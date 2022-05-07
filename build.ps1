[CmdletBinding(DefaultParameterSetName='default')]
param
(
    [Parameter(Mandatory=$true,Position=0,ParameterSetName='Explicit')]
    [uri]
    $Uri,
    [Parameter(Mandatory=$true,Position=1,ParameterSetName='Explicit')]
    [version]
    $Version,
    [bool]
    $Clean = $true
)

Set-StrictMode -Version Latest

Add-Type -Assembly 'System.IO.Compression.FileSystem' -ErrorAction Stop

# Check requirements.
[void](Get-Command 'git.exe' -ErrorAction Stop)
[void](Get-Command 'heat.exe' -ErrorAction Stop)
[void](Get-Command 'candle.exe' -ErrorAction Stop)
[void](Get-Command 'light.exe' -ErrorAction Stop)

# Determine release URI and version.
if ($PsCmdlet.ParameterSetName -eq 'Explicit')
{
    $releaseUri = $Uri
    $releaseVersion = $Version
}
else
{
    $apiUri = 'https://api.github.com/repos/vim/vim-win32-installer/releases/latest'
    $response = Invoke-RestMethod -Uri $apiUri -Verbose:$false -ErrorAction Stop
    $assetVersion = $response.tag_name.TrimStart('v')
    [regex]$regex = 'gvim_{0}_x64.zip' -f $assetVersion
    $asset = $response.assets.Where({ $_.name -match $regex }, 'First')
    if ($null -eq $asset)
    {
        throw 'Failed to query the latest release.'
    }

    $releaseUri = [uri]$asset.browser_download_url
    $releaseVersion = [version]$assetVersion
}

Write-Verbose ('Using vim version {0}.' -f $releaseVersion)

# Clean build environment.
& git.exe 'clean' '-xfd' '--exclude=.vscode/'

if ($LASTEXITCODE -ne 0)
{
   throw 'Git clean failed with exit code {0}.' -f $LASTEXITCODE
}

# Prepare build environment.
$pathTemp = New-Item -Path tmp -ItemType Directory -ErrorAction Stop

$fileNameArchive = split-path -leaf $releaseUri.AbsolutePath
$pathArchive = Join-Path $pathTemp $fileNameArchive
$pathProductSource = Join-Path $pathTemp '\vim\vim82'
$pathSrc = Join-Path $PSScriptRoot 'src'
$pathWixProductSource = Join-Path $pathSrc 'Product.wxs'
$pathWixProductObj = Join-Path $pathTemp 'Product.wixobj'
$pathWixFragmentSource = Join-Path $pathTemp 'Fragment.wxs'
$pathWixFragmentObj = Join-Path $pathTemp 'Fragment.wixobj'
$pathMsi = Join-Path $pathTemp 'vim.msi'

# Download release archive.
$webClient = [Net.WebClient]::new()
try
{
    $webClient.DownloadFile($releaseUri, $pathArchive)
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
    [System.IO.Compression.ZipFile]::ExtractToDirectory($pathArchive, $pathTemp.FullName)
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

Write-Verbose 'Harvesting vim files.'

# Harvest.
$heatArguments =
  'dir',
  $pathProductSource,
  '-nologo',
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

Write-Verbose 'Compiling vim files.'

# Compile.
$candleArguments =
  '-nologo',
  ('-dVimSource={0}' -f $pathProductSource),
  ('-dSrcDirectory={0}' -f $pathSrc),
  ('-dProductVersion={0}' -f $releaseVersion),
  '-out',
  ($pathTemp.FullName.TrimEnd('\') + '\'),
  '-arch',
  'x64',
  '-ext',
  'WixUtilExtension.dll',
  '-ext',
  'WixUIExtension.dll',
  $pathWixFragmentSource,
  $pathWixProductSource
& candle.exe $candleArguments |Out-Null

if ($LASTEXITCODE -ne 0)
{
    throw ('Compile failed with exit code {0}.' -f $LASTEXITCODE)
}

Write-Verbose 'Linking vim files.'

# Link.
$lightArguments =
  '-nologo',
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

# Clean up.
$pathRelease = New-Item -Path ('v{0}' -f $releaseVersion) -ItemType Directory -ErrorAction Stop
Move-Item $pathMsi $pathRelease -ErrorAction Stop

if ($Clean)
{
    Remove-Item $pathTemp -Force -Recurse
}