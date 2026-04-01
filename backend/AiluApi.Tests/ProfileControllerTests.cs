using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;

namespace AiluApi.Tests;

public class ProfileControllerTests : IClassFixture<CustomWebApplicationFactory>
{
    private readonly CustomWebApplicationFactory _factory;

    public ProfileControllerTests(CustomWebApplicationFactory factory)
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
    public async Task GetProfile_Unauthenticated_ReturnsUnauthorized()
    {
        var http = _factory.CreateClient();
        var response = await http.GetAsync("/api/profile");
        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [Fact]
    public async Task GetProfile_NewUser_ReturnsProfileWithUserEmail()
    {
        var http = await GetAuthClientAsync("profile_get@example.com");
        var response = await http.GetAsync("/api/profile");
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        var profile = await response.Content.ReadFromJsonAsync<ProfileViewResponse>();
        Assert.NotNull(profile);
        Assert.Equal("profile_get@example.com", profile.Email);
    }

    [Fact]
    public async Task UpdateProfile_ValidData_ReturnsOkWithUpdatedProfile()
    {
        var http = await GetAuthClientAsync("profile_update@example.com");

        var response = await http.PutAsJsonAsync("/api/profile", new
        {
            Name = "Jane Doe",
            Phone = "9876543210",
            District = "Chennai",
            State = "Tamil Nadu",
            Bio = "Experienced advocate with 10 years of practice.",
            Specialization = "Criminal Law"
        });

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        var profile = await response.Content.ReadFromJsonAsync<ProfileViewResponse>();
        Assert.NotNull(profile);
        Assert.Equal("Jane Doe", profile.Name);
        Assert.Equal("Chennai", profile.District);
        Assert.Equal("Tamil Nadu", profile.State);
        Assert.Equal("Experienced advocate with 10 years of practice.", profile.Bio);
        Assert.Equal("Criminal Law", profile.Specialization);
    }

    [Fact]
    public async Task UpdateProfile_NameTooLong_ReturnsBadRequest()
    {
        var http = await GetAuthClientAsync("profile_toolong@example.com");

        var response = await http.PutAsJsonAsync("/api/profile", new
        {
            Name = new string('A', 101)
        });

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task UpdateProfile_BioTooLong_ReturnsBadRequest()
    {
        var http = await GetAuthClientAsync("profile_biotoolong@example.com");

        var response = await http.PutAsJsonAsync("/api/profile", new
        {
            Bio = new string('B', 1001)
        });

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task UpdateProfile_PersistedInSubsequentGet()
    {
        var http = await GetAuthClientAsync("profile_persist@example.com");

        await http.PutAsJsonAsync("/api/profile", new
        {
            Name = "Persisted Name",
            Bio = "Persisted bio text",
            BarNumber = "BAR12345"
        });

        var getResponse = await http.GetAsync("/api/profile");
        Assert.Equal(HttpStatusCode.OK, getResponse.StatusCode);

        var profile = await getResponse.Content.ReadFromJsonAsync<ProfileViewResponse>();
        Assert.NotNull(profile);
        Assert.Equal("Persisted Name", profile.Name);
        Assert.Equal("Persisted bio text", profile.Bio);
        Assert.Equal("BAR12345", profile.BarNumber);
    }

    [Fact]
    public async Task UpdateProfile_Unauthenticated_ReturnsUnauthorized()
    {
        var http = _factory.CreateClient();
        var response = await http.PutAsJsonAsync("/api/profile", new { Name = "Test" });
        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [Fact]
    public async Task SearchAdvocates_ReturnsOkAnonymously()
    {
        var http = _factory.CreateClient();
        var response = await http.GetAsync("/api/profile/advocates");
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }
}

public class ProfileViewResponse
{
    public int UserId { get; set; }
    public string? Name { get; set; }
    public string? Email { get; set; }
    public string? Phone { get; set; }
    public string? District { get; set; }
    public string? State { get; set; }
    public string? Bio { get; set; }
    public string? Specialization { get; set; }
    public string? BarNumber { get; set; }
    public string? HighCourt { get; set; }
    public bool KycVerified { get; set; }
    public double Rating { get; set; }
    public bool IsAvailable { get; set; }
    public DateTime UpdatedAt { get; set; }
}
