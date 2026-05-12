using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace VulpiFit.API.Migrations
{
    /// <inheritdoc />
    public partial class AjoutFeedbackFinDeJournee : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            // Intentionnellement vide:
            // le schéma (Users, Missions, MissionLogs) est déjà créé/étendu
            // par les migrations précédentes de la chaîne historique.
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "MissionLogs");

            migrationBuilder.DropTable(
                name: "Missions");

            migrationBuilder.DropTable(
                name: "Users");
        }
    }
}
