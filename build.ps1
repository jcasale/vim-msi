[CmdletBinding()]
param
(
    [Parameter(Mandatory=$true,Position=0)]
    [uri]
    $Uri,
    [Parameter(Mandatory=$true,Position=1)]
    [version]
    $Version
)

Set-StrictMode -Version Latest

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

Add-Type -Assembly 'System.IO.Compression.FileSystem' -ErrorAction Stop

# Check requirements.
[void](Get-Command 'git.exe' -ErrorAction Stop)
[void](Get-Command 'heat.exe' -ErrorAction Stop)
[void](Get-Command 'candle.exe' -ErrorAction Stop)
[void](Get-Command 'light.exe' -ErrorAction Stop)

# Clean build environment.
& git.exe 'clean' '-xfd' '--exclude=.vscode/'

if ($LASTEXITCODE -ne 0)
{
   throw 'Git clean failed with exit code {0}.' -f $LASTEXITCODE
}

# Prepare build environment.
$tmp = New-Item -Path tmp -ItemType Directory -ErrorAction Stop

$fileNameArchive = split-path -leaf $Uri.AbsolutePath
$pathArchive = Join-Path $tmp $fileNameArchive
$pathProductSource = Join-Path $tmp '\vim\vim82'
$pathSrc = Join-Path $PSScriptRoot 'src'
$pathWixProductSource = Join-Path $pathSrc 'Product.wxs'
$pathWixProductObj = Join-Path $tmp 'Product.wixobj'
$pathWixFragmentSource = Join-Path $tmp 'Fragment.wxs'
$pathWixFragmentObj = Join-Path $tmp 'Fragment.wixobj'
$pathMsi = Join-Path $tmp 'vim.msi'

# Download release archive.
$webClient = [Net.WebClient]::new()
try
{
    $webClient.DownloadFile($Uri, $pathArchive)
}
catch
{
    throw
}
finally
{
    $webClient.Dispose()
}

# Unpack archive.
try
{
    [System.IO.Compression.ZipFile]::ExtractToDirectory($pathArchive, $tmp.FullName)
}
catch
{
    throw
}

# Remove archive.
Remove-Item -Path $pathArchive -ErrorAction Stop

# Remove unnecessary files from the package.
Push-Location $pathProductSource -ErrorAction Stop
try
{
    Remove-Item 'GvimExt32\GvimExt.reg' -Force -ErrorAction Stop
    Remove-Item 'GvimExt32\README.txt' -Force -ErrorAction Stop
    Remove-Item 'GvimExt64\GvimExt.reg' -Force -ErrorAction Stop
    Remove-Item 'GvimExt64\README.txt' -Force -ErrorAction Stop
    Remove-Item 'install.exe' -Force -ErrorAction Stop
    Remove-Item 'uninstall.exe' -Force -ErrorAction Stop
    Remove-Item '*.desktop' -Force -ErrorAction Stop
}
finally
{
    Pop-Location
}

# Harvest.
$heatArguments =
  'dir',
  $pathProductSource,
  '-cg',
  'ProductComponents',
  '-g1',
  '-ag',
  '-ke',
  '-srd',
  '-dr',
  'INSTALLDIR',
  '-sfrag',
  '-sreg',
  '-var',
  'var.VimSource',
  '-o',
  $pathWixFragmentSource
& heat.exe $heatArguments

if ($LASTEXITCODE -ne 0)
{
    throw ('Harvest failed with exit code {0}.' -f $LASTEXITCODE)
}

# Compile.
$candleArguments =
  ('-dVimSource={0}' -f $pathProductSource),
  ('-dSrcDirectory={0}' -f $pathSrc),
  ('-dProductVersion={0}' -f $Version),
  '-out',
  ($tmp.FullName.TrimEnd('\') + '\'),
  '-arch',
  'x64',
  '-ext',
  'WixUtilExtension.dll',
  '-ext',
  'WixUIExtension.dll',
  $pathWixFragmentSource,
  $pathWixProductSource
& candle.exe $candleArguments

if ($LASTEXITCODE -ne 0)
{
    throw ('Compile failed with exit code {0}.' -f $LASTEXITCODE)
}

# Link.
$lightArguments =
  '-out',
  $pathMsi,
  '-ext',
  'WixUtilExtension.dll',
  '-ext',
  'WixUIExtension.dll',
  '-spdb',
  $pathWixFragmentObj,
  $pathWixProductObj
& light.exe $lightArguments

if ($LASTEXITCODE -ne 0)
{
    throw ('Link failed with exit code {0}.' -f $LASTEXITCODE)
}