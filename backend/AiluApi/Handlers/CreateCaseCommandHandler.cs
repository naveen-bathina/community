using AiluApi.Commands;
using AiluApi.Data;
using AiluApi.Models;

namespace AiluApi.Handlers;

public class CreateCaseCommandHandler
{
    private readonly AppDbContext _context;

    public CreateCaseCommandHandler(AppDbContext context)
    {
        _context = context;
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

        return caseEntity;
    }
}