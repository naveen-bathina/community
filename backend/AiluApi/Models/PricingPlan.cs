namespace AiluApi.Models;

public class PricingPlan
{
    public int Id { get; set; }
    public required string Name { get; set; }
    public decimal Price { get; set; }
    public string? Description { get; set; }
    public int? TrialDays { get; set; }
    public decimal? DiscountPercent { get; set; }
    public int DurationMonths { get; set; } = 1; // 1=monthly, 3=quarterly, 12=annual
    public bool IsActive { get; set; } = true;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public ICollection<Subscription> Subscriptions { get; set; } = new List<Subscription>();
}
