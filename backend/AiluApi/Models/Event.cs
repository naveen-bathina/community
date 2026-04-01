namespace AiluApi.Models;

public class Event
{
    public int Id { get; set; }
    public required string Title { get; set; }
    public string? Description { get; set; }
    public string? Location { get; set; }
    public DateTime StartDate { get; set; }
    public DateTime EndDate { get; set; }
    public decimal? Price { get; set; }
    public int? Capacity { get; set; }
    public int OrganizerUserId { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public User? Organizer { get; set; }
    public ICollection<EventBooking> Bookings { get; set; } = new List<EventBooking>();
}
