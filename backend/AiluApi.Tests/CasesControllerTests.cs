using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using AiluApi.Models;
using Microsoft.AspNetCore.Mvc.Testing;

namespace AiluApi.Tests;

public class CasesControllerTests : IClassFixture<CustomWebApplicationFactory>
{
    private readonly HttpClient _client;
    private readonly CustomWebApplicationFactory _factory;

    public CasesControllerTests(CustomWebApplicationFactory factory)
    {
        _factory = factory;
        _client = factory.CreateClient();
    }

    [Fact]
    public async Task CreateCase_ValidData_ReturnsCreated()
    {
        // First, register and login to get token
        var registerResponse = await _client.PostAsJsonAsync("/api/auth/register", new { Email = "test@example.com", Password = "password123" });
        registerResponse.EnsureSuccessStatusCode();

        var loginResponse = await _client.PostAsJsonAsync("/api/auth/login", new { Email = "test@example.com", Password = "password123" });
        loginResponse.EnsureSuccessStatusCode();

        var loginResult = await loginResponse.Content.ReadFromJsonAsync<LoginResponse>();
        var token = loginResult!.Token;

        _client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", token);

        // Now create case
        var createResponse = await _client.PostAsJsonAsync("/api/cases", new { Title = "Test Case", Description = "Test Description", AssignedUserId = 1 });
        Assert.Equal(HttpStatusCode.Created, createResponse.StatusCode);

        var createdCase = await createResponse.Content.ReadFromJsonAsync<Case>();
        Assert.NotNull(createdCase);
        Assert.Equal("Test Case", createdCase.Title);
        Assert.Equal("Test Description", createdCase.Description);
        Assert.Equal(1, createdCase.AssignedUserId);
        Assert.Equal(CaseStatus.Open, createdCase.Status);
    }

    [Fact]
    public async Task GetCases_ReturnsCases()
    {
        // Similar setup
        var registerResponse = await _client.PostAsJsonAsync("/api/auth/register", new { Email = "test2@example.com", Password = "password123" });
        registerResponse.EnsureSuccessStatusCode();

        var loginResponse = await _client.PostAsJsonAsync("/api/auth/login", new { Email = "test2@example.com", Password = "password123" });
        loginResponse.EnsureSuccessStatusCode();

        var loginResult = await loginResponse.Content.ReadFromJsonAsync<LoginResponse>();
        var token = loginResult!.Token;

        _client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", token);

        // Create a case
        var createResponse = await _client.PostAsJsonAsync("/api/cases", new { Title = "Test Case 2", Description = "Test Description 2", AssignedUserId = 2 });
        createResponse.EnsureSuccessStatusCode();

        // Get cases
        var getResponse = await _client.GetAsync("/api/cases");
        Assert.Equal(HttpStatusCode.OK, getResponse.StatusCode);

        var cases = await getResponse.Content.ReadFromJsonAsync<List<Case>>();
        Assert.NotNull(cases);
        Assert.Contains(cases, c => c.Title == "Test Case 2");
    }

    [Fact]
    public async Task CreateCase_Unauthorized_ReturnsUnauthorized()
    {
        // Without token
        var createResponse = await _client.PostAsJsonAsync("/api/cases", new { Title = "Test Case", Description = "Test Description", AssignedUserId = 1 });
        Assert.Equal(HttpStatusCode.Unauthorized, createResponse.StatusCode);
    }
}