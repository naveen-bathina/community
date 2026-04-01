namespace AiluApi.Models;

public class Invoice
{
    public int Id { get; set; }
    public int ClientId { get; set; }
    public int? CaseId { get; set; }
    public required string InvoiceNumber { get; set; }
    public decimal Amount { get; set; }
    public decimal? GstAmount { get; set; }
    public string Status { get; set; } = "draft"; // draft, sent, paid, overdue
    public DateTime IssuedAt { get; set; } = DateTime.UtcNow;
    public DateTime? DueDate { get; set; }
    public DateTime? PaidAt { get; set; }

    public Client? Client { get; set; }
    public Case? Case { get; set; }
}
