namespace AiluApi.Models;

public class VakalatAssignment
{
    public int Id { get; set; }
    public int CaseId { get; set; }
    public int AdvocateUserId { get; set; }
    public string Role { get; set; } = "primary"; // primary, backup, reviewer
    public DateTime AssignedAt { get; set; } = DateTime.UtcNow;

    public Case? Case { get; set; }
    public User? Advocate { get; set; }
}
