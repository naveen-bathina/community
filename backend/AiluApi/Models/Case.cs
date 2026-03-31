namespace AiluApi.Models;

public enum CaseStatus
{
    Open,
    InProgress,
    Resolved,
    Closed
}

public class Case
{
    public int Id { get; set; }
    public required string Title { get; set; }
    public required string Description { get; set; }
    public CaseStatus Status { get; set; } = CaseStatus.Open;
    public int AssignedUserId { get; set; }
    public User? AssignedUser { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
}