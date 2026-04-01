using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using Microsoft.AspNetCore.Mvc.Testing;

namespace AiluApi.Tests;

public class ForumControllerTests : IClassFixture<WebApplicationFactory<Program>>
{
    private readonly WebApplicationFactory<Program> _factory;

    public ForumControllerTests(WebApplicationFactory<Program> factory)
    {
        _factory = factory;
    }

    private async Task<HttpClient> GetAuthClientAsync(string email)
    {
        var http = _factory.CreateClient();
        var token = await TestAuthHelper.RegisterAndLoginAsync(http, email, "pass123");
        http.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", token);
        return http;
    }

    [Fact]
    public async Task GetPosts_ReturnsOk()
    {
        var http = _factory.CreateClient();
        var response = await http.GetAsync("/api/forum");
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }

    [Fact]
    public async Task CreatePost_Authenticated_ReturnsCreated()
    {
        var http = await GetAuthClientAsync("forum_create@example.com");
        var response = await http.PostAsJsonAsync("/api/forum", new
        {
            Title = "Introduction to Contract Law",
            Content = "Contract law fundamentals for aspirants...",
            Category = "Legal Education"
        });
        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
    }

    [Fact]
    public async Task GetPost_ValidId_ReturnsOk()
    {
        var http = await GetAuthClientAsync("forum_get@example.com");
        var createResp = await http.PostAsJsonAsync("/api/forum", new
        {
            Title = "Test Post",
            Content = "Test content",
            Category = "General"
        });
        var postObj = await createResp.Content.ReadFromJsonAsync<PostIdResponse>();

        var getResp = await _factory.CreateClient().GetAsync($"/api/forum/{postObj!.Id}");
        Assert.Equal(HttpStatusCode.OK, getResp.StatusCode);
    }

    [Fact]
    public async Task GetPost_NotFound_Returns404()
    {
        var http = _factory.CreateClient();
        var response = await http.GetAsync("/api/forum/99999");
        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    [Fact]
    public async Task GetCategories_ReturnsOk()
    {
        var http = _factory.CreateClient();
        var response = await http.GetAsync("/api/forum/categories");
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }

    [Fact]
    public async Task CreatePost_Unauthenticated_Returns401()
    {
        var http = _factory.CreateClient();
        var response = await http.PostAsJsonAsync("/api/forum", new { Title = "Test", Content = "Test" });
        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [Fact]
    public async Task GetPosts_WithCategoryFilter_ReturnsOk()
    {
        var http = _factory.CreateClient();
        var response = await http.GetAsync("/api/forum?category=General");
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }
}

public class PostIdResponse
{
    public int Id { get; set; }
}
