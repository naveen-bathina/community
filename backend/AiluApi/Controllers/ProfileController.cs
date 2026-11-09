using AiluApi.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.ComponentModel.DataAnnotations;
using System.Security.Claims;

namespace AiluApi.Controllers;

[ApiController]
[Route("api/profile")]
[Authorize]
public class ProfileController : ControllerBase
{
    private readonly ProfileService _profileService;

    public ProfileController(ProfileService profileService)
    {
        _profileService = profileService;
    }

    private int GetUserId() =>
        int.Parse(User.FindFirstValue("uid")!);

    [HttpGet]
    public async Task<IActionResult> GetMyProfile()
    {
        var profile = await _profileService.GetProfileViewAsync(GetUserId());
        if (profile == null)
            return NotFound();
        return Ok(profile);
    }

    [HttpPut]
    public async Task<IActionResult> UpdateProfile([FromBody] UpdateProfileRequest request)
    {
        if (!ModelState.IsValid)
            return BadRequest(ModelState);

        try
        {
            var profile = await _profileService.UpsertProfileAsync(
                GetUserId(),
                request.Name, request.Phone, request.District, request.State,
                request.Bio, request.Specialization, request.BarNumber, request.HighCourt);
            return Ok(profile);
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(ex.Message);
        }
    }

    [HttpPost("kyc")]
    public async Task<IActionResult> UploadKyc([FromBody] KycUploadRequest request)
    {
        await _profileService.UploadKycDocumentAsync(GetUserId(), request.DocumentPath);
        return Ok();
    }

    [HttpGet("advocates")]
    [AllowAnonymous]
    public async Task<IActionResult> SearchAdvocates(
        [FromQuery] string? specialization,
        [FromQuery] string? district,
        [FromQuery] string? state)
    {
        var advocates = await _profileService.SearchAdvocatesAsync(specialization, district, state);
        return Ok(advocates);
    }
}

public class UpdateProfileRequest
{
    [MaxLength(100, ErrorMessage = "Name cannot exceed 100 characters.")]
    public string? Name { get; set; }

    [Phone(ErrorMessage = "Invalid phone number format.")]
    [MaxLength(20, ErrorMessage = "Phone number cannot exceed 20 characters.")]
    public string? Phone { get; set; }

    [MaxLength(100, ErrorMessage = "District cannot exceed 100 characters.")]
    public string? District { get; set; }

    [MaxLength(100, ErrorMessage = "State cannot exceed 100 characters.")]
    public string? State { get; set; }

    [MaxLength(1000, ErrorMessage = "Bio cannot exceed 1000 characters.")]
    public string? Bio { get; set; }

    [MaxLength(100, ErrorMessage = "Specialization cannot exceed 100 characters.")]
    public string? Specialization { get; set; }

    [MaxLength(50, ErrorMessage = "Bar number cannot exceed 50 characters.")]
    public string? BarNumber { get; set; }

    [MaxLength(100, ErrorMessage = "High court cannot exceed 100 characters.")]
    public string? HighCourt { get; set; }
}

public class KycUploadRequest
{
    public required string DocumentPath { get; set; }
}
