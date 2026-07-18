$ErrorActionPreference = "Stop"

$ApiBaseUrl = if ($env:API_BASE_URL) { $env:API_BASE_URL } else { "http://127.0.0.1:8000" }
$Iterations = if ($env:ITERATIONS) { [int]$env:ITERATIONS } else { 40 }

$urls = @(
  "$ApiBaseUrl/api/health",
  "$ApiBaseUrl/api/ready",
  "$ApiBaseUrl/api/campaigns"
)

$ok = 0
$fail = 0
$times = New-Object System.Collections.Generic.List[Double]

Write-Host "[load-smoke] base: $ApiBaseUrl"
Write-Host "[load-smoke] iterations: $Iterations"

for ($i = 1; $i -le $Iterations; $i++) {
  foreach ($url in $urls) {
    try {
      $sw = [System.Diagnostics.Stopwatch]::StartNew()
      $response = Invoke-WebRequest -Uri $url -Method GET -UseBasicParsing
      $sw.Stop()
      $times.Add($sw.Elapsed.TotalSeconds)
      if ($response.StatusCode -ge 200 -and $response.StatusCode -lt 300) {
        $ok++
      } else {
        $fail++
        Write-Host "[load-smoke][warn] $url -> HTTP $($response.StatusCode)"
      }
    } catch {
      $fail++
      $times.Add(9.999)
      Write-Host "[load-smoke][warn] $url -> failed: $($_.Exception.Message)"
    }
  }
}

if ($times.Count -eq 0) {
  Write-Host "[load-smoke] no samples collected"
  exit 1
}

$sorted = $times | Sort-Object
$avg = ($times | Measure-Object -Average).Average
$p95Index = [Math]::Ceiling($sorted.Count * 0.95) - 1
if ($p95Index -lt 0) { $p95Index = 0 }
$p95 = $sorted[$p95Index]

Write-Host ("[load-smoke] success={0} failure={1} count={2} avg={3:n3}s p95={4:n3}s" -f $ok, $fail, $times.Count, $avg, $p95)
if ($fail -gt 0) {
  exit 1
}
