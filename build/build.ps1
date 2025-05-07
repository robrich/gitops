
$ErrorActionPreference = "Stop"

Set-Location -Path $PSScriptRoot
cd ..

# commented out for demo:
#git reset --hard

$gitHash = git rev-parse HEAD
$gitBranch = git rev-parse --abbrev-ref HEAD

echo "Git Hash: $gitHash, Git Branch: $gitBranch"

$gitData = [PSCustomObject]@{
  hash = $gitHash
  branch = $gitBranch
}
$gitJson = $gitData | ConvertTo-Json -Depth 3

cd apps/backend
$gitJson | Out-File -FilePath "version.json" -Encoding utf8
dotnet build -c Release -o ../../dist/backend

cd ../frontend
$gitJson | Out-File -FilePath "version.json" -Encoding utf8
npm install
robocopy /mir . ../../dist/frontend /NFL /NDL /NP
cd ../..

Copy-Item -Path "build/ecosystem.config.js" -Destination "dist/ecosystem.config.js" -Force

if (-Not (Test-Path "repo")) {
    New-Item -ItemType Directory -Path "repo" | Out-Null
}
cd repo
git clone ../../deploy .
git show-ref --verify --quiet refs/heads/$gitBranch && git checkout $gitBranch || git checkout -b $gitBranch
robocopy /mir ../dist . /XD ".git" /NFL /NDL /NP
git add .
git commit -m "$gitHash-$gitBranch"
git push origin $gitBranch

Set-Location -Path $PSScriptRoot
cd ..
