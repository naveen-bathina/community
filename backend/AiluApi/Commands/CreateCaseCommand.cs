namespace AiluApi.Commands;

public class CreateCaseCommand
{
    public required string Title { get; set; }
    public required string Description { get; set; }
    public int AssignedUserId { get; set; }
}