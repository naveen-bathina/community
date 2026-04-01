using System.ComponentModel.DataAnnotations;
using AiluApi.Services;
using AiluApi.Data;
using AiluApi.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace AiluApi.Controllers;

[ApiController]
[Route("api/auth")]
public class AuthController : ControllerBase
{
    private readonly AuthService _authService;
    private readonly AppDbContext _context;

    public AuthController(AuthService authService, AppDbContext context)
    {
        _authService = authService;
        _context = context;
    }

    [HttpPost("register")]
    public async Task<IActionResult> Register([FromBody] RegisterRequest request)
    {
        try
        {
            await _authService.RegisterAsync(request.Email, request.Password, request.Name, request.Role ?? "member");
            return Ok();
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(ex.Message);
        }
    }

    [HttpPost("login")]
    public async Task<IActionResult> Login([FromBody] LoginRequest request)
    {
        var token = await _authService.LoginAsync(request.Email, request.Password);
        if (token == null)
        {
            return Unauthorized();
        }
        return Ok(new { Token = token });
    }

    [HttpGet("me")]
    [Authorize]
    public async Task<IActionResult> GetMe()
    {
        var email = User.FindFirst(ClaimTypes.Name)?.Value;
        if (email == null)
        {
            return Unauthorized();
        }

        var user = await _context.Users.FindAsync(int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value));
        if (user == null)
        {
            return NotFound();
        }

        return Ok(new { Email = user.Email, Id = user.Id });
    }
}

public class RegisterRequest
{
    [Required]
    [EmailAddress]
    public required string Email { get; set; }

    [Required]
    [MinLength(8, ErrorMessage = "Password must be at least 8 characters.")]
    public required string Password { get; set; }

    public string? Name { get; set; }
    public string? Role { get; set; }
}

public class LoginRequest
{
    [Required]
    [EmailAddress]
    public required string Email { get; set; }

    [Required]
    public required string Password { get; set; }
}