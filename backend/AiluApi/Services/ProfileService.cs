using AiluApi.Data;
using AiluApi.Models;
using Microsoft.EntityFrameworkCore;

namespace AiluApi.Services;

public class ProfileService
{
    private readonly AppDbContext _context;

    public ProfileService(AppDbContext context)
    {
        _context = context;
    }

    public async Task<Profile?> GetProfileAsync(int userId)
    {
        return await _context.Profiles.FirstOrDefaultAsync(p => p.UserId == userId);
    }

    public async Task<ProfileView?> GetProfileViewAsync(int userId)
    {
        var user = await _context.Users
            .Include(u => u.Profile)
            .FirstOrDefaultAsync(u => u.Id == userId);

        if (user == null)
            return null;

        return new ProfileView
        {
            UserId = user.Id,
            Name = user.Name,
            Email = user.Email,
            Phone = user.Phone,
            District = user.District,
            State = user.State,
            Bio = user.Profile?.Bio,
            Specialization = user.Profile?.Specialization,
            BarNumber = user.Profile?.BarNumber,
            HighCourt = user.Profile?.HighCourt,
            KycVerified = user.Profile?.KycVerified ?? false,
            Rating = user.Profile?.Rating ?? 0,
            IsAvailable = user.Profile?.IsAvailable ?? true,
            UpdatedAt = user.Profile?.UpdatedAt ?? user.CreatedAt
        };
    }

    public async Task<ProfileView> UpsertProfileAsync(int userId, string? name, string? phone,
        string? district, string? state, string? bio, string? specialization,
        string? barNumber, string? highCourt)
    {
        var user = await _context.Users
            .Include(u => u.Profile)
            .FirstOrDefaultAsync(u => u.Id == userId);

        if (user == null)
            throw new InvalidOperationException("User not found.");

        if (name != null) user.Name = name;
        if (phone != null) user.Phone = phone;
        if (district != null) user.District = district;
        if (state != null) user.State = state;

        var profile = user.Profile;
        if (profile == null)
        {
            profile = new Profile { UserId = userId };
            _context.Profiles.Add(profile);
        }

        if (bio != null) profile.Bio = bio;
        if (specialization != null) profile.Specialization = specialization;
        if (barNumber != null) profile.BarNumber = barNumber;
        if (highCourt != null) profile.HighCourt = highCourt;
        profile.UpdatedAt = DateTime.UtcNow;

        await _context.SaveChangesAsync();

        return new ProfileView
        {
            UserId = user.Id,
            Name = user.Name,
            Email = user.Email,
            Phone = user.Phone,
            District = user.District,
            State = user.State,
            Bio = profile.Bio,
            Specialization = profile.Specialization,
            BarNumber = profile.BarNumber,
            HighCourt = profile.HighCourt,
            KycVerified = profile.KycVerified,
            Rating = profile.Rating,
            IsAvailable = profile.IsAvailable,
            UpdatedAt = profile.UpdatedAt
        };
    }

    public async Task UploadKycDocumentAsync(int userId, string documentPath)
    {
        var profile = await _context.Profiles.FirstOrDefaultAsync(p => p.UserId == userId);
        if (profile == null)
        {
            profile = new Profile { UserId = userId };
            _context.Profiles.Add(profile);
        }

        profile.KycDocumentPath = documentPath;
        profile.UpdatedAt = DateTime.UtcNow;
        await _context.SaveChangesAsync();
    }

    public async Task<IEnumerable<object>> SearchAdvocatesAsync(string? specialization, string? district, string? state)
    {
        var query = _context.Users
            .Include(u => u.Profile)
            .Where(u => u.Role == "advocate");

        if (!string.IsNullOrEmpty(district))
            query = query.Where(u => u.District == district);

        if (!string.IsNullOrEmpty(state))
            query = query.Where(u => u.State == state);

        if (!string.IsNullOrEmpty(specialization))
            query = query.Where(u => u.Profile != null && u.Profile.Specialization == specialization);

        var advocates = await query.ToListAsync();

        return advocates.Select(u => new
        {
            u.Id,
            u.Name,
            u.Email,
            u.District,
            u.State,
            Profile = u.Profile == null ? null : new
            {
                u.Profile.Specialization,
                u.Profile.BarNumber,
                u.Profile.HighCourt,
                u.Profile.Rating,
                u.Profile.IsAvailable,
                u.Profile.KycVerified
            }
        });
    }
}

public class ProfileView
{
    public int UserId { get; set; }
    public string? Name { get; set; }
    public string? Email { get; set; }
    public string? Phone { get; set; }
    public string? District { get; set; }
    public string? State { get; set; }
    public string? Bio { get; set; }
    public string? Specialization { get; set; }
    public string? BarNumber { get; set; }
    public string? HighCourt { get; set; }
    public bool KycVerified { get; set; }
    public double Rating { get; set; }
    public bool IsAvailable { get; set; }
    public DateTime UpdatedAt { get; set; }
}
