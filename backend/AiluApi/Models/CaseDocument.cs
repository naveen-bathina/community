namespace AiluApi.Models;

public class CaseDocument
{
    public int Id { get; set; }
    public int CaseId { get; set; }
    public required string FileName { get; set; }
    public string? Description { get; set; }
    public required string FilePath { get; set; }
    public int? UploadedByUserId { get; set; }
    public DateTime UploadedAt { get; set; } = DateTime.UtcNow;
    public bool SignedOff { get; set; }

    public Case? Case { get; set; }
}
