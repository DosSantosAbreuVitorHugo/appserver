# ========================================
# BUILD STAGE
# ========================================
FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /src

# Copy the solution and restore dependencies
COPY dotnet-2526-vc2/Rise.sln ./
COPY dotnet-2526-vc2/src/Rise.Server/Rise.Server.csproj src/Rise.Server/
COPY dotnet-2526-vc2/src/Rise.Client/Rise.Client.csproj src/Rise.Client/
COPY dotnet-2526-vc2/src/Rise.Domain/Rise.Domain.csproj src/Rise.Domain/
COPY dotnet-2526-vc2/src/Rise.Services/Rise.Services.csproj src/Rise.Services/
COPY dotnet-2526-vc2/src/Rise.Shared/Rise.Shared.csproj src/Rise.Shared/
COPY dotnet-2526-vc2/src/Rise.Persistence/Rise.Persistence.csproj src/Rise.Persistence/

RUN dotnet restore Rise.sln

# Copy everything else and build
COPY dotnet-2526-vc2/. .
RUN dotnet publish src/Rise.Server/Rise.Server.csproj -c Release -o /app/publish /p:UseAppHost=false

# ========================================
# RUNTIME STAGE
# ========================================
FROM mcr.microsoft.com/dotnet/aspnet:9.0 AS runtime
WORKDIR /app
COPY --from=build /app/publish .

# Expose default ASP.NET port
EXPOSE 8080

ENTRYPOINT ["dotnet", "Rise.Server.dll"]
