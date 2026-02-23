using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace FitnessFox.API.Migrations
{
    /// <inheritdoc />
    public partial class CreationInitiale : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            // La fonction existe, mais elle est VIDE ! 
            // Ainsi, la création initiale est "validée" sans rien casser.
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "Missions");
        }
    }
}