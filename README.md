# Custom Noctalia Shell Plugins Repository

This repository contains custom plugins for [Noctalia Shell](https://github.com/noctalia-dev/noctalia-shell).

## Active Plugins

* **AmneziaWG**: Connect to AmneziaWG VPN via `awg-quick`.

## How to use this repository

To add this repository to your Noctalia Shell:

1. Open `~/.config/noctalia/plugins.json` in your favorite text editor.
2. Under `"sources"`, add the following entry:
   ```json
   {
       "enabled": true,
       "name": "Alexandr-Sol Custom Plugins",
       "url": "https://github.com/Alexandr-Sol/liS-noctalia-plugins"
   }
   ```
3. Open Noctalia Settings -> Plugins, refresh lists and enable the plugin!
