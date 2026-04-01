using AiluApi.Data;
using AiluApi.Models;
using AiluApi.Queries;
using Microsoft.EntityFrameworkCore;

namespace AiluApi.Handlers;

public class GetCasesQueryHandler
{
    private readonly AppDbContext _context;

    public GetCasesQueryHandler(AppDbContext context)
    {
        _context = context;
    }

    public async Task<List<Case>> Handle(GetCasesQuery query)
    {
        var queryable = _context.Cases.AsQueryable();

        if (query.AssignedUserId.HasValue)
        {
            queryable = queryable.Where(c => c.ClientId == query.AssignedUserId.Value);
        }

        return await queryable.ToListAsync();
    }
}