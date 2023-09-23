# PSYS - Portable SYStem - v0.0.1

# Enable TLSv1.2 for compatibility with older clients
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

# Disable progress bar
$ProgressPreference = "SilentlyContinue"

# Default install path
$installPath = "$env:UserProfile\PSYS"

function SetInstallPath {
    $installPath = Read-Host -Prompt "Enter install path (default: $env:UserProfile\PSYS)"
    if ($installPath -eq "") {
        $installPath = "$env:UserProfile\PSYS"
    }
    Write-Host "Install path: $installPath"

    # Create install path
    if (Test-Path -Path $installPath) {
        Write-Host "Install path already exists"

        while ($true) {
            $option = Read-Host -Prompt "Make a fresh new installation [y/n]"

            if ($option -eq "y") {
                Uninstaller
                # unsafe
                $null = New-Item -Path $installPath -ItemType Directory
                break
            }
            elseif ($option -eq "n") {
                Exit 0
            }
            else {
                Write-Host "Invalid option"
            }
        }

    }
    else {
        # unsafe
        $null = New-Item -Path $installPath -ItemType Directory
    }
}

# MSYS2 installer
function MSYS2Installer {
    $urlGithubMSYS2 = "https://api.github.com/repos/msys2/msys2-installer/releases/latest"
    $responseGithubMSYS2 = Invoke-RestMethod -Uri $urlGithubMSYS2

    foreach ($asset in $responseGithubMSYS2.assets) {
        if ($asset.name -like "*x86_64-latest.sfx.exe") {
            $urlMSYS2 = $asset.browser_download_url
        }
    }

    if ($urlMSYS2) {
        Write-Debug -Message "Found MSYS2 installer"
        $pathMSYS2 = "$env:Temp\msys2.sfx.exe"
        Invoke-WebRequest -Uri $urlMSYS2 -OutFile $pathMSYS2
        Start-Process -FilePath $pathMSYS2 -ArgumentList "-o$installpath" -Wait
    }
}

function AlacrittyInstaller {
    $url_alacritty_github = "https://api.github.com/repos/alacritty/alacritty/releases/latest"
    $response_alacritty_github = Invoke-RestMethod -Uri $url_alacritty_github

    foreach ($asset in $response_alacritty_github.assets) {
        if ($asset.name -like "*portable.exe") {
            $urlAlacrittyPortable = $asset.browser_download_url
            $nameAlacrittyPortable = $asset.name
        }
        if ($asset.name -like "alacritty.yml") {
            $urlAlacrittyConfigFile = $asset.browser_download_url
        }
    }

    if ($urlAlacrittyPortable) {
        Write-Debug -Message "Found Alacritty portable"
        $pathAlacrittyPortable = "$installPath\$nameAlacrittyPortable"
        Invoke-WebRequest -Uri $urlAlacrittyPortable -OutFile $pathAlacrittyPortable
    }

    if ($urlAlacrittyConfigFile) {
        Write-Debug -Message "Found Alacritty config file"
        $pathAlacrittyConfigFile = "$installpath\alacritty.yml"
        Invoke-WebRequest -Uri $urlAlacrittyConfigFile -OutFile $pathAlacrittyConfigFile
    }

    $null = New-Item -Path "$installPath" -ItemType SymbolicLink -Name "Alacritty.lnk" -Value "$installPath\$nameAlacrittyPortable -e$installPath\msys64\usr\bin\bash.exe"
}

function Installer {
    Write-Host "Installing PSYS..."

    # Set install path
    SetInstallPath

    # Install MSYS2
    MSYS2Installer

    # Install Alacritty
    AlacrittyInstaller

    Write-Host "Installation complete!"
}

function Uninstaller {
    Write-Host "Uninstalling PSYS from default path $installPath"

    # Remove install path
    Remove-Item -Path $installPath -Recurse -Force

    Write-Host "Uninstallation complete!"
}

function Main {
    Write-Host "PSYS - Portable SYStem"
    Write-Host "(i) - Install (default)"
    Write-Host "(u) - Uninstall"

    while ($true) {
        $option = Read-Host -Prompt "Choice [i/u]"

        if ($option -eq "" -or $option -eq "i") {
            Installer
            break
        }
        elseif ($option -eq "u") {
            Uninstaller
            break
        }
        else {
            Write-Host "Invalid option"
        }
    }
}

Main