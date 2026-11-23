# Windows installer for claude-kit. Re-runnable.
#   powershell -ExecutionPolicy Bypass -File install.ps1          copy files
#   powershell -ExecutionPolicy Bypass -File install.ps1 -Link    skills become junctions, so `git pull` updates them
param([switch]$Link)
$ErrorActionPreference = 'Stop'

$Dir  = $PSScriptRoot
$Dest = if ($env:CLAUDE_HOME) { $env:CLAUDE_HOME } else { Join-Path $HOME '.claude' }
foreach ($d in 'skills','agents','hooks') { New-Item -ItemType Directory -Force -Path (Join-Path $Dest $d) | Out-Null }
$managed = Test-Path (Join-Path $Dest '.kit-managed')

function Remove-Target($path) {
  $item = Get-Item -LiteralPath $path -Force -ErrorAction SilentlyContinue
  if (-not $item) { return }
  if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) { $item.Delete(); return }  # junction: remove link only
  if ($managed) { Remove-Item -LiteralPath $path -Recurse -Force }
  else { Rename-Item -LiteralPath $path -NewName ("{0}.bak.{1}" -f $item.Name, [DateTimeOffset]::Now.ToUnixTimeSeconds()) }
}

# Skills
foreach ($s in Get-ChildItem -Directory (Join-Path $Dir 'skills')) {
  $target = Join-Path (Join-Path $Dest 'skills') $s.Name
  Remove-Target $target
  if ($Link) { New-Item -ItemType Junction -Path $target -Target $s.FullName | Out-Null }
  else { Copy-Item -Recurse -LiteralPath $s.FullName -Destination $target }
}
# Agent + hook (always copied; re-run after git pull)
Copy-Item -Force (Join-Path $Dir 'agents\verifier.md') (Join-Path $Dest 'agents\verifier.md')
$hook = Join-Path $Dest 'hooks\require-verify.sh'
Copy-Item -Force (Join-Path $Dir 'hooks\require-verify.sh') $hook
Set-Content -LiteralPath (Join-Path $Dest '.kit-managed') -Value 'ai-workflow-kit'

# Find Git Bash (Claude Code on Windows needs Git for Windows anyway). Avoid WSL's bash.exe.
$bash = $null
$git = Get-Command git -ErrorAction SilentlyContinue
if ($git) {
  $gitRoot = Split-Path (Split-Path $git.Source -Parent) -Parent
  $cand = Join-Path $gitRoot 'bin\bash.exe'
  if (Test-Path $cand) { $bash = $cand }
}
if (-not $bash -and (Test-Path 'C:\Program Files\Git\bin\bash.exe')) { $bash = 'C:\Program Files\Git\bin\bash.exe' }

$utf8 = New-Object System.Text.UTF8Encoding($false)   # no BOM

if ($bash) {
  $cmd = '"{0}" "{1}"' -f ($bash -replace '\\','/'), ($hook -replace '\\','/')
  $settingsPath = Join-Path $Dest 'settings.json'
  $settings = if ((Test-Path $settingsPath) -and (Get-Item $settingsPath).Length -gt 0) {
    Get-Content -Raw $settingsPath | ConvertFrom-Json
  } else { New-Object PSObject }
  if (-not $settings.PSObject.Properties['hooks']) { $settings | Add-Member -NotePropertyName hooks -NotePropertyValue (New-Object PSObject) }
  if (-not $settings.hooks.PSObject.Properties['Stop']) { $settings.hooks | Add-Member -NotePropertyName Stop -NotePropertyValue @() }
  $stop = @($settings.hooks.Stop | Where-Object { $_ })
  # drop any older copy of our hook, then add the current one
  $stop = @($stop | Where-Object { -not (@($_.hooks) | Where-Object { $_.command -like '*require-verify.sh*' }) })
  $stop += [PSCustomObject]@{ hooks = @([PSCustomObject]@{ type = 'command'; command = $cmd }) }
  $settings.hooks.Stop = $stop
  [IO.File]::WriteAllText($settingsPath, ($settings | ConvertTo-Json -Depth 32), $utf8)
} else {
  Write-Warning 'Git Bash not found: skipped the stop hook. Install Git for Windows and re-run.'
}

# CLAUDE.md rules between markers
$md = Join-Path $Dest 'CLAUDE.md'
$text = if (Test-Path $md) { [IO.File]::ReadAllText($md) } else { '' }
$snip = ([IO.File]::ReadAllText((Join-Path $Dir 'CLAUDE.md.snippet'))).Trim()
$block = "<!-- ai-workflow-kit:start -->`n$snip`n<!-- ai-workflow-kit:end -->"
$pattern = '(?s)<!-- ai-workflow-kit:start -->.*?<!-- ai-workflow-kit:end -->'
if ($text -match $pattern) { $text = [regex]::Replace($text, $pattern, { param($m) $block }) }
else { $text = ($text.TrimEnd() + "`n`n" + $block + "`n").TrimStart() }
[IO.File]::WriteAllText($md, $text, $utf8)

$n = (Get-ChildItem -Directory (Join-Path $Dir 'skills')).Count
Write-Host "claude-kit: $n skills, verifier agent, stop hook and CLAUDE.md rules installed in $Dest"
