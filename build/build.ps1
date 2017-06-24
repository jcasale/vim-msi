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
$resourceDirectory = Join-Path $currentDirectory 'resource'
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
    (New-Object System.Net.WebClient).DownloadFile($url, $archiveFile)
    [System.IO.Compression.ZipFile]::ExtractToDirectory($archiveFile, $tmpDirectory)
}
catch
{
    throw $_
}

Move-Item (Join-Path $tmpDirectory 'vim\vim80\GvimExt\gvimext64.dll') (Join-Path $tmpDirectory 'vim\vim80\GvimExt\gvimext.dll') -Force -ErrorAction Stop
Remove-Item (Join-Path $tmpDirectory 'vim\vim80\install.exe') -Force -ErrorAction Stop
Remove-Item (Join-Path $tmpDirectory 'vim\vim80\uninstal.exe') -Force -ErrorAction Stop
Remove-Item (Join-Path $tmpDirectory 'vim\vim80\*.desktop') -Force -ErrorAction Stop

# Harvest.
$heatArguments =
  'dir',
  (Join-Path $tmpDirectory '\vim\vim80'),
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
  (Join-Path $currentDirectory 'src\Fragment.wxs')
& heat.exe $heatArguments

if ($LASTEXITCODE -ne 0)
{
    throw ('Harvest failed with exit code {0}.' -f $LASTEXITCODE)
}

# Compile.
$candleArguments =
  ('-dVimSource={0}' -f (Join-Path $tmpDirectory '\vim\vim80')),
  ('-dResourceDir={0}' -f $resourceDirectory),
  ('-dProductVersion={0}.{1}.{2}.0' -f $Major, $Minor, $Patch), # Don't pad MSI version.
  '-out',
  'obj\',
  '-arch',
  'x64',
  '-ext',
  'WixUtilExtension.dll',
  '-ext',
  'WixUIExtension.dll',
  'src\Fragment.wxs',
  'src\Product.wxs'
& candle.exe $candleArguments

if ($LASTEXITCODE -ne 0)
{
    throw ('Compile failed with exit code {0}.' -f $LASTEXITCODE)
}

# Link.
$lightArguments =
  '-out',
  'bin\vim.msi',
  '-ext',
  'WixUtilExtension.dll',
  '-ext',
  'WixUIExtension.dll',
  '-spdb',
  'obj\Fragment.wixobj',
  'obj\Product.wixobj'
& light.exe $lightArguments

if ($LASTEXITCODE -ne 0)
{
    throw ('Link failed with exit code {0}.' -f $LASTEXITCODE)
}