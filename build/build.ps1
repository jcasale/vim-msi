[cmdletbinding()]
param
(
    [Parameter(Mandatory=$true,Position=0)]
    [int]
    $Major,
    [Parameter(Mandatory=$true,Position=1)]
    [int]
    $Minor,
    [Parameter(Mandatory=$true,Position=2)]
    [int]
    $Patch
)

Set-StrictMode -Version Latest

# Check requirements.
[void](Get-Command 'git.exe' -ErrorAction Stop)
[void](Get-Command 'heat.exe' -ErrorAction Stop)
[void](Get-Command 'candle.exe' -ErrorAction Stop)
[void](Get-Command 'light.exe' -ErrorAction Stop)

Add-Type -assembly 'System.IO.Compression.FileSystem' -ErrorAction Stop

$url = 'https://github.com/vim/vim-win32-installer/releases/download/v{0}.{1}.{2:D4}/gvim_{0}.{1}.{2:D4}_x64.zip' -f $Major, $Minor, $Patch
$currentDirectory = (Resolve-Path .).Path
$srcDirectory = Join-Path $currentDirectory 'src'
$tmpDirectory = Join-Path $currentDirectory 'tmp'
$archiveFile = Join-Path $tmpDirectory (split-path -leaf $url)

# Prepare.
& git.exe "clean" "-xfd"

if ($LASTEXITCODE -ne 0)
{
    throw ('Git clean failed with exit code {0}.' -f $LASTEXITCODE)
}

[void](New-Item -Path $tmpDirectory -ItemType Directory -ErrorAction Stop)

try
{
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    (New-Object System.Net.WebClient).DownloadFile($url, $archiveFile)
    [System.IO.Compression.ZipFile]::ExtractToDirectory($archiveFile, $tmpDirectory)
}
catch
{
    throw $_
}

Remove-Item (Join-Path $tmpDirectory 'vim\vim81\GvimExt32\GvimExt.reg') -Force -ErrorAction Stop
Remove-Item (Join-Path $tmpDirectory 'vim\vim81\GvimExt32\README.txt') -Force -ErrorAction Stop
Remove-Item (Join-Path $tmpDirectory 'vim\vim81\GvimExt64\GvimExt.reg') -Force -ErrorAction Stop
Remove-Item (Join-Path $tmpDirectory 'vim\vim81\GvimExt64\README.txt') -Force -ErrorAction Stop
Remove-Item (Join-Path $tmpDirectory 'vim\vim81\install.exe') -Force -ErrorAction Stop
Remove-Item (Join-Path $tmpDirectory 'vim\vim81\uninstal.exe') -Force -ErrorAction Stop
Remove-Item (Join-Path $tmpDirectory 'vim\vim81\*.desktop') -Force -ErrorAction Stop

# Harvest.
$heatArguments =
  'dir',
  (Join-Path $tmpDirectory '\vim\vim81'),
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
  (Join-Path $tmpDirectory 'Fragment.wxs')
& heat.exe $heatArguments

if ($LASTEXITCODE -ne 0)
{
    throw ('Harvest failed with exit code {0}.' -f $LASTEXITCODE)
}

# Compile.
$candleArguments =
  ('-dVimSource={0}' -f (Join-Path $tmpDirectory '\vim\vim81')),
  ('-dSrcDirectory={0}' -f $srcDirectory),
  ('-dProductVersion={0}.{1}.{2}.0' -f $Major, $Minor, $Patch), # Don't pad MSI version.
  '-out',
  ($tmpDirectory.TrimEnd('\') + '\'),
  '-arch',
  'x64',
  '-ext',
  'WixUtilExtension.dll',
  '-ext',
  'WixUIExtension.dll',
  (Join-Path $tmpDirectory 'Fragment.wxs'),
  (Join-Path $srcDirectory 'Product.wxs')
& candle.exe $candleArguments

if ($LASTEXITCODE -ne 0)
{
    throw ('Compile failed with exit code {0}.' -f $LASTEXITCODE)
}

# Link.
$lightArguments =
  '-out',
  (Join-Path $tmpDirectory 'vim.msi'),
  '-ext',
  'WixUtilExtension.dll',
  '-ext',
  'WixUIExtension.dll',
  '-spdb',
  (Join-Path $tmpDirectory 'Fragment.wixobj'),
  (Join-Path $tmpDirectory 'Product.wixobj')
& light.exe $lightArguments

if ($LASTEXITCODE -ne 0)
{
    throw ('Link failed with exit code {0}.' -f $LASTEXITCODE)
}