using System;
using Microsoft.EntityFrameworkCore;


public class AppDbContext : DbContext
{

    protected override void OnConfiguring(DbContextOptionsBuilder options)
    {
        var connectionString = Environment.GetEnvironmentVariable("DOTNET_ConnectionStrings__SqlDatabase") 
                               ?? "Server=192.168.56.121;Port=3306;Database=mydatabase;User Id=root;Password=supersecretpassword;";
        options.UseMySql(connectionString, ServerVersion.AutoDetect(connectionString));
    }
}