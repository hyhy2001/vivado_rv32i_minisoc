param(
  [string]$Prefix = "riscv32-unknown-elf",
  [string]$OutElf = "firmware.elf",
  [string]$GccExe = "",
  [string]$ObjdumpExe = ""
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

$gccName = "$Prefix-gcc"
$objdumpName = "$Prefix-objdump"

$derivedObjdump = ""
if ($GccExe -and -not $ObjdumpExe) {
  $gccDir = Split-Path -Parent $GccExe
  $derivedObjdump = Join-Path $gccDir "$objdumpName.exe"
}

$gccCandidates = @(
  $GccExe,
  $gccName
)
$objdumpCandidates = @(
  $ObjdumpExe,
  $derivedObjdump,
  $objdumpName
)

$gcc = Resolve-Exe -Name $gccName -Candidates $gccCandidates
$objdump = Resolve-Exe -Name $objdumpName -Candidates $objdumpCandidates

if (-not $gcc -or -not $objdump) {
  throw "RISC-V toolchain not found. Add it to PATH or pass -GccExe/-ObjdumpExe (e.g. -GccExe '<toolchain_bin>\\riscv-none-elf-gcc.exe')."
}

$root = $PSScriptRoot

$linkerScript = Join-Path $root "link.ld"
$startS = Join-Path $root "start.S"
$mainC = Join-Path $root "main.c"
$outElfPath = Join-Path $root $OutElf

$gccArgs = @(
  "-march=rv32i",
  "-mabi=ilp32",
  "-O2",
  "-ffreestanding",
  "-fno-builtin",
  "-nostdlib",
  "-Wl,-T,$linkerScript",
  "-Wl,--gc-sections",
  $startS,
  $mainC,
  "-o",
  $outElfPath
)

& $gcc @gccArgs
if ($LASTEXITCODE -ne 0) { throw "$gcc failed with exit code $LASTEXITCODE" }

$disasmPath = Join-Path $root "firmware.disasm.txt"
& $objdump -d $outElfPath | Out-File -Encoding utf8 $disasmPath

$elf2hex = Join-Path $root "elf2hex.py"
$romHex = Join-Path $root "rom.hex"
python $elf2hex $outElfPath --out $romHex

Write-Host "OK: $outElfPath -> $romHex"
