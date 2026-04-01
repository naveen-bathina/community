using AiluApi.Data;
using AiluApi.Models;
using Microsoft.EntityFrameworkCore;

namespace AiluApi.Services;

public class SubAssociationService
{
    private readonly AppDbContext _context;

    public SubAssociationService(AppDbContext context)
    {
        _context = context;
    }

    public async Task<IEnumerable<SubAssociation>> GetAssociationsAsync()
    {
        return await _context.SubAssociations
            .Include(sa => sa.Leader)
            .Include(sa => sa.Memberships)
            .Where(sa => sa.Status == "active")
            .ToListAsync();
    }

    public async Task<SubAssociation?> GetAssociationAsync(int id)
    {
        return await _context.SubAssociations
            .Include(sa => sa.Leader)
            .Include(sa => sa.Memberships).ThenInclude(m => m.User)
            .FirstOrDefaultAsync(sa => sa.Id == id);
    }

    public async Task<SubAssociation> CreateAssociationAsync(int leaderUserId, string name, string? description)
    {
        var leader = await _context.Users.FindAsync(leaderUserId);
        if (leader == null || leader.Role != "advocate")
            throw new InvalidOperationException("Only advocates can create sub-associations");

        var association = new SubAssociation
        {
            Name = name,
            Description = description,
            LeaderUserId = leaderUserId
        };
        _context.SubAssociations.Add(association);
        await _context.SaveChangesAsync();

        // Leader automatically becomes a member with sub_admin role
        _context.AssociationMemberships.Add(new AssociationMembership
        {
            SubAssociationId = association.Id,
            UserId = leaderUserId,
            Role = "sub_admin",
            Status = "active"
        });
        await _context.SaveChangesAsync();

        return association;
    }

    public async Task<AssociationMembership> RequestMembershipAsync(int associationId, int userId)
    {
        var association = await _context.SubAssociations.FindAsync(associationId);
        if (association == null || association.Status != "active")
            throw new InvalidOperationException("Association not found or inactive");

        var existing = await _context.AssociationMemberships
            .FirstOrDefaultAsync(m => m.SubAssociationId == associationId && m.UserId == userId);
        if (existing != null)
            throw new InvalidOperationException("Already a member or request pending");

        var membership = new AssociationMembership
        {
            SubAssociationId = associationId,
            UserId = userId,
            Status = "pending"
        };
        _context.AssociationMemberships.Add(membership);
        await _context.SaveChangesAsync();
        return membership;
    }

    public async Task<AssociationMembership> ApproveMembershipAsync(int associationId, int userId, int leaderId)
    {
        var association = await _context.SubAssociations.FindAsync(associationId);
        if (association == null)
            throw new InvalidOperationException("Association not found");

        if (association.LeaderUserId != leaderId)
        {
            var leaderMembership = await _context.AssociationMemberships
                .FirstOrDefaultAsync(m => m.SubAssociationId == associationId && m.UserId == leaderId && m.Role == "sub_admin");
            if (leaderMembership == null)
                throw new InvalidOperationException("Unauthorized: not a leader or sub-admin");
        }

        var membership = await _context.AssociationMemberships
            .FirstOrDefaultAsync(m => m.SubAssociationId == associationId && m.UserId == userId);
        if (membership == null)
            throw new InvalidOperationException("Membership request not found");

        membership.Status = "active";
        await _context.SaveChangesAsync();
        return membership;
    }

    public async Task RemoveMemberAsync(int associationId, int userId, int leaderId)
    {
        var association = await _context.SubAssociations.FindAsync(associationId);
        if (association == null)
            throw new InvalidOperationException("Association not found");

        if (association.LeaderUserId != leaderId)
        {
            var leaderMembership = await _context.AssociationMemberships
                .FirstOrDefaultAsync(m => m.SubAssociationId == associationId && m.UserId == leaderId && m.Role == "sub_admin");
            if (leaderMembership == null)
                throw new InvalidOperationException("Unauthorized");
        }

        var membership = await _context.AssociationMemberships
            .FirstOrDefaultAsync(m => m.SubAssociationId == associationId && m.UserId == userId);
        if (membership == null)
            throw new InvalidOperationException("Member not found");

        membership.Status = "removed";
        await _context.SaveChangesAsync();
    }

    public async Task DelegateSubAdminAsync(int associationId, int userId, int leaderId)
    {
        var association = await _context.SubAssociations.FindAsync(associationId);
        if (association == null || association.LeaderUserId != leaderId)
            throw new InvalidOperationException("Unauthorized");

        var membership = await _context.AssociationMemberships
            .FirstOrDefaultAsync(m => m.SubAssociationId == associationId && m.UserId == userId && m.Status == "active");
        if (membership == null)
            throw new InvalidOperationException("Active member not found");

        membership.Role = "sub_admin";
        await _context.SaveChangesAsync();
    }
}
