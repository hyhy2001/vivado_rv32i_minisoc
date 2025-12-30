param(
  [string]$Top = "tb_minisoc",
  [string]$Iverilog = "",
  [string]$Vvp = ""
)

$ErrorActionPreference = "Stop"

function Resolve-Exe {
  param(
    [Parameter(Mandatory = $true)][string]$Name,
    [string[]]$Candidates = @()
  )
  if ($Candidates) {
    foreach ($c in $Candidates) {
      if ($c -and (Test-Path $c)) { return $c }
    }
  }
  $cmd = Get-Command $Name -ErrorAction SilentlyContinue
  if ($cmd) { return $cmd.Path }
  return $null
}

$iverilogCandidates = @(
  $Iverilog,
  "iverilog"
)
$vvpCandidates = @(
  $Vvp,
  "vvp"
)

$iverilogExe = Resolve-Exe -Name "iverilog" -Candidates $iverilogCandidates
$vvpExe = Resolve-Exe -Name "vvp" -Candidates $vvpCandidates

if (-not $iverilogExe -or -not $vvpExe) {
  throw "iverilog/vvp not found. Either add them to PATH, or run: pwsh rv32i_minisoc\\sim\\run_iverilog.ps1 -Iverilog <path\\iverilog.exe> -Vvp <path\\vvp.exe>"
}

Push-Location $PSScriptRoot
try {
  $romHex = Resolve-Path "..\\software\\rom.hex"
  $rtl = @(
    "..\\rtl\\rv32i_core.v",
    "..\\rtl\\simple_rom.v",
    "..\\rtl\\simple_ram.v",
    "..\\rtl\\minisoc_top.v",
    ".\\tb_minisoc.v"
  )

  & $iverilogExe -g2012 -Wall -o .\\sim.out -s $Top @rtl
  if ($LASTEXITCODE -ne 0) { throw "iverilog failed with exit code $LASTEXITCODE" }

  & $vvpExe .\\sim.out "+romhex=$romHex"
  if ($LASTEXITCODE -ne 0) { throw "vvp failed with exit code $LASTEXITCODE" }
} finally {
  Pop-Location
}
