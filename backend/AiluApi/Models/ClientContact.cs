namespace AiluApi.Models;

public class ClientContact
{
    public int Id { get; set; }
    public int ClientId { get; set; }
    public required string Name { get; set; }
    public string? Email { get; set; }
    public string? Phone { get; set; }
    public string? Role { get; set; } // primary, billing, legal

    public Client? Client { get; set; }
}
