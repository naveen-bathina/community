namespace AiluApi.Models;

public class EventBooking
{
    public int Id { get; set; }
    public int EventId { get; set; }
    public int UserId { get; set; }
    public DateTime BookedAt { get; set; } = DateTime.UtcNow;
    public string Status { get; set; } = "confirmed"; // confirmed, canceled

    public Event? Event { get; set; }
    public User? User { get; set; }
}
