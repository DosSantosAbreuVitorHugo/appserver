# ========================================
# BUILD STAGE
# ========================================
FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /src

# Copy solution and project files
COPY dotnet-2526-vc2/Rise.sln ./
COPY dotnet-2526-vc2/src/ src/
COPY dotnet-2526-vc2/tests/ tests/

# Restore dependencies
RUN dotnet restore Rise.sln

# Build and publish app
RUN dotnet build Rise.sln -c Release --no-restore
RUN dotnet publish src/Rise.Server/Rise.Server.csproj -c Release -o /app/publish /p:UseAppHost=false

# ========================================
# RUNTIME STAGE
# ========================================
FROM mcr.microsoft.com/dotnet/aspnet:9.0 AS runtime
WORKDIR /app

# Copy published output from build
COPY --from=build /app/publish .

# ** HARDENING CHANGE START **
# Critical Fix: Switch to the built-in non-root user 'appuser'
USER appuser
# ** HARDENING CHANGE END **

# Expose ASP.NET port
EXPOSE 5001

# Environment setup (Production)
ENV ASPNETCORE_URLS=https://+:5001
ENV ASPNETCORE_ENVIRONMENT=Production

ENTRYPOINT ["dotnet", "Rise.Server.dll"]