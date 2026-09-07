$ErrorActionPreference = 'Stop'

function EnvOrDefault([string]$Name, [string]$Default) {
  $value = [Environment]::GetEnvironmentVariable($Name)
  if ([string]::IsNullOrWhiteSpace($value)) { return $Default }
  return $value
}

$Port = EnvOrDefault 'PORT' '8080'
$HostAddress = EnvOrDefault 'HOST' '127.0.0.1'
$ApiKey = EnvOrDefault 'API_KEY' ''
$ModelAlias = EnvOrDefault 'MODEL_ALIAS' 'local-model'
$ModelPath = EnvOrDefault 'MODEL_PATH' '.\models\model.gguf'
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
$CorsOrigins = EnvOrDefault 'CORS_ORIGINS' '*'
$Server = EnvOrDefault 'LLAMA_SERVER_BIN' 'llama-server'

if (-not (Test-Path -LiteralPath $ModelPath -PathType Leaf)) {
  if ($DownloadModel -ne 'true' -or [string]::IsNullOrWhiteSpace($ModelRepo) -or [string]::IsNullOrWhiteSpace($ModelFile)) {
    throw "Model not found at '$ModelPath'. Set MODEL_REPO and MODEL_FILE, or provide MODEL_PATH."
  }
  New-Item -ItemType Directory -Force -Path $ModelDir | Out-Null
  $url = "https://huggingface.co/$ModelRepo/resolve/$ModelRevision/$ModelFile?download=true"
  $target = Join-Path $ModelDir $ModelFile
  $headers = @{}
  $hfToken = [Environment]::GetEnvironmentVariable('HF_TOKEN')
  if (-not [string]::IsNullOrWhiteSpace($hfToken)) { $headers['Authorization'] = "Bearer $hfToken" }
  Invoke-WebRequest -Uri $url -Headers $headers -OutFile "$target.part"
  Move-Item -Force "$target.part" $target
  $ModelPath = $target
}

$args = @(
  '--model', $ModelPath,
  '--alias', $ModelAlias,
  '--host', $HostAddress,
  '--port', $Port,
  '--threads', $CpuThreads,
  '--threads-batch', $CpuThreadsBatch,
  '--ctx-size', $ContextSize,
  '--batch-size', $BatchSize,
  '--ubatch-size', $UbatchSize,
  '--parallel', $Parallel,
  '--no-webui',
  '--log-verbosity', $LogVerbosity,
  '--cors-origins', $CorsOrigins
)
if (-not [string]::IsNullOrWhiteSpace($ApiKey)) { $args += @('--api-key', $ApiKey) }

& $Server @args
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
