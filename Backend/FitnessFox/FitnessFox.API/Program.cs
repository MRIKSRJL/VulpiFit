using FitnessFox.API.Data;
using Microsoft.EntityFrameworkCore;

var builder = WebApplication.CreateBuilder(args);

// CONFIGURATION DE LA BDD
builder.Services.AddDbContext<ApplicationDbContext>(options =>
    options.UseSqlServer("Server=(localdb)\\mssqllocaldb;Database=FitnessFox_Final;Trusted_Connection=True;MultipleActiveResultSets=true"));

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

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseAuthorization();
app.MapControllers();
app.Run();