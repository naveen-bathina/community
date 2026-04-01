namespace AiluApi.Models;

public class AssociationMembership
{
    public int Id { get; set; }
    public int SubAssociationId { get; set; }
    public int UserId { get; set; }
    public string Role { get; set; } = "member"; // member, sub_admin
    public string Status { get; set; } = "active"; // pending, active, removed
    public DateTime JoinedAt { get; set; } = DateTime.UtcNow;

    public SubAssociation? SubAssociation { get; set; }
    public User? User { get; set; }
}
