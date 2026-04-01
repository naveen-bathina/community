using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using Microsoft.AspNetCore.Mvc.Testing;

namespace AiluApi.Tests;

public class EventControllerTests : IClassFixture<WebApplicationFactory<Program>>
{
    private readonly WebApplicationFactory<Program> _factory;

    public EventControllerTests(WebApplicationFactory<Program> factory)
    {
        _factory = factory;
    }

    private async Task<HttpClient> GetAuthClientAsync(string email)
    {
        var http = _factory.CreateClient();
        var token = await TestAuthHelper.RegisterAndLoginAsync(http, email, "pass1234");
        http.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", token);
        return http;
    }

    [Fact]
    public async Task GetEvents_ReturnsOk()
    {
        var http = _factory.CreateClient();
        var response = await http.GetAsync("/api/events");
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }

    [Fact]
    public async Task CreateEvent_Authenticated_ReturnsCreated()
    {
        var http = await GetAuthClientAsync("event_create@example.com");
        var response = await http.PostAsJsonAsync("/api/events", new
        {
            Title = "Legal Workshop 2024",
            Description = "Workshop on corporate law",
            Location = "Mumbai",
            StartDate = DateTime.UtcNow.AddDays(7),
            EndDate = DateTime.UtcNow.AddDays(7).AddHours(3),
            Price = 500.00,
            Capacity = 50
        });
        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
    }

    [Fact]
    public async Task BookEvent_ValidEvent_ReturnsOk()
    {
        var organizerHttp = await GetAuthClientAsync("event_organizer@example.com");
        var createResp = await organizerHttp.PostAsJsonAsync("/api/events", new
        {
            Title = "Booking Test Event",
            StartDate = DateTime.UtcNow.AddDays(7),
            EndDate = DateTime.UtcNow.AddDays(7).AddHours(2),
            Capacity = 10
        });
        var eventObj = await createResp.Content.ReadFromJsonAsync<EventIdResponse>();

        var attendeeHttp = await GetAuthClientAsync("event_attendee@example.com");
        var bookResp = await attendeeHttp.PostAsJsonAsync($"/api/events/{eventObj!.Id}/book", new { });
        Assert.Equal(HttpStatusCode.OK, bookResp.StatusCode);
    }

    [Fact]
    public async Task BookEvent_TwiceByUser_ReturnsBadRequest()
    {
        var organizerHttp = await GetAuthClientAsync("event_organizer2@example.com");
        var createResp = await organizerHttp.PostAsJsonAsync("/api/events", new
        {
            Title = "Double Book Test",
            StartDate = DateTime.UtcNow.AddDays(7),
            EndDate = DateTime.UtcNow.AddDays(7).AddHours(2)
        });
        var eventObj = await createResp.Content.ReadFromJsonAsync<EventIdResponse>();

        var attendeeHttp = await GetAuthClientAsync("event_double_attendee@example.com");
        await attendeeHttp.PostAsJsonAsync($"/api/events/{eventObj!.Id}/book", new { });
        var secondBookResp = await attendeeHttp.PostAsJsonAsync($"/api/events/{eventObj.Id}/book", new { });
        Assert.Equal(HttpStatusCode.BadRequest, secondBookResp.StatusCode);
    }

    [Fact]
    public async Task GetEvent_NotFound_Returns404()
    {
        var http = _factory.CreateClient();
        var response = await http.GetAsync("/api/events/99999");
        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    [Fact]
    public async Task CreateEvent_Unauthenticated_Returns401()
    {
        var http = _factory.CreateClient();
        var response = await http.PostAsJsonAsync("/api/events", new { Title = "Test", StartDate = DateTime.UtcNow, EndDate = DateTime.UtcNow.AddHours(1) });
        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }
}

public class EventIdResponse
{
    public int Id { get; set; }
}
