using AiluApi.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace AiluApi.Controllers;

[ApiController]
[Route("api/events")]
public class EventController : ControllerBase
{
    private readonly EventService _eventService;

    public EventController(EventService eventService)
    {
        _eventService = eventService;
    }

    private int GetUserId() =>
        int.Parse(User.FindFirstValue("uid")!);

    [HttpGet]
    public async Task<IActionResult> GetEvents()
    {
        var events = await _eventService.GetEventsAsync();
        return Ok(events);
    }

    [HttpGet("{id}")]
    public async Task<IActionResult> GetEvent(int id)
    {
        var ev = await _eventService.GetEventAsync(id);
        if (ev == null)
            return NotFound();
        return Ok(ev);
    }

    [HttpPost]
    [Authorize]
    public async Task<IActionResult> CreateEvent([FromBody] CreateEventRequest request)
    {
        var ev = await _eventService.CreateEventAsync(
            GetUserId(), request.Title, request.Description,
            request.Location, request.StartDate, request.EndDate,
            request.Price, request.Capacity);
        return CreatedAtAction(nameof(GetEvent), new { id = ev.Id }, ev);
    }

    [HttpPost("{id}/book")]
    [Authorize]
    public async Task<IActionResult> BookEvent(int id)
    {
        try
        {
            var booking = await _eventService.BookEventAsync(id, GetUserId());
            return Ok(booking);
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(ex.Message);
        }
    }

    [HttpDelete("{id}/book")]
    [Authorize]
    public async Task<IActionResult> CancelBooking(int id)
    {
        try
        {
            await _eventService.CancelBookingAsync(id, GetUserId());
            return Ok();
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(ex.Message);
        }
    }
}

public class CreateEventRequest
{
    public required string Title { get; set; }
    public string? Description { get; set; }
    public string? Location { get; set; }
    public DateTime StartDate { get; set; }
    public DateTime EndDate { get; set; }
    public decimal? Price { get; set; }
    public int? Capacity { get; set; }
}
