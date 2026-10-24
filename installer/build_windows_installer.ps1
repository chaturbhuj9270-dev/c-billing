# Builds the Windows release and packages it as C-Billing-Setup.exe.
# Run this on Windows from any directory:
#   powershell -ExecutionPolicy Bypass -File installer\build_windows_installer.ps1

$ErrorActionPreference = 'Stop'

if ($env:OS -ne 'Windows_NT') {
  Write-Error 'C-Billing-Setup.exe can only be built on Windows. Flutter does not cross-compile Windows apps.'
}

$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

flutter pub get
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

flutter build windows --release
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$release = Join-Path $root 'build\windows\x64\runner\Release'
$exe = Join-Path $release 'c_billing.exe'
if (-not (Test-Path $exe)) {
  Write-Error "Release build did not produce $exe"
}

# Ship the Visual C++ runtime beside the app so login and startup do not
# depend on a machine-wide redistributable install.
$crtDll = $null
$vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
if (Test-Path $vswhere) {
  $crtDll = & $vswhere -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -find 'VC\Redist\MSVC\*\x64\Microsoft.VC*.CRT\vcruntime140.dll' |
    Select-Object -First 1
  if ($crtDll) {
    $crtDll = Get-Item $crtDll
  }
}

if ($null -ne $crtDll) {
  foreach ($name in @('vcruntime140.dll', 'vcruntime140_1.dll', 'msvcp140.dll')) {
    $source = Join-Path $crtDll.DirectoryName $name
    if (Test-Path $source) {
      Copy-Item $source -Destination $release -Force
    }
  }
}

$redistDir = Join-Path $root 'build\windows\installer\redist'
New-Item -ItemType Directory -Force -Path $redistDir | Out-Null
$redist = Join-Path $redistDir 'vc_redist.x64.exe'
if (-not (Test-Path $redist)) {
  Invoke-WebRequest -Uri 'https://aka.ms/vs/17/release/vc_redist.x64.exe' -OutFile $redist
}

$iscc = @(
  "${env:ProgramFiles(x86)}\Inno Setup 6\ISCC.exe",
  "$env:ProgramFiles\Inno Setup 6\ISCC.exe"
) | Where-Object { Test-Path $_ } | Select-Object -First 1

if (-not $iscc) {
  Write-Error 'Inno Setup 6 is not installed. Install it from https://jrsoftware.org/isdl.php and run this script again.'
}

& $iscc (Join-Path $PSScriptRoot 'c_billing_setup.iss')
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$setup = Join-Path $root 'build\windows\installer\C-Billing-Setup.exe'
if (-not (Test-Path $setup)) {
  Write-Error "Installer was not created at $setup"
}

Write-Host "Installer ready: $setup"
