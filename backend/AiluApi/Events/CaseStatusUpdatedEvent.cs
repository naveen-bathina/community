namespace AiluApi.Events;

public class CaseStatusUpdatedEvent
{
    public int CaseId { get; set; }
    public string OldStatus { get; set; } = string.Empty;
    public string NewStatus { get; set; } = string.Empty;
    public DateTime Timestamp { get; set; } = DateTime.UtcNow;
}