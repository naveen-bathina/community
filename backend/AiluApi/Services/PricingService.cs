using AiluApi.Data;
using AiluApi.Models;
using Microsoft.EntityFrameworkCore;

namespace AiluApi.Services;

public class PricingService
{
    private readonly AppDbContext _context;

    public PricingService(AppDbContext context)
    {
        _context = context;
    }

    public async Task<IEnumerable<PricingPlan>> GetActivePlansAsync()
    {
        return await _context.PricingPlans.Where(p => p.IsActive).ToListAsync();
    }

    public async Task<PricingPlan> CreatePlanAsync(string name, decimal price, string? description,
        int? trialDays, decimal? discountPercent)
    {
        var plan = new PricingPlan
        {
            Name = name,
            Price = price,
            Description = description,
            TrialDays = trialDays,
            DiscountPercent = discountPercent
        };
        _context.PricingPlans.Add(plan);
        await _context.SaveChangesAsync();
        return plan;
    }

    public async Task<Subscription> SubscribeAsync(int userId, int planId)
    {
        var plan = await _context.PricingPlans.FindAsync(planId);
        if (plan == null || !plan.IsActive)
            throw new InvalidOperationException("Plan not found or inactive");

        var existing = await _context.Subscriptions.FirstOrDefaultAsync(s => s.UserId == userId);
        if (existing != null)
        {
            existing.PricingPlanId = planId;
            existing.Status = plan.TrialDays.HasValue ? "trial" : "active";
            existing.StartDate = DateTime.UtcNow;
            existing.EndDate = plan.TrialDays.HasValue
                ? DateTime.UtcNow.AddDays(plan.TrialDays.Value)
                : DateTime.UtcNow.AddMonths(1);
            await _context.SaveChangesAsync();
            return existing;
        }

        var subscription = new Subscription
        {
            UserId = userId,
            PricingPlanId = planId,
            Status = plan.TrialDays.HasValue ? "trial" : "active",
            StartDate = DateTime.UtcNow,
            EndDate = plan.TrialDays.HasValue
                ? DateTime.UtcNow.AddDays(plan.TrialDays.Value)
                : DateTime.UtcNow.AddMonths(1)
        };
        _context.Subscriptions.Add(subscription);
        await _context.SaveChangesAsync();
        return subscription;
    }

    public async Task<Subscription?> GetSubscriptionAsync(int userId)
    {
        return await _context.Subscriptions
            .Include(s => s.PricingPlan)
            .FirstOrDefaultAsync(s => s.UserId == userId);
    }

    public async Task CancelSubscriptionAsync(int userId)
    {
        var subscription = await _context.Subscriptions.FirstOrDefaultAsync(s => s.UserId == userId);
        if (subscription == null)
            throw new InvalidOperationException("No active subscription found");

        subscription.Status = "canceled";
        subscription.EndDate = DateTime.UtcNow;
        await _context.SaveChangesAsync();
    }
}
