using AiluApi.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace AiluApi.Controllers;

[ApiController]
[Route("api/forum")]
public class ForumController : ControllerBase
{
    private readonly ForumService _forumService;

    public ForumController(ForumService forumService)
    {
        _forumService = forumService;
    }

    private int GetUserId() =>
        int.Parse(User.FindFirstValue("uid")!);

    private string GetUserRole() =>
        User.FindFirstValue(ClaimTypes.Role) ?? "member";

    [HttpGet]
    public async Task<IActionResult> GetPosts([FromQuery] string? category)
    {
        var posts = await _forumService.GetPostsAsync(category);
        return Ok(posts);
    }

    [HttpGet("{id}")]
    public async Task<IActionResult> GetPost(int id)
    {
        var post = await _forumService.GetPostAsync(id);
        if (post == null)
            return NotFound();
        return Ok(post);
    }

    [HttpPost]
    [Authorize]
    public async Task<IActionResult> CreatePost([FromBody] CreatePostRequest request)
    {
        var post = await _forumService.CreatePostAsync(GetUserId(), request.Title, request.Content, request.Category);
        return CreatedAtAction(nameof(GetPost), new { id = post.Id }, post);
    }

    [HttpDelete("{id}")]
    [Authorize]
    public async Task<IActionResult> DeletePost(int id)
    {
        try
        {
            await _forumService.DeletePostAsync(id, GetUserId(), GetUserRole());
            return Ok();
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(ex.Message);
        }
    }

    [HttpGet("categories")]
    public async Task<IActionResult> GetCategories()
    {
        var categories = await _forumService.GetCategoriesAsync();
        return Ok(categories);
    }
}

public class CreatePostRequest
{
    public required string Title { get; set; }
    public required string Content { get; set; }
    public string? Category { get; set; }
}
