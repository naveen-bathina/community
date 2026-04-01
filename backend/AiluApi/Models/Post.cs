namespace AiluApi.Models;

public class Post
{
    public int Id { get; set; }
    public required string Title { get; set; }
    public required string Content { get; set; }
    public string? Category { get; set; }
    public int AuthorUserId { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public bool IsPinned { get; set; }

    public User? Author { get; set; }
}
