# vim-msi

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE.md)

A WIX project that packages vim into a Windows MSI

## Compiling the MSI

Invoke the PowerShell script with the version desired:
```powershell
.\build\build.ps1 8 0 1257
```

## ADDLOCAL Properties

  - Product (mandatory, the vim/gvim binaries and registry entries)
  - ShellIntegration
  - DesktopShortcuts
  - StartMenuShortcuts
  - DefaultVimrc

## Public Properties

When installing the **DefaultVimrc** feature, you can optionally set the following
public properties when not using the UI to adjust the feature:

MSI Property | Range | Default | Description
--- | --- | --- | ---
VIMRC\_REMAP | "no", "win" | "win" | Remap some ctrl keys for Windows behavior
VIMRC\_BEHAVIOR | "default", "xterm", "mswin" | "mswin" | Right and left mouse button behavior

## Notes

The **DesktopShortcuts** feature is disabled by default.