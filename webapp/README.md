# Web App Management System

A generic web app installation and management system for DankMaterialShell, based on the Omarchy webapp system.

## Scripts

- `webapp-install` - Create desktop launchers for web apps
- `webapp-remove` - Remove specific web apps interactively
- `webapp-remove-all` - Remove all installed web apps
- `launch-webapp` - Launch URLs as web apps in supported browsers
- `launch-or-focus-webapp` - Launch or focus existing web app windows
- `webapp-handler-email` - Handle mailto: links for email webapps
- `webapp-handler-meeting` - Handle Zoom meeting links

## Usage

### Install a Web App Interactively
```bash
~/.config/DankMaterialShell/scripts/webapp/webapp-install
```

### Install a Web App Programmatically
```bash
~/.config/DankMaterialShell/scripts/webapp/webapp-install "App Name" "https://example.com" "icon.png"
```

### Remove Web Apps
```bash
~/.config/DankMaterialShell/scripts/webapp/webapp-remove
```

### Remove All Web Apps
```bash
~/.config/DankMaterialShell/scripts/webapp/webapp-remove-all
```

## Custom Handlers

You can create custom handlers for protocol links by following the pattern of `webapp-handler-email` and `webapp-handler-meeting`.

## Integration

To integrate with DMS launcher, add this to your DMS menu configuration:
```bash
~/.config/DankMaterialShell/scripts/webapp/webapp-install
```

## Requirements

- `gum` - Interactive terminal UI
- `curl` - For fetching icons
- `xdg-settings` - For browser detection
- Chromium-based browser (Chromium, Brave, Edge, etc.) for best results