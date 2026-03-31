using AiluApi.Data;
using AiluApi.Models;
using BCrypt.Net;
using Microsoft.EntityFrameworkCore;

namespace AiluApi.Services;

public class AuthService
{
    private readonly AppDbContext _context;

    public AuthService(AppDbContext context)
    {
        _context = context;
    }

    public async Task RegisterAsync(string email, string password)
    {
        var existingUser = await _context.Users.FirstOrDefaultAsync(u => u.Email == email);
        if (existingUser != null)
        {
            throw new InvalidOperationException("User already exists");
        }

        var passwordHash = BCrypt.Net.BCrypt.HashPassword(password);
        var user = new User { Email = email, PasswordHash = passwordHash };
        _context.Users.Add(user);
        await _context.SaveChangesAsync();
    }

    public async Task<bool> LoginAsync(string email, string password)
    {
        var user = await _context.Users.FirstOrDefaultAsync(u => u.Email == email);
        if (user == null)
        {
            return false;
        }
        return BCrypt.Net.BCrypt.Verify(password, user.PasswordHash);
    }
}