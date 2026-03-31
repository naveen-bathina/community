using AiluApi.Commands;
using AiluApi.Data;
using AiluApi.Events;
using AiluApi.Models;

namespace AiluApi.Handlers;

public class UpdateCaseStatusCommandHandler
{
    private readonly AppDbContext _context;
    private readonly EventStore _eventStore;

    public UpdateCaseStatusCommandHandler(AppDbContext context, EventStore eventStore)
    {
        _context = context;
        _eventStore = eventStore;
    }

    public async Task<Case> Handle(UpdateCaseStatusCommand command)
    {
        var caseEntity = await _context.Cases.FindAsync(command.CaseId);
        if (caseEntity == null)
        {
            throw new ArgumentException("Case not found");
        }

        if (!Enum.TryParse<CaseStatus>(command.NewStatus, out var newStatus))
        {
            throw new ArgumentException("Invalid status");
        }

        // Validate transitions
        if (!IsValidTransition(caseEntity.Status, newStatus))
        {
            throw new InvalidOperationException($"Invalid status transition from {caseEntity.Status} to {newStatus}");
        }

        var oldStatus = caseEntity.Status;
        caseEntity.Status = newStatus;
        caseEntity.UpdatedAt = DateTime.UtcNow;

        await _context.SaveChangesAsync();

        // Publish event
        var @event = new CaseStatusUpdatedEvent
        {
            CaseId = caseEntity.Id,
            OldStatus = oldStatus.ToString(),
            NewStatus = newStatus.ToString()
        };
        _eventStore.Append(@event);

        return caseEntity;
    }

    private bool IsValidTransition(CaseStatus current, CaseStatus next)
    {
        return (current, next) switch
        {
            (CaseStatus.Open, CaseStatus.InProgress) => true,
            (CaseStatus.InProgress, CaseStatus.Resolved) => true,
            (CaseStatus.InProgress, CaseStatus.Closed) => true,
            (CaseStatus.Resolved, CaseStatus.Closed) => true,
            _ => false
        };
    }
}