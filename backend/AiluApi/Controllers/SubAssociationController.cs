using AiluApi.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace AiluApi.Controllers;

[ApiController]
[Route("api/associations")]
[Authorize]
public class SubAssociationController : ControllerBase
{
    private readonly SubAssociationService _service;

    public SubAssociationController(SubAssociationService service)
    {
        _service = service;
    }

    private int GetUserId() =>
        int.Parse(User.FindFirstValue("uid")!);

    [HttpGet]
    [AllowAnonymous]
    public async Task<IActionResult> GetAssociations()
    {
        var associations = await _service.GetAssociationsAsync();
        return Ok(associations);
    }

    [HttpGet("{id}")]
    public async Task<IActionResult> GetAssociation(int id)
    {
        var association = await _service.GetAssociationAsync(id);
        if (association == null)
            return NotFound();
        return Ok(association);
    }

    [HttpPost]
    public async Task<IActionResult> CreateAssociation([FromBody] CreateAssociationRequest request)
    {
        try
        {
            var association = await _service.CreateAssociationAsync(GetUserId(), request.Name, request.Description);
            return CreatedAtAction(nameof(GetAssociation), new { id = association.Id }, association);
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(ex.Message);
        }
    }

    [HttpPost("{id}/join")]
    public async Task<IActionResult> RequestJoin(int id)
    {
        try
        {
            var membership = await _service.RequestMembershipAsync(id, GetUserId());
            return Ok(membership);
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(ex.Message);
        }
    }

    [HttpPut("{id}/members/{userId}/approve")]
    public async Task<IActionResult> ApproveMember(int id, int userId)
    {
        try
        {
            var membership = await _service.ApproveMembershipAsync(id, userId, GetUserId());
            return Ok(membership);
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(ex.Message);
        }
    }

    [HttpDelete("{id}/members/{userId}")]
    public async Task<IActionResult> RemoveMember(int id, int userId)
    {
        try
        {
            await _service.RemoveMemberAsync(id, userId, GetUserId());
            return Ok();
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(ex.Message);
        }
    }

    [HttpPut("{id}/members/{userId}/delegate")]
    public async Task<IActionResult> DelegateSubAdmin(int id, int userId)
    {
        try
        {
            await _service.DelegateSubAdminAsync(id, userId, GetUserId());
            return Ok();
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(ex.Message);
        }
    }
}

public class CreateAssociationRequest
{
    public required string Name { get; set; }
    public string? Description { get; set; }
}
