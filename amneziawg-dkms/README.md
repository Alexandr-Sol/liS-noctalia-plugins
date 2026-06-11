# AmneziaWG-dkms Plugin for Noctalia

[English](README.md) | [Русский](README.ru.md)

---

![](../image1.png) ![](../image2.png)

---

This plugin allows managing AmneziaWG VPN connections using the kernel space DKMS implementation directly from **Noctalia**.

---

## Dependencies & Requirements

* `amneziawg-tools` (provides `awg-quick` and `awg`)
* `amneziawg-dkms` (kernel module)
* `polkit` (provides `pkexec`)
* VPN configurations stored in `/etc/amnezia/amneziawg/`
* `zapret` (optional systemd service)

---

## Commands Used by the Plugin

The plugin runs the following commands under the hood:

### 1. Profile Discovery
To scan for available configurations:
```bash
pkexec ls /etc/amnezia/amneziawg/
```

### 2. Connection Management
To bring the interface **up**:
```bash
pkexec awg-quick up <path_to_config>
```

To bring the interface **down**:
```bash
pkexec awg-quick down <path_to_config>
```

### 3. Status Checking
To check which interfaces are currently active:
```bash
awg show interfaces
```

### 4. Zapret Integration (Optional)
To check if Zapret is installed and active:
```bash
systemctl list-unit-files zapret.service
systemctl is-active zapret
```

To start and stop the service:
```bash
systemctl start zapret
systemctl stop zapret
```
