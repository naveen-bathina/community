namespace AiluApi.Models;

public class SubAssociation
{
    public int Id { get; set; }
    public required string Name { get; set; }
    public string? Description { get; set; }
    public int LeaderUserId { get; set; }
    public string Status { get; set; } = "active"; // pending, active, inactive
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public User? Leader { get; set; }
    public ICollection<AssociationMembership> Memberships { get; set; } = new List<AssociationMembership>();
}
