# ========================================
# BUILD STAGE
# ========================================
FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /src

# Copy solution and projects
COPY dotnet-2526-vc2/Rise.sln ./
COPY dotnet-2526-vc2/src/ src/
COPY dotnet-2526-vc2/tests/ tests/

# Install EF Core CLI globally
RUN dotnet tool install --global dotnet-ef
ENV PATH="$PATH:/root/.dotnet/tools"

# Restore, build, and publish
RUN dotnet restore Rise.sln
RUN dotnet build Rise.sln -c Release --no-restore
RUN dotnet publish src/Rise.Server/Rise.Server.csproj -c Release -o /app/publish /p:UseAppHost=false

# Run migrations inside the SDK image
RUN dotnet ef database update --startup-project src/Rise.Server --project src/Rise.Persistence

# ========================================
# RUNTIME STAGE
# ========================================
FROM mcr.microsoft.com/dotnet/aspnet:9.0 AS runtime
WORKDIR /app

# Copy published output
COPY --from=build /app/publish .

# Expose ASP.NET port
EXPOSE 8080

ENTRYPOINT ["dotnet", "Rise.Server.dll"]
