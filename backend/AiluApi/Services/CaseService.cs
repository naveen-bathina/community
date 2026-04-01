using AiluApi.Data;
using AiluApi.Models;
using Microsoft.EntityFrameworkCore;

namespace AiluApi.Services;

public class CaseService
{
    private readonly AppDbContext _context;

    public CaseService(AppDbContext context)
    {
        _context = context;
    }

    public async Task<IEnumerable<Case>> GetCasesAsync(int? clientId = null)
    {
        var query = _context.Cases
            .Include(c => c.Client)
            .Include(c => c.Assignments)
            .ThenInclude(a => a.Advocate)
            .AsQueryable();

        if (clientId.HasValue)
            query = query.Where(c => c.ClientId == clientId.Value);

        return await query.OrderByDescending(c => c.CreatedAt).ToListAsync();
    }

    public async Task<Case?> GetCaseAsync(int id)
    {
        return await _context.Cases
            .Include(c => c.Client)
            .Include(c => c.Documents)
            .Include(c => c.History)
            .Include(c => c.Assignments).ThenInclude(a => a.Advocate)
            .Include(c => c.Invoices)
            .FirstOrDefaultAsync(c => c.Id == id);
    }

    public async Task<Case> CreateCaseAsync(int clientId, string title, string? description,
        string? caseNumber, string? court, DateTime? nextHearingDate)
    {
        var client = await _context.Clients.FindAsync(clientId);
        if (client == null)
            throw new InvalidOperationException("Client not found");

        var legalCase = new Case
        {
            ClientId = clientId,
            Title = title,
            Description = description,
            CaseNumber = caseNumber,
            Court = court,
            NextHearingDate = nextHearingDate
        };
        _context.Cases.Add(legalCase);
        await _context.SaveChangesAsync();

        await AddHistoryAsync(legalCase.Id, "created", $"Case '{title}' created", null);
        return legalCase;
    }

    public async Task<Case> UpdateCaseStatusAsync(int caseId, string status, int? actorId)
    {
        var validStatuses = new[] { "intake", "active", "review", "closed" };
        if (!validStatuses.Contains(status))
            throw new InvalidOperationException("Invalid status");

        var legalCase = await _context.Cases.FindAsync(caseId);
        if (legalCase == null)
            throw new InvalidOperationException("Case not found");

        var oldStatus = legalCase.Status;
        legalCase.Status = status;
        await _context.SaveChangesAsync();

        await AddHistoryAsync(caseId, "status_changed", $"Status changed from {oldStatus} to {status}", actorId);
        return legalCase;
    }

    public async Task<CaseDocument> AddDocumentAsync(int caseId, string fileName, string filePath,
        string? description, int? uploadedByUserId)
    {
        var legalCase = await _context.Cases.FindAsync(caseId);
        if (legalCase == null)
            throw new InvalidOperationException("Case not found");

        var doc = new CaseDocument
        {
            CaseId = caseId,
            FileName = fileName,
            FilePath = filePath,
            Description = description,
            UploadedByUserId = uploadedByUserId
        };
        _context.CaseDocuments.Add(doc);
        await _context.SaveChangesAsync();

        await AddHistoryAsync(caseId, "document_added", $"Document '{fileName}' uploaded", uploadedByUserId);
        return doc;
    }

    public async Task<VakalatAssignment> AssignAdvocateAsync(int caseId, int advocateUserId, string role, int? actorId)
    {
        var advocate = await _context.Users.FindAsync(advocateUserId);
        if (advocate == null || advocate.Role != "advocate")
            throw new InvalidOperationException("Advocate not found");

        var legalCase = await _context.Cases.FindAsync(caseId);
        if (legalCase == null)
            throw new InvalidOperationException("Case not found");

        var existing = await _context.VakalatAssignments
            .FirstOrDefaultAsync(va => va.CaseId == caseId && va.AdvocateUserId == advocateUserId);
        if (existing != null)
            throw new InvalidOperationException("Advocate already assigned to this case");

        var assignment = new VakalatAssignment
        {
            CaseId = caseId,
            AdvocateUserId = advocateUserId,
            Role = role
        };
        _context.VakalatAssignments.Add(assignment);
        await _context.SaveChangesAsync();

        await AddHistoryAsync(caseId, "advocate_assigned",
            $"Advocate {advocate.Name ?? advocate.Email} assigned as {role}", actorId);
        return assignment;
    }

    public async Task<IEnumerable<CaseHistory>> GetCaseHistoryAsync(int caseId)
    {
        return await _context.CaseHistories
            .Where(h => h.CaseId == caseId)
            .OrderByDescending(h => h.Timestamp)
            .ToListAsync();
    }

    private async Task AddHistoryAsync(int caseId, string action, string description, int? actorId)
    {
        _context.CaseHistories.Add(new CaseHistory
        {
            CaseId = caseId,
            Action = action,
            Description = description,
            ActorId = actorId
        });
        await _context.SaveChangesAsync();
    }
}
