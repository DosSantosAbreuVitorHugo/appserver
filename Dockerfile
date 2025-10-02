# Stage 1: Build
FROM mcr.microsoft.com/dotnet/sdk:6.0 AS build
WORKDIR /app

# Copy only the project file first for caching
COPY TestMariaDBApp/TestMariaDBApp.csproj ./TestMariaDBApp/
RUN dotnet restore TestMariaDBApp/TestMariaDBApp.csproj

# Copy the rest of the app
COPY TestMariaDBApp/ ./TestMariaDBApp/

# Build & publish
RUN dotnet publish TestMariaDBApp/TestMariaDBApp.csproj -c Release -o out

# Stage 2: Runtime
FROM mcr.microsoft.com/dotnet/runtime:6.0
WORKDIR /app
COPY --from=build /app/out .
ENTRYPOINT ["dotnet", "TestMariaDBApp.dll"]
