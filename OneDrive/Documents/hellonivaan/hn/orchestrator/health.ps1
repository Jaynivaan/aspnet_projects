#health.ps1 - Orchestrator MVP-1 health check
$root = Split-Path -Parent $myInvocation.MyCommand.Path
Set-Location $root

$now = Get-Date -Format "yyyy-MM-ddTHH:mm:ssK"
$indexPath = "index.json"
$chDir = "chambers"

# 1) Load index.json
try { $index = Get-Content $indexPath -Raw | ConvertFrom-Json }
catch { Write-Error "index.json invalid or missing"; exit 1 }

# 2) Enumerate chamber files
$expected = @("gateway","challenge", "presence", "auth","content", "session")
$report = @()

foreach($name in $expected) {
	$file = Join-Path $chDir "$name.json"
	$exists = Test-Path $file
	$status = if ($exists){"present"} else {"missing"}
	$report += [pscustomobject]@{ chamber=$name; file=$file; status=$status }
	if (-not $exists) {$index.chambers.$name.status = "missing_file" }
}
	

# 3) Update Last_update in index.json
index.last_update = $now
($index | ConvertTo-Json -Depth 10) | Set-Content $indexPath -Encoding UTF-8


# 4) Write a status report file
$repDir = "reports"; if (!(Test-Path $repDir)){New-Item -ItemType Directory $repDir | Out-Null }
$repPath = Join-Path $repDir ("status-" + (Get-Date -Format "yyyyMMdd-HHmmss") + ".json")
($report | ConvertTo-Json -Depth 10) | Set-Content $repPath -Encoding UTF-8


# 5) Append progress.log
$line = "[{0}] Health check : {1} present, {2}missing" -f $now, ($report | Where-Object {$_.status -eq "present"}).Count, ($report | Where-Object {$_.status -ne "present"}).Count
Add-Content -Path "progress.log" -Value $line

# 6) Console Summary.
$report | Format-Table -AutoSize
Write-Host "`nIndex updated. Report -> $repPath"