namespace AiluApi.Models;

public class CaseHistory
{
    public int Id { get; set; }
    public int CaseId { get; set; }
    public required string Action { get; set; }
    public string? Description { get; set; }
    public int? ActorId { get; set; }
    public DateTime Timestamp { get; set; } = DateTime.UtcNow;

    public Case? Case { get; set; }
}
