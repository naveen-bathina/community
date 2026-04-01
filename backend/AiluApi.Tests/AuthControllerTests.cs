using System.Net;
using System.Net.Http.Json;
using AiluApi;
using Microsoft.AspNetCore.Mvc.Testing;
using Xunit;

namespace AiluApi.Tests;

public class AuthControllerTests : IClassFixture<WebApplicationFactory<Program>>
{
    private readonly WebApplicationFactory<Program> _factory;

    public AuthControllerTests(WebApplicationFactory<Program> factory)
    {
        _factory = factory;
    }

    [Fact]
    public async Task Register_ValidUser_ReturnsSuccess()
    {
        // Arrange
        var client = _factory.CreateClient();
        var registerRequest = new
        {
            Email = "register@example.com",
            Password = "password123"
        };

        // Act
        var response = await client.PostAsJsonAsync("/api/auth/register", registerRequest);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
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
    public async Task Register_InvalidEmail_ReturnsBadRequest()
    {
        // Arrange
        var client = _factory.CreateClient();
        var registerRequest = new
        {
            Email = "not-an-email",
            Password = "password123"
        };

        // Act
        var response = await client.PostAsJsonAsync("/api/auth/register", registerRequest);

        // Assert
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task Register_PasswordTooShort_ReturnsBadRequest()
    {
        // Arrange
        var client = _factory.CreateClient();
        var registerRequest = new
        {
            Email = "short@example.com",
            Password = "short7x"
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
        await client.PostAsJsonAsync("/api/auth/register", registerRequest);

        // Act - register same email again
        var response = await client.PostAsJsonAsync("/api/auth/register", registerRequest);

        // Assert
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }
}

public class LoginResponse
{
    public string? Token { get; set; }
}