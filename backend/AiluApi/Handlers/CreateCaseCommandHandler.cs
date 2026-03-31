using AiluApi.Commands;
using AiluApi.Data;
using AiluApi.Events;
using AiluApi.Models;

namespace AiluApi.Handlers;

public class CreateCaseCommandHandler
{
    private readonly AppDbContext _context;
    private readonly EventStore _eventStore;

    public CreateCaseCommandHandler(AppDbContext context, EventStore eventStore)
    {
        _context = context;
        _eventStore = eventStore;
    }

    public async Task<Case> Handle(CreateCaseCommand command)
    {
        var caseEntity = new Case
        {
            Title = command.Title,
            Description = command.Description,
            AssignedUserId = command.AssignedUserId,
            Status = CaseStatus.Open,
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        };

        _context.Cases.Add(caseEntity);
        await _context.SaveChangesAsync();

        // Publish event
        var @event = new CaseCreatedEvent
        {
            CaseId = caseEntity.Id,
            Title = caseEntity.Title,
            Description = caseEntity.Description,
            AssignedUserId = caseEntity.AssignedUserId
        };
        _eventStore.Append(@event);

        return caseEntity;
    }
}