using AiluApi.Data;
using AiluApi.Models;
using Microsoft.EntityFrameworkCore;

namespace AiluApi.Services;

public class ClientService
{
    private readonly AppDbContext _context;

    public ClientService(AppDbContext context)
    {
        _context = context;
    }

    public async Task<IEnumerable<Client>> GetClientsAsync()
    {
        return await _context.Clients.Include(c => c.Contacts).ToListAsync();
    }

    public async Task<Client?> GetClientAsync(int id)
    {
        return await _context.Clients
            .Include(c => c.Contacts)
            .Include(c => c.Invoices)
            .FirstOrDefaultAsync(c => c.Id == id);
    }

    public async Task<Client> CreateClientAsync(string name, string? type, string? email,
        string? phone, string? address, string? gstNumber)
    {
        var client = new Client
        {
            Name = name,
            Type = type,
            Email = email,
            Phone = phone,
            Address = address,
            GstNumber = gstNumber
        };
        _context.Clients.Add(client);
        await _context.SaveChangesAsync();
        return client;
    }

    public async Task<ClientContact> AddContactAsync(int clientId, string name, string? email,
        string? phone, string? role)
    {
        var client = await _context.Clients.FindAsync(clientId);
        if (client == null)
            throw new InvalidOperationException("Client not found");

        var contact = new ClientContact
        {
            ClientId = clientId,
            Name = name,
            Email = email,
            Phone = phone,
            Role = role
        };
        _context.ClientContacts.Add(contact);
        await _context.SaveChangesAsync();
        return contact;
    }

    public async Task<Invoice> CreateInvoiceAsync(int clientId, int? caseId, decimal amount,
        decimal? gstAmount, DateTime? dueDate)
    {
        var client = await _context.Clients.FindAsync(clientId);
        if (client == null)
            throw new InvalidOperationException("Client not found");

        var invoiceNumber = $"INV-{DateTime.UtcNow:yyyyMMdd}-{Guid.NewGuid():N}";
        var invoice = new Invoice
        {
            ClientId = clientId,
            CaseId = caseId,
            InvoiceNumber = invoiceNumber,
            Amount = amount,
            GstAmount = gstAmount,
            DueDate = dueDate
        };
        _context.Invoices.Add(invoice);
        await _context.SaveChangesAsync();
        return invoice;
    }

    public async Task<Invoice> UpdateInvoiceStatusAsync(int invoiceId, string status)
    {
        var invoice = await _context.Invoices.FindAsync(invoiceId);
        if (invoice == null)
            throw new InvalidOperationException("Invoice not found");

        invoice.Status = status;
        if (status == "paid")
            invoice.PaidAt = DateTime.UtcNow;

        await _context.SaveChangesAsync();
        return invoice;
    }

    public async Task<IEnumerable<Invoice>> GetClientInvoicesAsync(int clientId)
    {
        return await _context.Invoices
            .Where(i => i.ClientId == clientId)
            .OrderByDescending(i => i.IssuedAt)
            .ToListAsync();
    }
}
