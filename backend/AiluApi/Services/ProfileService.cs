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

    public async Task<Profile> UpsertProfileAsync(int userId, string? bio, string? specialization,
        string? barNumber, string? highCourt)
    {
        var profile = await _context.Profiles.FirstOrDefaultAsync(p => p.UserId == userId);
        if (profile == null)
        {
            profile = new Profile { UserId = userId };
            _context.Profiles.Add(profile);
        }

        profile.Bio = bio ?? profile.Bio;
        profile.Specialization = specialization ?? profile.Specialization;
        profile.BarNumber = barNumber ?? profile.BarNumber;
        profile.HighCourt = highCourt ?? profile.HighCourt;
        profile.UpdatedAt = DateTime.UtcNow;

        await _context.SaveChangesAsync();
        return profile;
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
