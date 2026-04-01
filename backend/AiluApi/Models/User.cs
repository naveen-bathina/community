namespace AiluApi.Models;

public class User
{
    public int Id { get; set; }
    public required string Email { get; set; }
    public required string PasswordHash { get; set; }
    public string Role { get; set; } = "member"; // member, advocate, student, admin, client_user
    public string? Name { get; set; }
    public string? Phone { get; set; }
    public string? District { get; set; }
    public string? State { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public Profile? Profile { get; set; }
    public Subscription? Subscription { get; set; }
    public ICollection<AssociationMembership> AssociationMemberships { get; set; } = new List<AssociationMembership>();
    public ICollection<VakalatAssignment> CaseAssignments { get; set; } = new List<VakalatAssignment>();
}