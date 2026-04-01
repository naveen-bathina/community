using AiluApi.Data;
using AiluApi.Models;
using Microsoft.EntityFrameworkCore;

namespace AiluApi.Services;

public class EventService
{
    private readonly AppDbContext _context;

    public EventService(AppDbContext context)
    {
        _context = context;
    }

    public async Task<IEnumerable<Event>> GetEventsAsync()
    {
        return await _context.Events
            .Include(e => e.Organizer)
            .OrderBy(e => e.StartDate)
            .ToListAsync();
    }

    public async Task<Event?> GetEventAsync(int id)
    {
        return await _context.Events
            .Include(e => e.Organizer)
            .Include(e => e.Bookings).ThenInclude(b => b.User)
            .FirstOrDefaultAsync(e => e.Id == id);
    }

    public async Task<Event> CreateEventAsync(int organizerUserId, string title, string? description,
        string? location, DateTime startDate, DateTime endDate, decimal? price, int? capacity)
    {
        var ev = new Event
        {
            OrganizerUserId = organizerUserId,
            Title = title,
            Description = description,
            Location = location,
            StartDate = startDate,
            EndDate = endDate,
            Price = price,
            Capacity = capacity
        };
        _context.Events.Add(ev);
        await _context.SaveChangesAsync();
        return ev;
    }

    public async Task<EventBooking> BookEventAsync(int eventId, int userId)
    {
        var ev = await _context.Events
            .Include(e => e.Bookings)
            .FirstOrDefaultAsync(e => e.Id == eventId);
        if (ev == null)
            throw new InvalidOperationException("Event not found");

        var activeBookings = ev.Bookings.Count(b => b.Status == "confirmed");
        if (ev.Capacity.HasValue && activeBookings >= ev.Capacity.Value)
            throw new InvalidOperationException("Event is at full capacity");

        var existing = ev.Bookings.FirstOrDefault(b => b.UserId == userId && b.Status == "confirmed");
        if (existing != null)
            throw new InvalidOperationException("Already booked");

        var booking = new EventBooking { EventId = eventId, UserId = userId };
        _context.EventBookings.Add(booking);
        await _context.SaveChangesAsync();
        return booking;
    }

    public async Task CancelBookingAsync(int eventId, int userId)
    {
        var booking = await _context.EventBookings
            .FirstOrDefaultAsync(b => b.EventId == eventId && b.UserId == userId && b.Status == "confirmed");
        if (booking == null)
            throw new InvalidOperationException("Booking not found");

        booking.Status = "canceled";
        await _context.SaveChangesAsync();
    }
}
