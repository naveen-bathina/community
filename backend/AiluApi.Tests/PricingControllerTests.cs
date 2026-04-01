using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using Microsoft.AspNetCore.Mvc.Testing;

namespace AiluApi.Tests;

public class PricingControllerTests : IClassFixture<WebApplicationFactory<Program>>
{
    private readonly WebApplicationFactory<Program> _factory;

    public PricingControllerTests(WebApplicationFactory<Program> factory)
    {
        _factory = factory;
    }

    [Fact]
    public async Task GetPlans_ReturnsOk()
    {
        var client = _factory.CreateClient();
        var response = await client.GetAsync("/api/pricing/plans");
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }

    [Fact]
    public async Task Subscribe_ValidPlan_ReturnsOk()
    {
        var client = _factory.CreateClient();
        var token = await TestAuthHelper.RegisterAndLoginAsync(client, "pricing_sub@example.com", "pass1234");
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", token);

        // Create a plan first (need admin role – use admin user)
        var adminClient = _factory.CreateClient();
        var adminToken = await TestAuthHelper.RegisterAndLoginAsync(adminClient, "pricing_admin@example.com", "pass1234", "admin");
        adminClient.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", adminToken);
        var planResponse = await adminClient.PostAsJsonAsync("/api/pricing/plans", new
        {
            Name = "Basic",
            Price = 299.00,
            Description = "Basic plan",
            TrialDays = 14
        });
        Assert.Equal(HttpStatusCode.Created, planResponse.StatusCode);
        var plan = await planResponse.Content.ReadFromJsonAsync<PlanResponse>();
        Assert.NotNull(plan);

        // Subscribe the member
        var subResponse = await client.PostAsJsonAsync("/api/pricing/subscribe", new { PlanId = plan!.Id });
        Assert.Equal(HttpStatusCode.OK, subResponse.StatusCode);
    }

    [Fact]
    public async Task GetSubscription_WithoutSubscription_ReturnsNotFound()
    {
        var client = _factory.CreateClient();
        var token = await TestAuthHelper.RegisterAndLoginAsync(client, "pricing_nosub@example.com", "pass1234");
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", token);

        var response = await client.GetAsync("/api/pricing/subscription");
        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    [Fact]
    public async Task GetSubscription_Unauthorized_Returns401()
    {
        var client = _factory.CreateClient();
        var response = await client.GetAsync("/api/pricing/subscription");
        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }
}

public class PlanResponse
{
    public int Id { get; set; }
    public string? Name { get; set; }
}
