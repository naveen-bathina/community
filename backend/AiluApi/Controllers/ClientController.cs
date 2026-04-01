using AiluApi.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace AiluApi.Controllers;

[ApiController]
[Route("api/clients")]
[Authorize]
public class ClientController : ControllerBase
{
    private readonly ClientService _clientService;

    public ClientController(ClientService clientService)
    {
        _clientService = clientService;
    }

    [HttpGet]
    public async Task<IActionResult> GetClients()
    {
        var clients = await _clientService.GetClientsAsync();
        return Ok(clients);
    }

    [HttpGet("{id}")]
    public async Task<IActionResult> GetClient(int id)
    {
        var client = await _clientService.GetClientAsync(id);
        if (client == null)
            return NotFound();
        return Ok(client);
    }

    [HttpPost]
    public async Task<IActionResult> CreateClient([FromBody] CreateClientRequest request)
    {
        var client = await _clientService.CreateClientAsync(
            request.Name, request.Type, request.Email, request.Phone, request.Address, request.GstNumber);
        return CreatedAtAction(nameof(GetClient), new { id = client.Id }, client);
    }

    [HttpPost("{id}/contacts")]
    public async Task<IActionResult> AddContact(int id, [FromBody] AddContactRequest request)
    {
        try
        {
            var contact = await _clientService.AddContactAsync(id, request.Name, request.Email, request.Phone, request.Role);
            return Ok(contact);
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(ex.Message);
        }
    }

    [HttpGet("{id}/invoices")]
    public async Task<IActionResult> GetInvoices(int id)
    {
        var invoices = await _clientService.GetClientInvoicesAsync(id);
        return Ok(invoices);
    }

    [HttpPost("{id}/invoices")]
    public async Task<IActionResult> CreateInvoice(int id, [FromBody] CreateInvoiceRequest request)
    {
        try
        {
            var invoice = await _clientService.CreateInvoiceAsync(id, request.CaseId, request.Amount, request.GstAmount, request.DueDate);
            return Ok(invoice);
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(ex.Message);
        }
    }

    [HttpPut("invoices/{invoiceId}/status")]
    public async Task<IActionResult> UpdateInvoiceStatus(int invoiceId, [FromBody] UpdateInvoiceStatusRequest request)
    {
        try
        {
            var invoice = await _clientService.UpdateInvoiceStatusAsync(invoiceId, request.Status);
            return Ok(invoice);
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(ex.Message);
        }
    }
}

public class CreateClientRequest
{
    public required string Name { get; set; }
    public string? Type { get; set; }
    public string? Email { get; set; }
    public string? Phone { get; set; }
    public string? Address { get; set; }
    public string? GstNumber { get; set; }
}

public class AddContactRequest
{
    public required string Name { get; set; }
    public string? Email { get; set; }
    public string? Phone { get; set; }
    public string? Role { get; set; }
}

public class CreateInvoiceRequest
{
    public int? CaseId { get; set; }
    public decimal Amount { get; set; }
    public decimal? GstAmount { get; set; }
    public DateTime? DueDate { get; set; }
}

public class UpdateInvoiceStatusRequest
{
    public required string Status { get; set; }
}
