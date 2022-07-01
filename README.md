# vim-msi

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE.md)

A WIX project that packages vim into a Windows MSI

## Compiling the MSI

Invoke the PowerShell without any parameters to build the latest version:

```powershell
.\build.ps1 -ErrorAction Stop
```

or explicitly define the version:

```powershell
.\build.ps1 `
    -Uri https://github.com/vim/vim-win32-installer/releases/download/v9.0.0014/gvim_9.0.0014_x64.zip `
    -Version 9.0.0014 `
    -ErrorAction Stop
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