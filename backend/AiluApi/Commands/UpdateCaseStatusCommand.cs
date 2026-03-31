namespace AiluApi.Commands;

public class UpdateCaseStatusCommand
{
    public int CaseId { get; set; }
    public required string NewStatus { get; set; }
}