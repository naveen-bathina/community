using AiluApi.Data;
using AiluApi.Models;
using Microsoft.EntityFrameworkCore;

namespace AiluApi.Services;

public class ForumService
{
    private readonly AppDbContext _context;

    public ForumService(AppDbContext context)
    {
        _context = context;
    }

    public async Task<IEnumerable<Post>> GetPostsAsync(string? category = null)
    {
        var query = _context.Posts.Include(p => p.Author).AsQueryable();
        if (!string.IsNullOrEmpty(category))
            query = query.Where(p => p.Category == category);

        return await query.OrderByDescending(p => p.IsPinned).ThenByDescending(p => p.CreatedAt).ToListAsync();
    }

    public async Task<Post?> GetPostAsync(int id)
    {
        return await _context.Posts.Include(p => p.Author).FirstOrDefaultAsync(p => p.Id == id);
    }

    public async Task<Post> CreatePostAsync(int authorUserId, string title, string content, string? category)
    {
        var post = new Post
        {
            AuthorUserId = authorUserId,
            Title = title,
            Content = content,
            Category = category
        };
        _context.Posts.Add(post);
        await _context.SaveChangesAsync();
        return post;
    }

    public async Task DeletePostAsync(int postId, int userId, string userRole)
    {
        var post = await _context.Posts.FindAsync(postId);
        if (post == null)
            throw new InvalidOperationException("Post not found");

        if (post.AuthorUserId != userId && userRole != "admin")
            throw new InvalidOperationException("Unauthorized");

        _context.Posts.Remove(post);
        await _context.SaveChangesAsync();
    }

    public async Task<IEnumerable<string>> GetCategoriesAsync()
    {
        return await _context.Posts
            .Where(p => p.Category != null)
            .Select(p => p.Category!)
            .Distinct()
            .ToListAsync();
    }
}
