# 🛡️ AntiZapret для OPNsense/FreeBSD

<div align="center">

![Version](https://img.shields.io/badge/version-3.0-blue?style=for-the-badge)
![Platform](https://img.shields.io/badge/platform-OPNsense%20%7C%20FreeBSD-orange?style=for-the-badge)
![License](https://img.shields.io/badge/license-MIT-green?style=for-the-badge)

**Прозрачный обход блокировок для локальной сети**

*Никаких настроек на клиентах — работает автоматически для всех устройств*

[🚀 Быстрый старт](#-быстрый-старт) •
[📖 Документация](#-документация) •
[❓ FAQ](#-faq) •
[💬 Поддержка](#-поддержка)

---

</div>

## ✨ Особенности

<table>
<tr>
<td width="50%">

### 🔒 Безопасность
- ✅ Полная поддержка **HTTPS** трафика
- ✅ Работа через **Tor** с мостами (obfs4/webtunnel)
- ✅ Исключение узлов СНГ для приватности

</td>
<td width="50%">

### ⚡ Простота
- ✅ **Прозрачный прокси** — не нужны настройки на клиентах
- ✅ Автоматический установщик
- ✅ Ежедневное обновление списков IP

</td>
</tr>
<tr>
<td>

### 🌐 Совместимость
- ✅ **OPNsense** (полная интеграция)
- ✅ **pfSense** (должно работать)
- ✅ **FreeBSD** (базовая поддержка)

</td>
<td>

### 🛠️ Возможности
- ✅ IPv6 поддержка
- ✅ DNS через Tor
- ✅ Настраиваемые мосты для обхода блокировок Tor

</td>
</tr>
</table>

---

## 🚀 Быстрый старт

### Автоматическая установка (рекомендуется)

```bash
# Подключитесь к роутеру по SSH и выполните:
cd /root
git clone https://github.com/grashooper/antizapret.git
cd antizapret
chmod +x install.sh
./install.sh
```

<details>
<summary>📸 <b>Скриншот процесса установки</b></summary>

```
    ██╗███╗   ██╗███████╗████████╗ █████╗ ██╗     ██╗     ███████╗██████╗ 
    ██║████╗  ██║██╔════╝╚══██╔══╝██╔══██╗██║     ██║     ██╔════╝██╔══██╗
    ██║██╔██╗ ██║███████╗   ██║   ███████║██║     ██║     █████╗  ██████╔╝
    ...
    
    ╔═══════════════════════════════════════════════════════════════════════╗
    ║         ★ ★ ★  INSTALLATION COMPLETED SUCCESSFULLY  ★ ★ ★           ║
    ╚═══════════════════════════════════════════════════════════════════════╝
```

</details>

### Что делает установщик?

| Этап | Описание |
|------|----------|
| 🔍 **Определение системы** | Автоматически определяет ОС, версию и архитектуру |
| 🌐 **Обнаружение сети** | Находит LAN IP адрес для настройки |
| 📦 **Установка пакетов** | Tor, obfs4proxy, webtunnel и опциональные утилиты |
| ⚙️ **Конфигурация** | Настройка Tor с мостами (опционально) |
| 🔄 **Интеграция** | Создание служб и cron-задач для OPNsense |
| ✅ **Проверка** | Верификация работоспособности всех компонентов |

---

## 📖 Документация

| Документ | Описание |
|----------|----------|
| [📋 QUICKSTART.md](QUICKSTART.md) | Установка в одну команду |
| [📘 INSTALL.md](INSTALL.md) | Подробное руководство по установке |
| [🔧 FEATURES.md](FEATURES.md) | Полный список возможностей |
| [❓ FAQ.md](FAQ.md) | Часто задаваемые вопросы |
| [📝 DEMO.txt](DEMO.txt) | Пример работы скрипта установки |
| [📜 CHANGELOG.md](CHANGELOG.md) | История изменений |

### Методы подключения

<table>
<tr>
<td align="center" width="50%">

#### 🧅 Tor с мостами
**Рекомендуется**

Использует obfs4/webtunnel для обхода блокировок самого Tor

[📖 Инструкция](TOR.md)

</td>
<td align="center" width="50%">

#### 🔐 WireGuard VPN
**Альтернатива**

Требуется собственный VPN-сервер на внешнем хостинге

[📖 Инструкция](WireGuard.md)

</td>
</tr>
</table>

---

## ⚙️ Настройка после установки

### Шаг 1: Создание Firewall Alias

```
Firewall → Aliases → Add
├── Name: AntiZapret_IPs
├── Type: External (advanced)
└── Content URL: https://YOUR_LAN_IP/ipfw_antizapret.dat
```

### Шаг 2: Настройка NAT Port Forward

```
Firewall → NAT → Port Forward → Add
├── Interface: LAN
├── Protocol: TCP
├── Destination: AntiZapret_IPs
├── Redirect target IP: 127.0.0.1
└── Redirect target port: 9040
```

### Шаг 3: Расписание обновлений

```
System → Settings → Cron → Add
├── Command: Renew AntiZapret IP-list
└── Schedule: Daily (например, 4:00)
```

---

## 🔧 Команды управления

```bash
# Статус сервиса
service tor status

# Управление Tor
service tor start|stop|restart

# Просмотр логов
tail -f /var/log/tor/notices.log

# Обновление списка IP вручную
/root/antizapret/antizapret.pl

# Количество заблокированных IP
cat /usr/local/www/ipfw_antizapret.dat | wc -l
```

---

## 📁 Расположение файлов

| Файл | Описание |
|------|----------|
| `/usr/local/etc/tor/torrc` | Конфигурация Tor |
| `/usr/local/www/ipfw_antizapret.dat` | Список заблокированных IP |
| `/var/log/tor/notices.log` | Логи Tor |
| `/root/antizapret/antizapret.pl` | Скрипт обновления списков |
| `/usr/local/etc/rc.d/tor` | Скрипт автозапуска |

---

## ❓ FAQ

<details>
<summary><b>Нужно ли что-то настраивать на клиентских устройствах?</b></summary>

Нет! Система работает как прозрачный прокси — весь трафик к заблокированным ресурсам автоматически направляется через Tor.

</details>

<details>
<summary><b>Поддерживается ли HTTPS?</b></summary>

Да, полная поддержка HTTPS без необходимости установки сертификатов на клиентах.

</details>

<details>
<summary><b>Как часто обновляется список IP?</b></summary>

По умолчанию — раз в сутки через cron. Можно настроить чаще или запускать вручную.

</details>

<details>
<summary><b>Что если Tor заблокирован в моей стране?</b></summary>

Используйте мосты (bridges). Установщик предложит настроить obfs4 или webtunnel мосты для обхода блокировок.

</details>

---

## 🙏 Благодарности

Этот проект является форком [Limych/antizapret](https://github.com/Limych/antizapret).

Огромная благодарность автору оригинального проекта за создание основы!

---

## 💖 Поддержать проект

Если проект оказался полезен, вы можете поддержать его развитие:

<div align="center">

### 💵 USDT (TRC20)

<img src="https://img.shields.io/badge/USDT-TRC20-26A17B?style=for-the-badge&logo=tether&logoColor=white" alt="USDT TRC20"/>

```
TCyZuUjX3ymFmrDPxTmeSNPMuuWRDtviFy
```

<img src="https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=TCyZuUjX3ymFmrDPxTmeSNPMuuWRDtviFy" alt="USDT QR Code" width="200"/>

---

*Спасибо за вашу поддержку! ❤️*

</div>

---

<div align="center">

**[⬆ Вернуться наверх](#-antizapret-для-opnsensefreebsd)**

<sub>Made with ❤️ for internet freedom</sub>

</div>
