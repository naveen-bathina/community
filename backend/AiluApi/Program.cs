using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Npgsql.EntityFrameworkCore.PostgreSQL;
using System.Text;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
builder.Services.AddControllers()
    .AddJsonOptions(options =>
    {
        options.JsonSerializerOptions.ReferenceHandler = System.Text.Json.Serialization.ReferenceHandler.IgnoreCycles;
    });
builder.Services.AddScoped<AiluApi.Services.AuthService>();
builder.Services.AddScoped<AiluApi.Handlers.CreateCaseCommandHandler>();
builder.Services.AddScoped<AiluApi.Handlers.GetCasesQueryHandler>();
builder.Services.AddScoped<AiluApi.Handlers.UpdateCaseStatusCommandHandler>();
builder.Services.AddSingleton<AiluApi.Data.EventStore>();
builder.Services.AddScoped<AiluApi.Services.ProfileService>();
builder.Services.AddScoped<AiluApi.Services.PricingService>();
builder.Services.AddScoped<AiluApi.Services.ClientService>();
builder.Services.AddScoped<AiluApi.Services.CaseService>();
builder.Services.AddScoped<AiluApi.Services.SubAssociationService>();
builder.Services.AddScoped<AiluApi.Services.EventService>();
builder.Services.AddScoped<AiluApi.Services.ForumService>();
builder.Services.AddDbContext<AiluApi.Data.AppDbContext>(options =>
    options.UseNpgsql(builder.Configuration.GetConnectionString("DefaultConnection")));
builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true,
            ValidIssuer = builder.Configuration["Jwt:Issuer"],
            ValidAudience = builder.Configuration["Jwt:Audience"],
            IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(builder.Configuration["Jwt:Key"]!))
        };
    });
builder.Services.AddAuthorization();
builder.Services.AddOpenApi();

var app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
}

app.UseHttpsRedirection();

app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();

app.Run();
