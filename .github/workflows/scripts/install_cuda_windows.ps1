## -------------------
## Constants
## -------------------

# Dictionary of known cuda versions and thier download URLS, which do not follow a consistent pattern :(
$CUDA_KNOWN_URLS = @{
    "10.1.243" = "https://developer.download.nvidia.com/compute/cuda/10.1/Prod/network_installers/cuda_10.1.243_win10_network.exe";
    "10.2.89" = "https://developer.download.nvidia.com/compute/cuda/10.2/Prod/network_installers/cuda_10.2.89_win10_network.exe";
    "11.0.2" = "https://developer.download.nvidia.com/compute/cuda/11.0.2/network_installers/cuda_11.0.2_win10_network.exe";
    "11.1.1" = "https://developer.download.nvidia.com/compute/cuda/11.1.1/network_installers/cuda_11.1.1_win10_network.exe"
}

# cuda_runtime.h is in nvcc <= 10.2, but cudart >= 11.0
# @todo - make this easier to vary per CUDA version.
$CUDA_PACKAGES_IN = @(
    "nvcc";
    "visual_studio_integration";
    "curand_dev";
    "cublas_dev";
    "cufft_dev";
    "cusolver_dev";
    "cusparse_dev";
    "nvrtc_dev";
    "cudart";
    "nsight_nvtx";
)


## -------------------
## Select CUDA version
## -------------------

# Get the cuda version from the environment as env:cuda.
$CUDA_VERSION_FULL = $env:cuda
$CUDNN_VERSION_FULL = $env:cudnn

# Validate CUDA version, extracting components via regex
$cuda_ver_matched = $CUDA_VERSION_FULL -match "^(?<major>[1-9][0-9]*)\.(?<minor>[0-9]+)\.(?<patch>[0-9]+)$"
if(-not $cuda_ver_matched){
    Write-Output "Invalid CUDA version specified, <major>.<minor>.<patch> required. '$CUDA_VERSION_FULL'."
    exit 1
}
$CUDA_MAJOR=$Matches.major
$CUDA_MINOR=$Matches.minor
$CUDA_PATCH=$Matches.patch

# Validate CUDNN version, extracting components via regex
$cudnn_ver_matched = $CUDNN_VERSION_FULL -match "^(?<major>[0-9]+)\.(?<minor>[0-9]+)\.(?<patch>[0-9]+)\.(?<build>[0-9]+)$"
if(-not $cuda_ver_matched){
    Write-Output "Invalid CUDNN version specified, <major>.<minor>.<patch>.<build> required. '$CUDNN_VERSION_FULL'."
    exit 1
}
$CUDNN_MAJOR=$Matches.major
$CUDNN_MINOR=$Matches.minor
$CUDNN_PATCH=$Matches.patch
$CUDNN_BUILD=$Matches.build

## ------------------------------------------------
## Select CUDA packages to install from environment
## ------------------------------------------------

$CUDA_PACKAGES = ""

# for CUDA >= 11 cudart is a required package.
# if([version]$CUDA_VERSION_FULL -ge [version]"11.0") {
#     if(-not $CUDA_PACKAGES_IN -contains "cudart") {
#         $CUDA_PACKAGES_IN += 'cudart'
#     }
# }

Foreach ($package in $CUDA_PACKAGES_IN) {
    # Make sure the correct package name is used for nvcc.
    if($package -eq "nvcc" -and [version]$CUDA_VERSION_FULL -lt [version]"9.1"){
        $package="compiler"
    } elseif($package -eq "compiler" -and [version]$CUDA_VERSION_FULL -ge [version]"9.1") {
        $package="nvcc"
    }
    $CUDA_PACKAGES += " $($package)_$($CUDA_MAJOR).$($CUDA_MINOR)"

}
echo "$($CUDA_PACKAGES)"
## -----------------
## Prepare download
## -----------------

# Select the download link if known, otherwise have a guess.
$CUDA_REPO_PKG_REMOTE=""
if($CUDA_KNOWN_URLS.containsKey($CUDA_VERSION_FULL)){
    $CUDA_REPO_PKG_REMOTE=$CUDA_KNOWN_URLS[$CUDA_VERSION_FULL]
} else{
    # Guess what the url is given the most recent pattern (at the time of writing, 10.1)
    Write-Output "note: URL for CUDA ${$CUDA_VERSION_FULL} not known, estimating."
    $CUDA_REPO_PKG_REMOTE="http://developer.download.nvidia.com/compute/cuda/$($CUDA_VERSION_FULL)/network_installers/cuda_$($CUDA_VERSION_FULL)_win10_network.exe"
}
$TEMP_PATH = [System.IO.Path]::GetTempPath()
$CUDA_REPO_PKG_LOCAL = Join-Path $TEMP_PATH "cuda_$($CUDA_VERSION_FULL)_win10_network.exe"


## ------------
## Install CUDA
## ------------

# Get CUDA network installer
Write-Output "Downloading CUDA Network Installer for $($CUDA_VERSION_FULL) from: $($CUDA_REPO_PKG_REMOTE)"
Invoke-WebRequest $CUDA_REPO_PKG_REMOTE -OutFile $CUDA_REPO_PKG_LOCAL | Out-Null
if(Test-Path -Path $CUDA_REPO_PKG_LOCAL){
    Write-Output "Downloading Complete"
} else {
    Write-Output "Error: Failed to download $($CUDA_REPO_PKG_LOCAL) from $($CUDA_REPO_PKG_REMOTE)"
    exit 1
}

# Invoke silent install of CUDA (via network installer)
Write-Output "Installing CUDA $($CUDA_VERSION_FULL). Subpackages $($CUDA_PACKAGES)"
Start-Process -Wait -FilePath "$($CUDA_REPO_PKG_LOCAL)" -ArgumentList "-s $($CUDA_PACKAGES)"

# Check the return status of the CUDA installer.
if (!$?) {
    Write-Output "Error: CUDA installer reported error. $($LASTEXITCODE)"
    exit 1 
}

# Store the CUDA_PATH in the environment for the current session, to be forwarded in the action.
$CUDA_PATH = "C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v$($CUDA_MAJOR).$($CUDA_MINOR)"
$CUDA_PATH_VX_Y = "CUDA_PATH_V$($CUDA_MAJOR)_$($CUDA_MINOR)" 

# PATH needs updating elsewhere, anything in here won't persist.
# Append $CUDA_PATH/bin to path.
# Set CUDA_PATH as an environmental variable

$CUDNN_ZIP_REMOTE = "http://developer.download.nvidia.com/compute/redist/cudnn/v$($CUDNN_MAJOR).$($CUDNN_MINOR).$($CUDNN_PATCH)/cudnn-$($CUDA_MAJOR).$($CUDA_MINOR)-windows-x64-v$($CUDNN_VERSION_FULL).zip"
$CUDNN_ZIP_LOCAL = Join-Path $TEMP_PATH "cudnn.zip"

Write-Output "Downloading CUDNN zip for $($CUDNN_VERSION_FULL) from: $($CUDNN_ZIP_REMOTE)"
Invoke-WebRequest $CUDNN_ZIP_REMOTE -OutFile $CUDNN_ZIP_LOCAL | Out-Null
if(Test-Path -Path $CUDNN_ZIP_LOCAL){
    Write-Output "Downloading Complete"
} else {
    Write-Output "Error: Failed to download $($CUDNN_ZIP_LOCAL) from $($CUDNN_ZIP_REMOTE)"
    exit 1
}

Write-Output "Installing CUDNN"

Expand-Archive -Path $CUDNN_ZIP_LOCAL -DestinationPath $TEMP_PATH
$CUDNN_EXPAND_LOCAL = Join-Path $TEMP_PATH "cuda"
Copy-Item -Path "$($CUDNN_EXPAND_LOCAL)/*" -Destination $CUDA_PATH -Filter *.* -Force -recurse

# Set environmental variables in this session
$env:CUDA_PATH = "$($CUDA_PATH)"
$env:CUDA_PATH_VX_Y = "$($CUDA_PATH_VX_Y)"
Write-Output "CUDA_PATH $($CUDA_PATH)"
Write-Output "CUDA_PATH_VX_Y $($CUDA_PATH_VX_Y)"

tree $CUDA_PATH /f