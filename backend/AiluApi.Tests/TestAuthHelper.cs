using System.Net.Http.Json;
using Microsoft.AspNetCore.Mvc.Testing;

namespace AiluApi.Tests;

/// <summary>
/// Helper to register a user and retrieve an auth token for integration tests.
/// </summary>
public static class TestAuthHelper
{
    public static async Task<string> RegisterAndLoginAsync(HttpClient client, string email, string password, string role = "member")
    {
        await client.PostAsJsonAsync("/api/auth/register", new { Email = email, Password = password, Role = role });
        var loginResponse = await client.PostAsJsonAsync("/api/auth/login", new { Email = email, Password = password });
        var result = await loginResponse.Content.ReadFromJsonAsync<LoginTokenResponse>();
        return result?.Token ?? string.Empty;
    }
}

public class LoginTokenResponse
{
    public string? Token { get; set; }
}
