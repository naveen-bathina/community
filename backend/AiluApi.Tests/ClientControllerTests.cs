using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using Microsoft.AspNetCore.Mvc.Testing;

namespace AiluApi.Tests;

public class ClientControllerTests : IClassFixture<WebApplicationFactory<Program>>
{
    private readonly WebApplicationFactory<Program> _factory;

    public ClientControllerTests(WebApplicationFactory<Program> factory)
    {
        _factory = factory;
    }

    private async Task<(HttpClient http, string token)> GetAuthenticatedClientAsync(string email)
    {
        var http = _factory.CreateClient();
        var token = await TestAuthHelper.RegisterAndLoginAsync(http, email, "pass123");
        http.DefaultRequestHeaders.Authorization = new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", token);
        return (http, token);
    }

    [Fact]
    public async Task CreateClient_ReturnsCreated()
    {
        var (http, _) = await GetAuthenticatedClientAsync("client_create@example.com");
        var response = await http.PostAsJsonAsync("/api/clients", new
        {
            Name = "Test Law Firm",
            Type = "firm",
            Email = "firm@example.com",
            Phone = "9876543210"
        });
        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
    }

    [Fact]
    public async Task GetClients_ReturnsOk()
    {
        var (http, _) = await GetAuthenticatedClientAsync("client_list@example.com");
        var response = await http.GetAsync("/api/clients");
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }

    [Fact]
    public async Task GetClient_NotFound_Returns404()
    {
        var (http, _) = await GetAuthenticatedClientAsync("client_notfound@example.com");
        var response = await http.GetAsync("/api/clients/99999");
        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    [Fact]
    public async Task AddContact_ValidClient_ReturnsOk()
    {
        var (http, _) = await GetAuthenticatedClientAsync("client_contact@example.com");

        // Create client first
        var createResp = await http.PostAsJsonAsync("/api/clients", new { Name = "Contact Test Firm", Type = "firm" });
        var clientObj = await createResp.Content.ReadFromJsonAsync<IdResponse>();

        // Add contact
        var contactResp = await http.PostAsJsonAsync($"/api/clients/{clientObj!.Id}/contacts", new
        {
            Name = "John Doe",
            Email = "john@firm.com",
            Role = "primary"
        });
        Assert.Equal(HttpStatusCode.OK, contactResp.StatusCode);
    }

    [Fact]
    public async Task CreateInvoice_ValidClient_ReturnsOk()
    {
        var (http, _) = await GetAuthenticatedClientAsync("client_invoice@example.com");

        // Create client
        var createResp = await http.PostAsJsonAsync("/api/clients", new { Name = "Invoice Test Firm", Type = "corporate" });
        var clientObj = await createResp.Content.ReadFromJsonAsync<IdResponse>();

        // Create invoice
        var invoiceResp = await http.PostAsJsonAsync($"/api/clients/{clientObj!.Id}/invoices", new
        {
            Amount = 5000.00,
            GstAmount = 900.00,
            DueDate = DateTime.UtcNow.AddDays(30)
        });
        Assert.Equal(HttpStatusCode.OK, invoiceResp.StatusCode);
    }

    [Fact]
    public async Task Unauthenticated_GetClients_Returns401()
    {
        var http = _factory.CreateClient();
        var response = await http.GetAsync("/api/clients");
        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }
}

public class IdResponse
{
    public int Id { get; set; }
}
