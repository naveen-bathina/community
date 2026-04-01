using AiluApi.Commands;
using AiluApi.Handlers;
using AiluApi.Models;
using AiluApi.Queries;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace AiluApi.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class CasesController : ControllerBase
{
    private readonly CreateCaseCommandHandler _createHandler;
    private readonly GetCasesQueryHandler _getHandler;
    private readonly UpdateCaseStatusCommandHandler _updateStatusHandler;

    public CasesController(CreateCaseCommandHandler createHandler, GetCasesQueryHandler getHandler, UpdateCaseStatusCommandHandler updateStatusHandler)
    {
        _createHandler = createHandler;
        _getHandler = getHandler;
        _updateStatusHandler = updateStatusHandler;
    }

    [HttpPost]
    public async Task<IActionResult> CreateCase([FromBody] CreateCaseCommand command)
    {
        var userId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? "0");
        command.AssignedUserId = userId;
        var caseEntity = await _createHandler.Handle(command);
        return CreatedAtAction(nameof(GetCase), new { id = caseEntity.Id }, caseEntity);
    }

    [HttpGet]
    public async Task<IActionResult> GetCases()
    {
        var userId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? "0");
        var query = new GetCasesQuery { AssignedUserId = userId };
        var cases = await _getHandler.Handle(query);
        return Ok(cases);
    }

    [HttpGet("{id}")]
    public async Task<IActionResult> GetCase(int id)
    {
        var userId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? "0");
        var query = new GetCasesQuery { AssignedUserId = userId };
        var cases = await _getHandler.Handle(query);
        var caseEntity = cases.FirstOrDefault(c => c.Id == id);
        if (caseEntity == null)
        {
            return NotFound();
        }
        return Ok(caseEntity);
    }

    [HttpPut("{id}/status")]
    public async Task<IActionResult> UpdateCaseStatus(int id, [FromBody] UpdateCaseStatusRequest request)
    {
        var userId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? "0");
        var command = new UpdateCaseStatusCommand { CaseId = id, NewStatus = request.NewStatus };

        try
        {
            var updatedCase = await _updateStatusHandler.Handle(command);
            // Check if user owns the case
            if (updatedCase.AssignedUserId != userId)
            {
                return Forbid();
            }
            return Ok(updatedCase);
        }
        catch (ArgumentException ex)
        {
            return NotFound(ex.Message);
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(ex.Message);
        }
    }
}

public class UpdateCaseStatusRequest
{
    public required string NewStatus { get; set; }
}