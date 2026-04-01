namespace AiluApi.Events;

public class CaseCreatedEvent
{
    public int CaseId { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public int AssignedUserId { get; set; }
    public DateTime Timestamp { get; set; } = DateTime.UtcNow;
}