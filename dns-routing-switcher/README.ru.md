# DNS Routing Switcher

[English](README.md) | [Русский](README.ru.md)

---

Плагин для управления DNS в Noctalia Shell, позволяющий переключать глобальные DNS-серверы и настраивать Split DNS (маршрутизацию доменов) через `systemd-resolved`.

---

## Зависимости и требования

* `networkmanager` (предоставляет `nmcli` для управления настройками DNS сетевых соединений)
* `systemd` (предоставляет `systemd-resolved` и `systemctl` для Split DNS маршрутизации доменов)
* `polkit` (предоставляет `pkexec` для применения системных настроек)

## Возможности

- Быстрое переключение между популярными публичными DNS-провайдерами (Google, Cloudflare, AdGuard, Quad9 и др.)
- Возможность добавлять свои собственные глобальные DNS-серверы
- Split DNS (маршрутизация доменов): перенаправление запросов для определённых доменов через выделенные DNS-серверы
- Удобный индикатор статуса DNS на панели и в центре управления
- Генератор конфигурации для systemd-resolved

## Принцип работы

Под капотом плагин выполняет следующие операции:
1. **Проверка текущего DNS**:
   ```bash
   nmcli -f IP4.DNS dev show
   ```
2. **Применение глобального DNS**: Изменение настроек активного соединения в NetworkManager.
   ```bash
   nmcli con mod <соединение> ipv4.dns "<ip>" ipv4.ignore-auto-dns yes
   nmcli con up <соединение>
   ```
3. **Маршрутизация Split DNS**: Запись конфигурационного файла `/etc/systemd/resolved.conf.d/noctalia.conf` и перезапуск службы.
   ```bash
   systemctl restart systemd-resolved
   ```
