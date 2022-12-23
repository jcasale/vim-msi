# vim-msi

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

A WIX project that packages vim into a Windows MSI

## Releases

This repo checks [vim-win32-installer](https://github.com/vim/vim-win32-installer) daily for a
new release and builds an MSI if required. Only the 10 most recent releases are retained.

## ADDLOCAL Properties

  - Product (mandatory, the vim/gvim binaries and registry entries)
  - ShellIntegration
  - DesktopShortcuts
  - StartMenuShortcuts
  - DefaultVimrc

## Public Properties

When installing the **DefaultVimrc** feature, you can optionally set the following
public properties when not using the UI to adjust the feature:

| MSI Property    | Range                       | Default | Description                               |
|-----------------|-----------------------------|---------|-------------------------------------------|
| VIMRC\_REMAP    | "no", "win"                 | "win"   | Remap some ctrl keys for Windows behavior |
| VIMRC\_BEHAVIOR | "default", "xterm", "mswin" | "mswin" | Right and left mouse button behavior      |

## Notes

The **DesktopShortcuts** feature is disabled by default.