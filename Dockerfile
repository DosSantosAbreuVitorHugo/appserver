# ========================================
# BUILD STAGE
# ========================================
FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /src

# Copy solution file
COPY dotnet-2526-vc2/Rise.sln ./

# Copy all project files (src/)
COPY dotnet-2526-vc2/src/ src/

# Copy all test project files (tests/)
COPY dotnet-2526-vc2/tests/ tests/

RUN dotnet ef migrations add YourMigrationName --startup-project Rise.Server --project Rise.Persistence

RUN dotnet ef database update --startup-project Rise.Server --project Rise.Persistence

# Restore all projects in the solution
RUN dotnet restore Rise.sln

# Build the solution
RUN dotnet build Rise.sln -c Release --no-restore

# Publish the server project only
RUN dotnet publish src/Rise.Server/Rise.Server.csproj \
    -c Release \
    -o /app/publish \
    /p:UseAppHost=false

# ========================================
# RUNTIME STAGE
# ========================================
FROM mcr.microsoft.com/dotnet/aspnet:9.0 AS runtime
WORKDIR /app

# Copy the published output from build stage
COPY --from=build /app/publish .

# Expose default ASP.NET port
EXPOSE 8080

# Run the application
ENTRYPOINT ["dotnet", "Rise.Server.dll"]
