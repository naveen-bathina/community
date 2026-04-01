using System.Net;
using System.Net.Http.Json;
using AiluApi;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Xunit;

namespace AiluApi.Tests;

public class AuthControllerTests : IClassFixture<CustomWebApplicationFactory>
{
    private readonly CustomWebApplicationFactory _factory;

    public AuthControllerTests(CustomWebApplicationFactory factory)
    {
        _factory = factory;
    }

    [Fact]
    public async Task Register_InvalidEmail_ReturnsBadRequest()
    {
        // Arrange
        var client = _factory.CreateClient();
        var registerRequest = new
        {
            Email = "invalid-email",
            Password = "password123"
        };

        // Act
        var response = await client.PostAsJsonAsync("/api/auth/register", registerRequest);

        // Assert
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task Register_DuplicateEmail_ReturnsBadRequest()
    {
        // Arrange
        var client = _factory.CreateClient();
        var registerRequest = new
        {
            Email = "duplicate@example.com",
            Password = "password123"
        };

        // First registration
        await client.PostAsJsonAsync("/api/auth/register", registerRequest);

        // Act - second registration with same email
        var response = await client.PostAsJsonAsync("/api/auth/register", registerRequest);

        // Assert
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task Register_EmptyPassword_ReturnsBadRequest()
    {
        // Arrange
        var client = _factory.CreateClient();
        var registerRequest = new
        {
            Email = "test@example.com",
            Password = ""
        };

        // Act
        var response = await client.PostAsJsonAsync("/api/auth/register", registerRequest);

        // Assert
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task Login_ValidCredentials_ReturnsSuccess()
    {
        // Arrange
        var client = _factory.CreateClient();

        // First register the user
        var registerRequest = new
        {
            Email = "test@example.com",
            Password = "password123"
        };
        await client.PostAsJsonAsync("/api/auth/register", registerRequest);

        // Now login
        var loginRequest = new
        {
            Email = "test@example.com",
            Password = "password123"
        };

        // Act
        var response = await client.PostAsJsonAsync("/api/auth/login", loginRequest);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var result = await response.Content.ReadFromJsonAsync<LoginResponse>();
        Assert.NotNull(result);
        Assert.NotNull(result.Token);
        Assert.NotEmpty(result.Token);
    }

    [Fact]
    public async Task Login_InvalidCredentials_ReturnsUnauthorized()
    {
        // Arrange
        var client = _factory.CreateClient();

        // Register the user
        var registerRequest = new
        {
            Email = "test@example.com",
            Password = "password123"
        };
        await client.PostAsJsonAsync("/api/auth/register", registerRequest);

        // Now try login with wrong password
        var loginRequest = new
        {
            Email = "test@example.com",
            Password = "wrongpassword"
        };

        // Act
        var response = await client.PostAsJsonAsync("/api/auth/login", loginRequest);

        // Assert
        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [Fact]
    public async Task GetMe_ValidToken_ReturnsUserInfo()
    {
        // Arrange
        var client = _factory.CreateClient();

        // Register and login to get token
        var registerRequest = new
        {
            Email = "me@example.com",
            Password = "password123"
        };
        await client.PostAsJsonAsync("/api/auth/register", registerRequest);

        var loginRequest = new
        {
            Email = "me@example.com",
            Password = "password123"
        };
        var loginResponse = await client.PostAsJsonAsync("/api/auth/login", loginRequest);
        var loginResult = await loginResponse.Content.ReadFromJsonAsync<LoginResponse>();
        client.DefaultRequestHeaders.Authorization = new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", loginResult.Token);

        // Act
        var response = await client.GetAsync("/api/auth/me");

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var userInfo = await response.Content.ReadFromJsonAsync<UserInfo>();
        Assert.NotNull(userInfo);
        Assert.Equal("me@example.com", userInfo.Email);
    }
}

public class LoginResponse
{
    public string Token { get; set; }
}

public class UserInfo
{
    public string Email { get; set; }
}

public class CustomWebApplicationFactory : WebApplicationFactory<Program>
{
    protected override void ConfigureWebHost(IWebHostBuilder builder)
    {
        builder.ConfigureAppConfiguration((context, config) =>
        {
            // Override JWT settings for tests
            config.Sources.Clear();
            config.AddInMemoryCollection(new Dictionary<string, string>
            {
                ["Jwt:Key"] = "YourSuperSecretKeyHere12345678901234567890",
                ["Jwt:Issuer"] = "AiluApi",
                ["Jwt:Audience"] = "AiluUsers"
            });
        });

        builder.ConfigureServices(services =>
        {
            // Override the DbContext to use in-memory for tests
            var descriptor = services.SingleOrDefault(d => d.ServiceType == typeof(DbContextOptions<AiluApi.Data.AppDbContext>));
            if (descriptor != null)
            {
                services.Remove(descriptor);
            }
            services.AddDbContext<AiluApi.Data.AppDbContext>(options =>
            {
                options.UseInMemoryDatabase("TestDb");
            });
        });
    }
}