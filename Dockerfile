# ========================================
# BUILD STAGE
# ========================================
FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /src

# Copy solution and project files
COPY dotnet-2526-vc2/Rise.sln ./
COPY dotnet-2526-vc2/src/ src/
COPY dotnet-2526-vc2/tests/ tests/

# Install EF Core CLI tools
RUN dotnet tool install --global dotnet-ef
ENV PATH="$PATH:/root/.dotnet/tools"

# Restore all projects
RUN dotnet restore Rise.sln

# --- Run EF migrations ---
# Note: using full correct paths
WORKDIR /src
RUN dotnet ef migrations add InitialCreate \
    --startup-project src/Rise.Server/Rise.Server.csproj \
    --project src/Rise.Persistence/Rise.Persistence.csproj

RUN dotnet ef database update \
    --startup-project src/Rise.Server/Rise.Server.csproj \
    --project src/Rise.Persistence/Rise.Persistence.csproj

# --- Build & publish ---
RUN dotnet build Rise.sln -c Release --no-restore

RUN dotnet publish src/Rise.Server/Rise.Server.csproj \
    -c Release \
    -o /app/publish \
    /p:UseAppHost=false

# ========================================
# RUNTIME STAGE
# ========================================
FROM mcr.microsoft.com/dotnet/aspnet:9.0 AS runtime
WORKDIR /app

COPY --from=build /app/publish .

EXPOSE 8080
ENTRYPOINT ["dotnet", "Rise.Server.dll"]
