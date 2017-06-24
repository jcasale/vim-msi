# vim-msi

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE.md)

A WIX project that packages vim into a Windows MSI

## Compiling the MSI

Invoke the PowerShell script with the version desired:
```powershell
.\build\build.ps1 8 0 458
```

## ADDLOCAL properties
  - Product (mandatory, the vim/gvim binaries and registry entries)
  - ShellIntegration
  - DesktopShortcuts
  - StartMenuShortcuts
  - DefaultVimrc

## Notes

The **DesktopShortcuts** feature is disabled by default.