# ========================================
# BUILD STAGE
# ========================================
# FIX: Switch to the Alpine SDK variant for a smaller attack surface and to fix zlib1g vulnerability
FROM mcr.microsoft.com/dotnet/sdk:9.0-alpine AS build
WORKDIR /src

# Alpine Fix: Install glibc compatibility layer (libc6-compat) and git for .NET operations
RUN apk add --no-cache git libc6-compat

# Copy solution and project files
COPY Rise.sln ./
COPY src/ src/
COPY tests/ tests/

# Restore dependencies
RUN dotnet restore Rise.sln

# Build and publish app
RUN dotnet build Rise.sln -c Release --no-restore
RUN dotnet publish src/Rise.Server/Rise.Server.csproj -c Release -o /app/publish /p:UseAppHost=false

# ========================================
# RUNTIME STAGE
# ========================================
# FIX: Switch to the Alpine ASPNET runtime to match the SDK and maintain a minimal, secure base
FROM mcr.microsoft.com/dotnet/aspnet:9.0-alpine AS runtime
WORKDIR /app

# Copy published output from build
COPY --from=build /app/publish .

# ** HARDENING CHANGE: NON-ROOT USER **

# Alpine Fix: Create system user 'appuser'. The '-D' flag is equivalent to '--system'.
RUN adduser -D -u 1000 appuser

# Set ownership of the app directory to the new user.
RUN chown -R appuser:appuser /app

# Critical Fix: Switch to the unprivileged user 'appuser'
USER appuser
# ** HARDENING CHANGE END **

# Expose ASP.NET port
EXPOSE 5001

# Environment setup (Production)
ENV ASPNETCORE_URLS=https://+:5001
ENV ASPNETCORE_ENVIRONMENT=Production

ENTRYPOINT ["dotnet", "Rise.Server.dll"]