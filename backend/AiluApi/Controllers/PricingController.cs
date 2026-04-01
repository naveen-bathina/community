using AiluApi.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace AiluApi.Controllers;

[ApiController]
[Route("api/pricing")]
public class PricingController : ControllerBase
{
    private readonly PricingService _pricingService;

    public PricingController(PricingService pricingService)
    {
        _pricingService = pricingService;
    }

    private int GetUserId() =>
        int.Parse(User.FindFirstValue("uid")!);

    [HttpGet("plans/{id}")]
    public async Task<IActionResult> GetPlan(int id)
    {
        var plans = await _pricingService.GetActivePlansAsync();
        var plan = plans.FirstOrDefault(p => p.Id == id);
        if (plan == null)
            return NotFound();
        return Ok(plan);
    }

    [HttpGet("plans")]
    public async Task<IActionResult> GetPlans()
    {
        var plans = await _pricingService.GetActivePlansAsync();
        return Ok(plans);
    }

    [HttpPost("plans")]
    [Authorize(Roles = "admin")]
    public async Task<IActionResult> CreatePlan([FromBody] CreatePlanRequest request)
    {
        var plan = await _pricingService.CreatePlanAsync(
            request.Name, request.Price, request.Description, request.TrialDays, request.DiscountPercent, request.DurationMonths);
        return CreatedAtAction(nameof(GetPlan), new { id = plan.Id }, plan);
    }

    [HttpGet("subscription")]
    [Authorize]
    public async Task<IActionResult> GetMySubscription()
    {
        var subscription = await _pricingService.GetSubscriptionAsync(GetUserId());
        if (subscription == null)
            return NotFound();
        return Ok(subscription);
    }

    [HttpPost("subscribe")]
    [Authorize]
    public async Task<IActionResult> Subscribe([FromBody] SubscribeRequest request)
    {
        try
        {
            var subscription = await _pricingService.SubscribeAsync(GetUserId(), request.PlanId);
            return Ok(subscription);
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(ex.Message);
        }
    }

    [HttpDelete("subscription")]
    [Authorize]
    public async Task<IActionResult> CancelSubscription()
    {
        try
        {
            await _pricingService.CancelSubscriptionAsync(GetUserId());
            return Ok();
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(ex.Message);
        }
    }
}

public class CreatePlanRequest
{
    public required string Name { get; set; }
    public decimal Price { get; set; }
    public string? Description { get; set; }
    public int? TrialDays { get; set; }
    public decimal? DiscountPercent { get; set; }
    public int DurationMonths { get; set; } = 1;
}

public class SubscribeRequest
{
    public int PlanId { get; set; }
}
