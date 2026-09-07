$ErrorActionPreference = 'Stop'

function EnvOrDefault([string]$Name, [string]$Default) {
  $value = [Environment]::GetEnvironmentVariable($Name)
  if ([string]::IsNullOrWhiteSpace($value)) { return $Default }
  return $value
}

$Port = EnvOrDefault 'PORT' '8080'
$HostAddress = EnvOrDefault 'HOST' '127.0.0.1'
$ApiKey = EnvOrDefault 'API_KEY' ''
$ModelAlias = EnvOrDefault 'MODEL_ALIAS' ''
$ModelPath = EnvOrDefault 'MODEL_PATH' ''
$ModelRepo = EnvOrDefault 'MODEL_REPO' ''
$ModelFile = EnvOrDefault 'MODEL_FILE' ''
$ModelRevision = EnvOrDefault 'MODEL_REVISION' 'main'
$ModelDir = EnvOrDefault 'MODEL_DIR' '.\models'
$DownloadModel = EnvOrDefault 'DOWNLOAD_MODEL' 'true'
$CpuThreads = EnvOrDefault 'CPU_THREADS' '2'
$CpuThreadsBatch = EnvOrDefault 'CPU_THREADS_BATCH' $CpuThreads
$ContextSize = EnvOrDefault 'CONTEXT_SIZE' '2048'
$BatchSize = EnvOrDefault 'BATCH_SIZE' '256'
$UbatchSize = EnvOrDefault 'UBATCH_SIZE' '128'
$Parallel = EnvOrDefault 'PARALLEL' '1'
$LogVerbosity = EnvOrDefault 'LOG_VERBOSITY' '3'
$CorsOrigins = EnvOrDefault 'CORS_ORIGINS' ''
$Server = EnvOrDefault 'LLAMA_SERVER_BIN' 'llama-server'

if (-not [string]::IsNullOrWhiteSpace($ModelPath) -and (Test-Path -LiteralPath $ModelPath -PathType Leaf)) {
  Write-Host "Using model from MODEL_PATH: $ModelPath"
}
elseif ($DownloadModel -eq 'true') {
  if ([string]::IsNullOrWhiteSpace($ModelRepo) -or [string]::IsNullOrWhiteSpace($ModelFile)) {
    throw 'No model configured. Set MODEL_REPO and MODEL_FILE to the exact model to download, or set MODEL_PATH to an existing GGUF file.'
  }

  if ([string]::IsNullOrWhiteSpace($ModelPath)) {
    $ModelPath = Join-Path $ModelDir $ModelFile
  }

  New-Item -ItemType Directory -Force -Path (Split-Path -Parent $ModelPath) | Out-Null
  $url = "https://huggingface.co/$ModelRepo/resolve/$ModelRevision/$ModelFile?download=true"
  $headers = @{}
  $hfToken = [Environment]::GetEnvironmentVariable('HF_TOKEN')
  if (-not [string]::IsNullOrWhiteSpace($hfToken)) { $headers['Authorization'] = "Bearer $hfToken" }

  $part = "$ModelPath.part"
  Invoke-WebRequest -Uri $url -Headers $headers -OutFile $part
  Move-Item -Force $part $ModelPath
}
else {
  throw 'No usable model configured. Set MODEL_PATH to an existing GGUF file or set MODEL_REPO and MODEL_FILE with DOWNLOAD_MODEL=true.'
}

if (-not (Test-Path -LiteralPath $ModelPath -PathType Leaf)) {
  throw "Model file not found at '$ModelPath'."
}

$args = @(
  '--model', $ModelPath,
  '--host', $HostAddress,
  '--port', $Port,
  '--threads', $CpuThreads,
  '--threads-batch', $CpuThreadsBatch,
  '--ctx-size', $ContextSize,
  '--batch-size', $BatchSize,
  '--ubatch-size', $UbatchSize,
  '--parallel', $Parallel,
  '--no-webui',
  '--log-verbosity', $LogVerbosity
)

if (-not [string]::IsNullOrWhiteSpace($ModelAlias)) { $args += @('--alias', $ModelAlias) }
if (-not [string]::IsNullOrWhiteSpace($CorsOrigins)) { $args += @('--cors-origins', $CorsOrigins) }
if (-not [string]::IsNullOrWhiteSpace($ApiKey)) { $args += @('--api-key', $ApiKey) }

& $Server @args
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
