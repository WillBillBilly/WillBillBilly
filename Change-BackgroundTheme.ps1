# PowerShell Script to Change Windows Background Theme
# Author: Assistant
# Description: Changes Windows wallpaper and theme settings

param(
    [Parameter(Mandatory=$false)]
    [string]$WallpaperPath,
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("Light", "Dark", "Auto")]
    [string]$ThemeMode = "Dark",
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("Fill", "Fit", "Stretch", "Tile", "Center", "Span")]
    [string]$WallpaperStyle = "Fill",
    
    [Parameter(Mandatory=$false)]
    [switch]$SetSolidColor,
    
    [Parameter(Mandatory=$false)]
    [string]$BackgroundColor = "#000000"
)

# Function to set wallpaper
function Set-Wallpaper {
    param(
        [string]$Path,
        [string]$Style = "Fill"
    )
    
    # Map style names to registry values
    $styleMap = @{
        "Fill" = "10"
        "Fit" = "6"
        "Stretch" = "2"
        "Tile" = "0"
        "Center" = "0"
        "Span" = "22"
    }
    
    $tileWallpaper = if ($Style -eq "Tile") { "1" } else { "0" }
    $wallpaperStyle = $styleMap[$Style]
    
    try {
        # Set wallpaper style in registry
        Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name WallpaperStyle -Value $wallpaperStyle -Force
        Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name TileWallpaper -Value $tileWallpaper -Force
        
        # Update wallpaper using SystemParametersInfo
        Add-Type -TypeDefinition @"
            using System;
            using System.Runtime.InteropServices;
            
            public class Wallpaper {
                [DllImport("user32.dll", CharSet = CharSet.Auto)]
                public static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
            }
"@
        
        $SPI_SETDESKWALLPAPER = 0x0014
        $SPIF_UPDATEINIFILE = 0x01
        $SPIF_SENDCHANGE = 0x02
        
        [Wallpaper]::SystemParametersInfo($SPI_SETDESKWALLPAPER, 0, $Path, $SPIF_UPDATEINIFILE -bor $SPIF_SENDCHANGE)
        
        Write-Host "✅ Wallpaper set successfully: $Path" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Error "❌ Failed to set wallpaper: $($_.Exception.Message)"
        return $false
    }
}

# Function to set solid color background
function Set-SolidColorBackground {
    param([string]$Color)
    
    try {
        # Convert hex color to RGB
        $hex = $Color -replace '#', ''
        $r = [convert]::ToInt32($hex.Substring(0,2), 16)
        $g = [convert]::ToInt32($hex.Substring(2,2), 16)
        $b = [convert]::ToInt32($hex.Substring(4,2), 16)
        
        # Set solid color in registry
        $rgbValue = $r + ($g * 256) + ($b * 65536)
        Set-ItemProperty -Path "HKCU:\Control Panel\Colors" -Name Background -Value "$r $g $b" -Force
        Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name Wallpaper -Value "" -Force
        
        # Update desktop
        Add-Type -TypeDefinition @"
            using System;
            using System.Runtime.InteropServices;
            
            public class Desktop {
                [DllImport("user32.dll", CharSet = CharSet.Auto)]
                public static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
            }
"@
        
        $SPI_SETDESKWALLPAPER = 0x0014
        $SPIF_UPDATEINIFILE = 0x01
        $SPIF_SENDCHANGE = 0x02
        
        [Desktop]::SystemParametersInfo($SPI_SETDESKWALLPAPER, 0, "", $SPIF_UPDATEINIFILE -bor $SPIF_SENDCHANGE)
        
        Write-Host "✅ Solid color background set: $Color" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Error "❌ Failed to set solid color background: $($_.Exception.Message)"
        return $false
    }
}

# Function to set Windows theme mode (Light/Dark)
function Set-WindowsTheme {
    param([string]$Mode)
    
    try {
        $themeValue = switch ($Mode) {
            "Light" { 1 }
            "Dark" { 0 }
            "Auto" { 
                # Auto mode - set based on time of day
                $hour = (Get-Date).Hour
                if ($hour -ge 6 -and $hour -lt 18) { 1 } else { 0 }
            }
        }
        
        # Set app theme
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name AppsUseLightTheme -Value $themeValue -Force
        
        # Set system theme
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name SystemUsesLightTheme -Value $themeValue -Force
        
        $themeName = if ($themeValue -eq 1) { "Light" } else { "Dark" }
        Write-Host "✅ Windows theme set to: $themeName" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Error "❌ Failed to set Windows theme: $($_.Exception.Message)"
        return $false
    }
}

# Function to download and set a random wallpaper
function Set-RandomWallpaper {
    param([string]$Category = "nature")
    
    try {
        $width = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds.Width
        $height = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds.Height
        
        # Unsplash API for random wallpapers
        $url = "https://source.unsplash.com/${width}x${height}/?$Category"
        $tempPath = "$env:TEMP\wallpaper_$(Get-Date -Format 'yyyyMMdd_HHmmss').jpg"
        
        Write-Host "🔄 Downloading random wallpaper..." -ForegroundColor Yellow
        Invoke-WebRequest -Uri $url -OutFile $tempPath -UseBasicParsing
        
        if (Test-Path $tempPath) {
            Set-Wallpaper -Path $tempPath -Style $WallpaperStyle
            Write-Host "✅ Random wallpaper downloaded and set!" -ForegroundColor Green
            return $true
        }
    }
    catch {
        Write-Error "❌ Failed to download random wallpaper: $($_.Exception.Message)"
        return $false
    }
}

# Function to show interactive menu
function Show-ThemeMenu {
    do {
        Clear-Host
        Write-Host "🎨 Windows Background Theme Changer" -ForegroundColor Cyan
        Write-Host "=================================" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "1. Set custom wallpaper from file"
        Write-Host "2. Set solid color background"
        Write-Host "3. Download random wallpaper"
        Write-Host "4. Change theme mode (Light/Dark)"
        Write-Host "5. Apply preset themes"
        Write-Host "6. Exit"
        Write-Host ""
        
        $choice = Read-Host "Select an option (1-6)"
        
        switch ($choice) {
            "1" {
                $file = Read-Host "Enter wallpaper file path"
                if (Test-Path $file) {
                    $style = Read-Host "Enter style (Fill, Fit, Stretch, Tile, Center, Span) [Default: Fill]"
                    if ([string]::IsNullOrEmpty($style)) { $style = "Fill" }
                    Set-Wallpaper -Path $file -Style $style
                } else {
                    Write-Host "❌ File not found!" -ForegroundColor Red
                }
                Read-Host "Press Enter to continue"
            }
            "2" {
                $color = Read-Host "Enter hex color (e.g., #FF5733) [Default: #000000]"
                if ([string]::IsNullOrEmpty($color)) { $color = "#000000" }
                Set-SolidColorBackground -Color $color
                Read-Host "Press Enter to continue"
            }
            "3" {
                $category = Read-Host "Enter category (nature, technology, abstract, etc.) [Default: nature]"
                if ([string]::IsNullOrEmpty($category)) { $category = "nature" }
                Set-RandomWallpaper -Category $category
                Read-Host "Press Enter to continue"
            }
            "4" {
                $mode = Read-Host "Enter theme mode (Light, Dark, Auto) [Default: Dark]"
                if ([string]::IsNullOrEmpty($mode)) { $mode = "Dark" }
                Set-WindowsTheme -Mode $mode
                Read-Host "Press Enter to continue"
            }
            "5" {
                Write-Host "🎨 Preset Themes:" -ForegroundColor Cyan
                Write-Host "1. Dark Ocean Theme"
                Write-Host "2. Light Minimalist Theme"
                Write-Host "3. Gaming Theme"
                Write-Host "4. Professional Theme"
                
                $preset = Read-Host "Select preset (1-4)"
                switch ($preset) {
                    "1" {
                        Set-WindowsTheme -Mode "Dark"
                        Set-RandomWallpaper -Category "ocean"
                    }
                    "2" {
                        Set-WindowsTheme -Mode "Light"
                        Set-SolidColorBackground -Color "#F5F5F5"
                    }
                    "3" {
                        Set-WindowsTheme -Mode "Dark"
                        Set-RandomWallpaper -Category "technology"
                    }
                    "4" {
                        Set-WindowsTheme -Mode "Light"
                        Set-RandomWallpaper -Category "business"
                    }
                }
                Read-Host "Press Enter to continue"
            }
            "6" {
                Write-Host "👋 Goodbye!" -ForegroundColor Green
                return
            }
            default {
                Write-Host "❌ Invalid option!" -ForegroundColor Red
                Start-Sleep 2
            }
        }
    } while ($true)
}

# Main script execution
try {
    Write-Host "🎨 Windows Background Theme Changer" -ForegroundColor Cyan
    Write-Host "===================================" -ForegroundColor Cyan
    Write-Host ""
    
    # If no parameters provided, show interactive menu
    if (-not $WallpaperPath -and -not $SetSolidColor) {
        Show-ThemeMenu
        exit 0
    }
    
    # Set theme mode
    if ($ThemeMode) {
        Set-WindowsTheme -Mode $ThemeMode
    }
    
    # Set solid color background
    if ($SetSolidColor) {
        Set-SolidColorBackground -Color $BackgroundColor
    }
    # Set wallpaper from file
    elseif ($WallpaperPath) {
        if (Test-Path $WallpaperPath) {
            Set-Wallpaper -Path $WallpaperPath -Style $WallpaperStyle
        } else {
            Write-Error "❌ Wallpaper file not found: $WallpaperPath"
            exit 1
        }
    }
    
    Write-Host ""
    Write-Host "✅ Theme change completed successfully!" -ForegroundColor Green
    Write-Host "💡 You may need to refresh your desktop or restart Explorer to see all changes." -ForegroundColor Yellow
}
catch {
    Write-Error "❌ An error occurred: $($_.Exception.Message)"
    exit 1
}

# Examples of usage:
<#
# Set a custom wallpaper
.\Change-BackgroundTheme.ps1 -WallpaperPath "C:\Pictures\wallpaper.jpg" -WallpaperStyle "Fill" -ThemeMode "Dark"

# Set solid color background
.\Change-BackgroundTheme.ps1 -SetSolidColor -BackgroundColor "#2D3748" -ThemeMode "Dark"

# Interactive mode (no parameters)
.\Change-BackgroundTheme.ps1

# Set light theme with fit wallpaper
.\Change-BackgroundTheme.ps1 -WallpaperPath "C:\Pictures\light-wallpaper.jpg" -WallpaperStyle "Fit" -ThemeMode "Light"
#>