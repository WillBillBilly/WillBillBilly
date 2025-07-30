# Windows Background Theme Changer

A comprehensive PowerShell script to change your Windows background and theme settings.

## Features

- 🖼️ Set custom wallpapers with different styles (Fill, Fit, Stretch, Tile, Center, Span)
- 🎨 Set solid color backgrounds
- 🌓 Switch between Light, Dark, and Auto themes
- 🖥️ Download random wallpapers from Unsplash
- 🎯 Preset theme configurations
- 📱 Interactive menu for easy use

## Usage

### Interactive Mode (Recommended)
```powershell
.\Change-BackgroundTheme.ps1
```

### Command Line Examples

**Set a custom wallpaper:**
```powershell
.\Change-BackgroundTheme.ps1 -WallpaperPath "C:\Pictures\wallpaper.jpg" -WallpaperStyle "Fill" -ThemeMode "Dark"
```

**Set solid color background:**
```powershell
.\Change-BackgroundTheme.ps1 -SetSolidColor -BackgroundColor "#2D3748" -ThemeMode "Dark"
```

**Set light theme with fit wallpaper:**
```powershell
.\Change-BackgroundTheme.ps1 -WallpaperPath "C:\Pictures\light-wallpaper.jpg" -WallpaperStyle "Fit" -ThemeMode "Light"
```

## Prerequisites

- Windows 10/11
- PowerShell 5.1 or later
- Administrator privileges may be required for some registry changes

## Parameters

- `WallpaperPath`: Path to wallpaper image file
- `ThemeMode`: Light, Dark, or Auto (based on time of day)
- `WallpaperStyle`: Fill, Fit, Stretch, Tile, Center, or Span
- `SetSolidColor`: Switch to enable solid color background
- `BackgroundColor`: Hex color code for solid background (e.g., #FF5733)

## Execution Policy

If you encounter execution policy errors, run PowerShell as Administrator and execute:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```
