namespace AiluApi.Models;

public class Case
{
    public int Id { get; set; }
    public int ClientId { get; set; }
    public required string Title { get; set; }
    public string? Description { get; set; }
    public string Status { get; set; } = "intake"; // intake, active, review, closed
    public string? CaseNumber { get; set; }
    public string? Court { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? NextHearingDate { get; set; }

    public Client? Client { get; set; }
    public ICollection<CaseDocument> Documents { get; set; } = new List<CaseDocument>();
    public ICollection<CaseHistory> History { get; set; } = new List<CaseHistory>();
    public ICollection<VakalatAssignment> Assignments { get; set; } = new List<VakalatAssignment>();
    public ICollection<Invoice> Invoices { get; set; } = new List<Invoice>();
}
