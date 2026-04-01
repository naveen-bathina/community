using AiluApi.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
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
        var profile = await _profileService.GetProfileAsync(GetUserId());
        if (profile == null)
            return NotFound();
        return Ok(profile);
    }

    [HttpPut]
    public async Task<IActionResult> UpdateProfile([FromBody] UpdateProfileRequest request)
    {
        var profile = await _profileService.UpsertProfileAsync(
            GetUserId(), request.Bio, request.Specialization, request.BarNumber, request.HighCourt);
        return Ok(profile);
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
    public string? Bio { get; set; }
    public string? Specialization { get; set; }
    public string? BarNumber { get; set; }
    public string? HighCourt { get; set; }
}

public class KycUploadRequest
{
    public required string DocumentPath { get; set; }
}
