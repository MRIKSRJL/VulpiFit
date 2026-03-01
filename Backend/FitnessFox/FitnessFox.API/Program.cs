using FitnessFox.API.Data;
using Microsoft.EntityFrameworkCore;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using System.Text;

var builder = WebApplication.CreateBuilder(args);

// 1. LA CLÉ SECRÈTE DE FITNESS FOX (À garder secrète !)
var jwtKey = "LaCleSecreteDeFitnessFoxSuperLongueEtSecurisee2026!"; // Doit faire au moins 32 caractères
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
builder.Services.AddDbContext<ApplicationDbContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection")));
builder.Services.AddHttpClient<FitnessFox.API.Services.GroqService>();
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

        // 🛑 LIGNE SUPPRIMÉE : context.Database.EnsureDeleted();

        // Cette commande crée la base uniquement si elle n'existe pas encore.
        // Si elle existe déjà avec tes comptes et tes missions, elle la conserve intacte !
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