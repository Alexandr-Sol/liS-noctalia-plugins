# DNS Routing Switcher

[English](README.md) | [Русский](README.ru.md)

---

A DNS Manager plugin for Noctalia Shell that allows switching global DNS servers and configuring Split DNS (domain routing) via `systemd-resolved`.

---

## Dependencies & Requirements

* `networkmanager` (provides `nmcli` for managing connection-level DNS settings)
* `systemd` (provides `systemd-resolved` and `systemctl` for handling Split DNS domain routing)
* `polkit` (provides `pkexec` to apply system configurations)

## Features

- Quick switching between predefined public DNS providers (Google, Cloudflare, AdGuard, Quad9, etc.)
- Ability to add and manage custom global DNS servers
- Split DNS (domain routing): route specific domains or top-level domains through custom DNS servers
- Visual DNS status indicator on the panel and in the control center
- Systemd-resolved configuration generator

## How It Works

Under the hood, the plugin runs the following operations:
1. **DNS check**:
   ```bash
   nmcli -f IP4.DNS dev show
   ```
2. **Apply DNS**: Modifies the active connection in NetworkManager.
   ```bash
   nmcli con mod <connection> ipv4.dns "<ip>" ipv4.ignore-auto-dns yes
   nmcli con up <connection>
   ```
3. **Split DNS Routing**: Writes configuration file `/etc/systemd/resolved.conf.d/noctalia.conf` and restarts systemd-resolved.
   ```bash
   systemctl restart systemd-resolved
   ```
