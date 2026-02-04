using FitnessFox.API.Data;
using Microsoft.EntityFrameworkCore;

var builder = WebApplication.CreateBuilder(args);

// 1. Ajouter les services (Les outils)
builder.Services.AddControllers();

// --- ACTIVATION DE SWAGGER (L'interface visuelle) ---
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();
// ----------------------------------------------------

// --- CONNEXION BDD ---
builder.Services.AddDbContext<ApplicationDbContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection")));
// ---------------------

var app = builder.Build();

// 2. Configurer le pipeline (L'ordre des actions)
if (app.Environment.IsDevelopment())
{
    // --- Lancer l'interface Swagger ---
    app.UseSwagger();
    app.UseSwaggerUI(); // C'est cette ligne qui crée la page web !
}

app.UseHttpsRedirection();

app.UseAuthorization();

app.MapControllers();

app.Run();