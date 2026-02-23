using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace FitnessFox.API.Migrations
{
    /// <inheritdoc />
    public partial class AddFeedback : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "LastDifficulty",
                table: "Users",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "LastFeedback",
                table: "Users",
                type: "nvarchar(max)",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "LastDifficulty",
                table: "Users");

            migrationBuilder.DropColumn(
                name: "LastFeedback",
                table: "Users");
        }
    }
}