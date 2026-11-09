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

        var newStatus = command.NewStatus?.ToLower();
        if (!IsValidStatus(newStatus))
        {
            throw new ArgumentException("Invalid status");
        }

        if (!IsValidTransition(caseEntity.Status, newStatus!))
        {
            throw new InvalidOperationException($"Invalid status transition from {caseEntity.Status} to {newStatus}");
        }

        var oldStatus = caseEntity.Status;
        caseEntity.Status = newStatus!;

        await _context.SaveChangesAsync();

        var @event = new CaseStatusUpdatedEvent
        {
            CaseId = caseEntity.Id,
            OldStatus = oldStatus,
            NewStatus = newStatus!
        };
        _eventStore.Append(@event);

        return caseEntity;
    }

    private static bool IsValidStatus(string? status) =>
        status is "intake" or "active" or "review" or "closed";

    private static bool IsValidTransition(string current, string next)
    {
        return (current, next) switch
        {
            ("intake", "active") => true,
            ("active", "review") => true,
            ("active", "closed") => true,
            ("review", "closed") => true,
            _ => false
        };
    }
}