using AiluApi.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace AiluApi.Controllers;

[ApiController]
[Route("api/cases")]
[Authorize]
public class CaseController : ControllerBase
{
    private readonly CaseService _caseService;

    public CaseController(CaseService caseService)
    {
        _caseService = caseService;
    }

    private int GetUserId() =>
        int.Parse(User.FindFirstValue("uid")!);

    [HttpGet]
    public async Task<IActionResult> GetCases([FromQuery] int? clientId)
    {
        var cases = await _caseService.GetCasesAsync(clientId);
        return Ok(cases);
    }

    [HttpGet("{id}")]
    public async Task<IActionResult> GetCase(int id)
    {
        var legalCase = await _caseService.GetCaseAsync(id);
        if (legalCase == null)
            return NotFound();
        return Ok(legalCase);
    }

    [HttpPost]
    public async Task<IActionResult> CreateCase([FromBody] CreateCaseRequest request)
    {
        try
        {
            var legalCase = await _caseService.CreateCaseAsync(
                request.ClientId, request.Title, request.Description,
                request.CaseNumber, request.Court, request.NextHearingDate);
            return CreatedAtAction(nameof(GetCase), new { id = legalCase.Id }, legalCase);
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(ex.Message);
        }
    }

    [HttpPut("{id}/status")]
    public async Task<IActionResult> UpdateStatus(int id, [FromBody] UpdateCaseStatusRequest request)
    {
        try
        {
            var legalCase = await _caseService.UpdateCaseStatusAsync(id, request.Status, GetUserId());
            return Ok(legalCase);
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(ex.Message);
        }
    }

    [HttpPost("{id}/documents")]
    public async Task<IActionResult> AddDocument(int id, [FromBody] AddDocumentRequest request)
    {
        try
        {
            var doc = await _caseService.AddDocumentAsync(
                id, request.FileName, request.FilePath, request.Description, GetUserId());
            return Ok(doc);
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(ex.Message);
        }
    }

    [HttpPost("{id}/advocates")]
    public async Task<IActionResult> AssignAdvocate(int id, [FromBody] AssignAdvocateRequest request)
    {
        try
        {
            var assignment = await _caseService.AssignAdvocateAsync(
                id, request.AdvocateUserId, request.Role ?? "primary", GetUserId());
            return Ok(assignment);
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(ex.Message);
        }
    }

    [HttpGet("{id}/history")]
    public async Task<IActionResult> GetHistory(int id)
    {
        var history = await _caseService.GetCaseHistoryAsync(id);
        return Ok(history);
    }
}

public class CreateCaseRequest
{
    public int ClientId { get; set; }
    public required string Title { get; set; }
    public string? Description { get; set; }
    public string? CaseNumber { get; set; }
    public string? Court { get; set; }
    public DateTime? NextHearingDate { get; set; }
}

public class UpdateCaseStatusRequest
{
    public required string Status { get; set; }
}

public class AddDocumentRequest
{
    public required string FileName { get; set; }
    public required string FilePath { get; set; }
    public string? Description { get; set; }
}

public class AssignAdvocateRequest
{
    public int AdvocateUserId { get; set; }
    public string? Role { get; set; }
}
