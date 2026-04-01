namespace AiluApi.Models;

public class Profile
{
    public int Id { get; set; }
    public int UserId { get; set; }
    public string? Bio { get; set; }
    public string? Specialization { get; set; }
    public string? BarNumber { get; set; }
    public string? HighCourt { get; set; }
    public string? KycDocumentPath { get; set; }
    public bool KycVerified { get; set; }
    public double Rating { get; set; } = 0;
    public bool IsAvailable { get; set; } = true;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

    public User? User { get; set; }
}
