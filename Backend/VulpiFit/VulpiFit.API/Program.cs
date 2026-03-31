using VulpiFit.API.Data;
using Microsoft.EntityFrameworkCore;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using System.Text;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Configuration;

var builder = WebApplication.CreateBuilder(args);

// 1. LA CLÉ SECRÈTE DE VulpiFit (À garder secrète !)
var jwtKey = "LaCleSecreteDeVulpiFitSuperLongueEtSecurisee2026!"; // Doit faire au moins 32 caractères
var keyBytes = Encoding.UTF8.GetBytes(jwtKey);

// 2. CONFIGURATION DU VIGILE (Authentification)
builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuerSigningKey = true,
            IssuerSigningKey = new SymmetricSecurityKey(keyBytes),
            ValidateIssuer = false, // On désactive pour le développement
            ValidateAudience = false, // On désactive pour le développement
            ValidateLifetime = true // On vérifie que le bracelet n'est pas expiré
        };
    });

// CONFIGURATION DE LA BDD
// CONFIGURATION DE LA BDD
// Par défaut, on récupère depuis la config ASP.NET (incluant éventuellement user-secrets).
// Mais en mode Development, les user-secrets peuvent écraser appsettings.Development.json.
// Pour faciliter le run local (tests Postman), on force la source appsettings en l'absence de variable d'environnement.
var envOverrideConnectionString = Environment.GetEnvironmentVariable("ConnectionStrings__DefaultConnection");
var defaultConnectionString = string.IsNullOrWhiteSpace(envOverrideConnectionString)
    ? builder.Configuration.GetConnectionString("DefaultConnection")
    : envOverrideConnectionString;

if (builder.Environment.IsDevelopment() && string.IsNullOrWhiteSpace(envOverrideConnectionString))
{
    var jsonOnlyConfig = new ConfigurationBuilder()
        .SetBasePath(builder.Environment.ContentRootPath)
        .AddJsonFile("appsettings.json", optional: true, reloadOnChange: false)
        .AddJsonFile($"appsettings.{builder.Environment.EnvironmentName}.json", optional: true, reloadOnChange: false)
        .Build();

    var devFromJson = jsonOnlyConfig.GetConnectionString("DefaultConnection");
    if (!string.IsNullOrWhiteSpace(devFromJson))
    {
        defaultConnectionString = devFromJson;
    }
}
try
{
    var csb = new SqlConnectionStringBuilder(defaultConnectionString);
    Console.WriteLine($"[DB] Environment={builder.Environment.EnvironmentName} | DataSource={csb.DataSource}");
}
catch
{
    Console.WriteLine($"[DB] Environment={builder.Environment.EnvironmentName} | DefaultConnectionString loaded (could not parse DataSource).");
}

builder.Services.AddDbContext<ApplicationDbContext>(options =>
    options.UseSqlServer(defaultConnectionString));
builder.Services.AddHttpClient<VulpiFit.API.Services.GroqService>();
builder.Services.AddScoped<VulpiFit.API.Services.CoopStreakService>();
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

var app = builder.Build();

// BLOC DE VÉRIFICATION DE LA BASE
using (var scope = app.Services.CreateScope())
{
    var services = scope.ServiceProvider;
    try
    {
        var context = services.GetRequiredService<ApplicationDbContext>();

        //  context.Database.EnsureDeleted();

        // Cette commande crée la base uniquement si elle n'existe pas encore.
        // Si elle existe déjà avec tes comptes et tes missions, elle la conserve intacte 
        context.Database.EnsureCreated();
    }
    catch (Exception ex)
    {
        Console.WriteLine($"ERREUR CRITIQUE BDD : {ex.Message}");
    }
}

app.UseSwagger();
app.UseSwaggerUI();
if (app.Environment.IsDevelopment())
{
    
}

app.UseAuthentication();
app.UseAuthorization();
app.MapControllers();
app.Run();
