using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using Microsoft.AspNetCore.Mvc.Testing;

namespace AiluApi.Tests;

public class SubAssociationControllerTests : IClassFixture<WebApplicationFactory<Program>>
{
    private readonly WebApplicationFactory<Program> _factory;

    public SubAssociationControllerTests(WebApplicationFactory<Program> factory)
    {
        _factory = factory;
    }

    private async Task<HttpClient> GetAuthClientAsync(string email, string role = "member")
    {
        var http = _factory.CreateClient();
        var token = await TestAuthHelper.RegisterAndLoginAsync(http, email, "pass1234", role);
        http.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", token);
        return http;
    }

    [Fact]
    public async Task GetAssociations_ReturnsOk()
    {
        var http = _factory.CreateClient();
        var response = await http.GetAsync("/api/associations");
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }

    [Fact]
    public async Task CreateAssociation_AsAdvocate_ReturnsCreated()
    {
        var http = await GetAuthClientAsync("assoc_create_advocate@example.com", "advocate");
        var response = await http.PostAsJsonAsync("/api/associations", new
        {
            Name = "Delhi Advocates Circle",
            Description = "Delhi-based advocate group"
        });
        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
    }

    [Fact]
    public async Task CreateAssociation_AsMember_ReturnsBadRequest()
    {
        var http = await GetAuthClientAsync("assoc_create_member@example.com", "member");
        var response = await http.PostAsJsonAsync("/api/associations", new
        {
            Name = "Invalid Association"
        });
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task RequestJoin_ValidAssociation_ReturnsOk()
    {
        // Create advocate to create association
        var advocateHttp = await GetAuthClientAsync("assoc_join_advocate@example.com", "advocate");
        var createResp = await advocateHttp.PostAsJsonAsync("/api/associations", new
        {
            Name = "Join Test Association"
        });
        var assocObj = await createResp.Content.ReadFromJsonAsync<AssocIdResponse>();

        // Member requests to join
        var memberHttp = await GetAuthClientAsync("assoc_join_member@example.com", "member");
        var joinResp = await memberHttp.PostAsJsonAsync($"/api/associations/{assocObj!.Id}/join", new { });
        Assert.Equal(HttpStatusCode.OK, joinResp.StatusCode);
    }

    [Fact]
    public async Task GetAssociation_NotFound_Returns404()
    {
        var http = await GetAuthClientAsync("assoc_notfound@example.com");
        var response = await http.GetAsync("/api/associations/99999");
        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    [Fact]
    public async Task CreateAssociation_Unauthenticated_Returns401()
    {
        var http = _factory.CreateClient();
        var response = await http.PostAsJsonAsync("/api/associations", new { Name = "Test" });
        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }
}

public class AssocIdResponse
{
    public int Id { get; set; }
}
