namespace AiluApi.Models;

public class Client
{
    public int Id { get; set; }
    public required string Name { get; set; }
    public string? Type { get; set; } // firm, corporate, individual
    public string? Email { get; set; }
    public string? Phone { get; set; }
    public string? Address { get; set; }
    public string? GstNumber { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public ICollection<ClientContact> Contacts { get; set; } = new List<ClientContact>();
    public ICollection<Invoice> Invoices { get; set; } = new List<Invoice>();
    public ICollection<Case> Cases { get; set; } = new List<Case>();
}
