module.exports = {
  apps: [
    {
      name: "frontend",
      script: "index.js",
      cwd: "./frontend",
      instances: 1,
      env: {
        NODE_ENV: "production",
        PORT: 3000
      }
    },
    {
      name: "backend",
      script: "dotnet",
      args: "backend.dll",
      cwd: "./backend",
      instances: 1,
      env: {
        ASPNETCORE_URLS: "http://localhost:5000",
        ASPNETCORE_ENVIRONMENT: "Production"
      }
    }
  ]
};
