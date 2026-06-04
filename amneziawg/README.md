# AmneziaWG Plugin for Noctalia

This plugin allows you to manage AmneziaWG VPN connections using `awg-quick`.

## Requirements

- `amneziawg-tools` (provides `awg` and `awg-quick`)
- `polkit` (for `pkexec` graphical authentication)

## Configuration

Configurations are automatically loaded from `/etc/amnezia/amneziawg/`. Ensure your `.conf` files are placed there.
The plugin will use `pkexec ls` to scan the directory on startup, which will trigger a Polkit authentication prompt.
Connecting and disconnecting will also trigger a Polkit authentication prompt via `pkexec`.

## Features

- Quick connect/disconnect from the bar
- Profile management
- Automatic stopping of `zapret.service` when VPN is connected (optional)
