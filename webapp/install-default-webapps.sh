#!/bin/bash

# Install a set of popular default web apps
# Based on common web apps but with generic names

set -e

WEBAPP_SCRIPTS="$HOME/.config/DankMaterialShell/scripts/webapp"

# Install popular web apps with custom handlers for some
echo "Installing default web apps..."

# Email handler (HEY)
"$WEBAPP_SCRIPTS/webapp-install" "HEY Email" "https://app.hey.com" "HEY.png" \
    "$WEBAPP_SCRIPTS/webapp-handler-email %u" "x-scheme-handler/mailto"

# Communication apps
"$WEBAPP_SCRIPTS/webapp-install" "WhatsApp Web" "https://web.whatsapp.com/" "WhatsApp.png"

# Google services
"$WEBAPP_SCRIPTS/webapp-install" "Google Photos" "https://photos.google.com/" "Google Photos.png"
"$WEBAPP_SCRIPTS/webapp-install" "Google Contacts" "https://contacts.google.com/" "Google Contacts.png"
"$WEBAPP_SCRIPTS/webapp-install" "Google Messages" "https://messages.google.com/web/conversations" "Google Messages.png"

# Social media
"$WEBAPP_SCRIPTS/webapp-install" "X (Twitter)" "https://x.com/" "X.png"
"$WEBAPP_SCRIPTS/webapp-install" "Discord" "https://discord.com/channels/@me" "Discord.png"

# Productivity
"$WEBAPP_SCRIPTS/webapp-install" "ChatGPT" "https://chatgpt.com/" "ChatGPT.png"
"$WEBAPP_SCRIPTS/webapp-install" "GitHub" "https://github.com/" "GitHub.png"
"$WEBAPP_SCRIPTS/webapp-install" "Figma" "https://figma.com/" "Figma.png"

# Meeting handler (Zoom)
"$WEBAPP_SCRIPTS/webapp-install" "Zoom" "https://app.zoom.us/wc/home" "Zoom.png" \
    "$WEBAPP_SCRIPTS/webapp-handler-meeting %u" "x-scheme-handler/zoommtg;x-scheme-handler/zoomus"

# Entertainment
"$WEBAPP_SCRIPTS/webapp-install" "YouTube" "https://youtube.com/" "YouTube.png"

echo "Default web apps installed successfully!"
echo "You can find them in your DMS application launcher."