using AiluApi.Models;
using Microsoft.EntityFrameworkCore;

namespace AiluApi.Data;

public class AppDbContext : DbContext
{
    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) { }

    public DbSet<User> Users { get; set; }
    public DbSet<Profile> Profiles { get; set; }
    public DbSet<PricingPlan> PricingPlans { get; set; }
    public DbSet<Subscription> Subscriptions { get; set; }
    public DbSet<Client> Clients { get; set; }
    public DbSet<ClientContact> ClientContacts { get; set; }
    public DbSet<Invoice> Invoices { get; set; }
    public DbSet<Case> Cases { get; set; }
    public DbSet<CaseDocument> CaseDocuments { get; set; }
    public DbSet<CaseHistory> CaseHistories { get; set; }
    public DbSet<VakalatAssignment> VakalatAssignments { get; set; }
    public DbSet<SubAssociation> SubAssociations { get; set; }
    public DbSet<AssociationMembership> AssociationMemberships { get; set; }
    public DbSet<Event> Events { get; set; }
    public DbSet<EventBooking> EventBookings { get; set; }
    public DbSet<Post> Posts { get; set; }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        // User has one Profile
        modelBuilder.Entity<User>()
            .HasOne(u => u.Profile)
            .WithOne(p => p.User)
            .HasForeignKey<Profile>(p => p.UserId);

        // User has one Subscription
        modelBuilder.Entity<User>()
            .HasOne(u => u.Subscription)
            .WithOne(s => s.User)
            .HasForeignKey<Subscription>(s => s.UserId);

        // Client -> Contacts
        modelBuilder.Entity<ClientContact>()
            .HasOne(cc => cc.Client)
            .WithMany(c => c.Contacts)
            .HasForeignKey(cc => cc.ClientId);

        // Client -> Invoices
        modelBuilder.Entity<Invoice>()
            .HasOne(i => i.Client)
            .WithMany(c => c.Invoices)
            .HasForeignKey(i => i.ClientId);

        // Case -> Invoice (optional)
        modelBuilder.Entity<Invoice>()
            .HasOne(i => i.Case)
            .WithMany(c => c.Invoices)
            .HasForeignKey(i => i.CaseId)
            .IsRequired(false);

        // Client -> Cases
        modelBuilder.Entity<Case>()
            .HasOne(c => c.Client)
            .WithMany(cl => cl.Cases)
            .HasForeignKey(c => c.ClientId);

        // Case -> Documents
        modelBuilder.Entity<CaseDocument>()
            .HasOne(cd => cd.Case)
            .WithMany(c => c.Documents)
            .HasForeignKey(cd => cd.CaseId);

        // Case -> History
        modelBuilder.Entity<CaseHistory>()
            .HasOne(ch => ch.Case)
            .WithMany(c => c.History)
            .HasForeignKey(ch => ch.CaseId);

        // Case -> VakalatAssignments
        modelBuilder.Entity<VakalatAssignment>()
            .HasOne(va => va.Case)
            .WithMany(c => c.Assignments)
            .HasForeignKey(va => va.CaseId);

        // VakalatAssignment -> Advocate (User)
        modelBuilder.Entity<VakalatAssignment>()
            .HasOne(va => va.Advocate)
            .WithMany(u => u.CaseAssignments)
            .HasForeignKey(va => va.AdvocateUserId)
            .OnDelete(DeleteBehavior.Restrict);

        // SubAssociation -> Memberships
        modelBuilder.Entity<AssociationMembership>()
            .HasOne(am => am.SubAssociation)
            .WithMany(sa => sa.Memberships)
            .HasForeignKey(am => am.SubAssociationId);

        // AssociationMembership -> User
        modelBuilder.Entity<AssociationMembership>()
            .HasOne(am => am.User)
            .WithMany(u => u.AssociationMemberships)
            .HasForeignKey(am => am.UserId)
            .OnDelete(DeleteBehavior.Restrict);

        // SubAssociation -> Leader (User)
        modelBuilder.Entity<SubAssociation>()
            .HasOne(sa => sa.Leader)
            .WithMany()
            .HasForeignKey(sa => sa.LeaderUserId)
            .OnDelete(DeleteBehavior.Restrict);

        // Event -> Organizer (User)
        modelBuilder.Entity<Event>()
            .HasOne(e => e.Organizer)
            .WithMany()
            .HasForeignKey(e => e.OrganizerUserId)
            .OnDelete(DeleteBehavior.Restrict);

        // Event -> Bookings
        modelBuilder.Entity<EventBooking>()
            .HasOne(eb => eb.Event)
            .WithMany(e => e.Bookings)
            .HasForeignKey(eb => eb.EventId);

        // EventBooking -> User
        modelBuilder.Entity<EventBooking>()
            .HasOne(eb => eb.User)
            .WithMany()
            .HasForeignKey(eb => eb.UserId)
            .OnDelete(DeleteBehavior.Restrict);

        // Post -> Author (User)
        modelBuilder.Entity<Post>()
            .HasOne(p => p.Author)
            .WithMany()
            .HasForeignKey(p => p.AuthorUserId)
            .OnDelete(DeleteBehavior.Restrict);

        // PricingPlan -> Subscriptions
        modelBuilder.Entity<Subscription>()
            .HasOne(s => s.PricingPlan)
            .WithMany(pp => pp.Subscriptions)
            .HasForeignKey(s => s.PricingPlanId);
    }
}