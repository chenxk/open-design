Param(
    [Parameter(Mandatory = $true)]
    [string]$DockerHubUser = "8216179140",

    [string]$ImageName = "open-design",

    [string]$Version = "v1.0.0",

    [switch]$MultiArch = $false,

    [string]$Platforms = "linux/amd64,linux/arm64",

    [string]$Dockerfile = "Dockerfile",

    [string]$BuildContext = ".",

    [string]$BuildName = "open-design"
)

$ErrorActionPreference = "Stop"

$repo = "$DockerHubUser/$ImageName"

Write-Host "==> Repo: $repo"
Write-Host "==> Version: $Version"
Write-Host "==> Dockerfile: $Dockerfile"

if (-not (Test-Path $Dockerfile)) {
    throw "Dockerfile not found: $Dockerfile"
}

docker --version | Out-Null

Write-Host "==> Checking Docker login status..."
try {
    docker info | Out-Null
} catch {
    throw "Docker daemon is not available. Please start Docker Desktop first."
}

if ($MultiArch) {
    Write-Host "==> Building and pushing multi-arch image..."
    docker buildx inspect multi-builder *> $null
    if ($LASTEXITCODE -ne 0) {
        docker buildx create --name multi-builder --use | Out-Null
    } else {
        docker buildx use multi-builder | Out-Null
    }
    docker buildx inspect --bootstrap | Out-Null

    $buildArgs = @()
    if ($BuildName) {
        $buildArgs += "--build-arg"
        $buildArgs += "name=$BuildName"
    }

    docker buildx build `
        --platform $Platforms `
        -f $Dockerfile `
        $buildArgs `
        -t "$repo`:$Version" `
        -t "$repo`:latest" `
        --push $BuildContext
} else {
    Write-Host "==> Building local image..."
    $buildArgs = @()
    if ($BuildName) {
        $buildArgs += "--build-arg"
        $buildArgs += "name=$BuildName"
    }

    docker build `
        -f $Dockerfile `
        $buildArgs `
        -t "$repo`:$Version" `
        -t "$repo`:latest" `
        $BuildContext

    Write-Host "==> Pushing tags to Docker Hub..."
    docker push "$repo`:$Version"
    docker push "$repo`:latest"
}

Write-Host "==> Done."
Write-Host "Pushed: $repo`:$Version and $repo`:latest"
