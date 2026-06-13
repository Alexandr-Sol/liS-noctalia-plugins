# Плагин AmneziaWG-go для Noctalia

[English](README.md) | [Русский](README.ru.md)

---

![](../images/image1.png) ![](../images/image2.png)

---

Этот плагин позволяет управлять VPN-подключениями AmneziaWG в **пространстве пользователя** (userspace) с использованием реализации `amneziawg-go` непосредственно из **Noctalia**.

---

## Зависимости и требования

* `amneziawg-tools` (предоставляет `awg-quick` и `awg`)
* `amneziawg-go` (userspace-реализация)
* `polkit` (предоставляет `pkexec`)
* VPN-конфигурации в директории `/etc/amnezia/amneziawg/`
* `zapret` (опциональная служба systemd)

---

## Команды, используемые плагином

Плагин выполняет следующие системные команды:

### 1. Сканирование профилей
Для получения списка доступных конфигураций:
```bash
pkexec ls /etc/amnezia/amneziawg/
```

### 2. Управление подключением
Для включения интерфейса (подключение) в режиме userspace:
```bash
pkexec env WG_QUICK_USERSPACE_IMPLEMENTATION=amneziawg-go awg-quick up <путь_к_файлу_конфигурации>
```

Для выключения интерфейса (отключение):
```bash
pkexec env WG_QUICK_USERSPACE_IMPLEMENTATION=amneziawg-go awg-quick down <путь_к_файлу_конфигурации>
```

### 3. Проверка статуса
Для определения активных в данный момент интерфейсов:
```bash
awg show interfaces
```

### 4. Интеграция с Zapret (Опционально)
Для проверки наличия и статуса службы Zapret:
```bash
systemctl list-unit-files zapret.service
systemctl is-active zapret
```

Для запуска и остановки службы:
```bash
systemctl start zapret
systemctl stop zapret
```

## Настройка Polkit (выполнение без пароля)

Чтобы плагин мог управлять VPN-подключениями и получать список файлов конфигурации без постоянного запроса пароля администратора через `pkexec`, вы можете создать правило Polkit.

Создайте файл `/etc/polkit-1/rules.d/10-noctalia-plugins.rules` со следующим содержимым:

```javascript
/* Разрешить выполнение системных команд для плагинов Noctalia без пароля для группы wheel */
polkit.addRule(function(action, subject) {
    if (action.id == "org.freedesktop.policykit.exec" &&
        subject.isInGroup("wheel")) {
        var program = action.lookup("program");
        if (program == "/usr/bin/ls" ||
            program == "/usr/bin/awg-quick" ||
            program == "/usr/bin/env" ||
            program == "/usr/bin/sh") {
            return polkit.Result.YES;
        }
    }
});
```

Убедитесь, что владельцем файла является `root:root`, а права доступа установлены в `0644`.
