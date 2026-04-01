namespace AiluApi.Models;

public class Subscription
{
    public int Id { get; set; }
    public int UserId { get; set; }
    public int PricingPlanId { get; set; }
    public string Status { get; set; } = "trial"; // trial, active, past_due, canceled
    public DateTime StartDate { get; set; } = DateTime.UtcNow;
    public DateTime? EndDate { get; set; }
    public bool AutoRenew { get; set; } = true;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public User? User { get; set; }
    public PricingPlan? PricingPlan { get; set; }
}
