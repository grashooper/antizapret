# 🚀 Быстрый старт

Установка AntiZapret на OPNsense/FreeBSD за 2 минуты.

---

## ⚡ Установка в одну команду

```bash
cd /root && git clone https://github.com/grashooper/antizapret.git && cd antizapret && chmod +x install.sh && ./install.sh
```

---

## 📋 Пошаговая установка

### Шаг 1: Подключение к роутеру

```bash
ssh root@192.168.1.1
```

> 💡 Замените `192.168.1.1` на IP-адрес вашего роутера

### Шаг 2: Клонирование репозитория

```bash
cd /root
git clone https://github.com/grashooper/antizapret.git
```

### Шаг 3: Запуск установщика

```bash
cd antizapret
chmod +x install.sh
./install.sh
```

### Шаг 4: Следуйте инструкциям

Установщик задаст несколько вопросов:

| Вопрос | Рекомендация |
|--------|--------------|
| Use this IP address? | **Y** (если IP определён верно) |
| Package selection | **A** (все пакеты) или **0** (только Tor) |
| Enable IPv6? | **Y** (для большинства сетей) |
| Configure bridges? | **N** (если Tor не заблокирован) |

---

## ⚙️ Настройка OPNsense (после установки)

### 1️⃣ Создание Alias

```
Firewall → Aliases → Add

┌─────────────────────────────────────────────────────┐
│ Name:         AntiZapret_IPs                        │
│ Type:         External (advanced)                   │
│ Content:      https://YOUR_IP/ipfw_antizapret.dat   │
└─────────────────────────────────────────────────────┘
```

### 2️⃣ Настройка NAT

```
Firewall → NAT → Port Forward → Add

┌─────────────────────────────────────────────────────┐
│ Interface:            LAN                           │
│ Protocol:             TCP                           │
│ Destination:          AntiZapret_IPs                │
│ Redirect target IP:   127.0.0.1                     │
│ Redirect target port: 9040                          │
└─────────────────────────────────────────────────────┘
```

### 3️⃣ Настройка Cron

```
System → Settings → Cron → Add

┌─────────────────────────────────────────────────────┐
│ Command:    Renew AntiZapret IP-list                │
│ Hours:      4                                       │
│ Minutes:    0                                       │
│ Days:       *                                       │
└─────────────────────────────────────────────────────┘
```

---

## ✅ Проверка работы

### Статус Tor

```bash
service tor status
```

Ожидаемый вывод:
```
tor is running as pid 12345.
```

### Проверка портов

```bash
sockstat -4l | grep -E "9050|9053|9040"
```

Ожидаемый вывод:
```
_tor     tor        12345 6  tcp4   192.168.1.1:9050  *:*
_tor     tor        12345 7  tcp4   127.0.0.1:9053    *:*
_tor     tor        12345 8  tcp4   *:9040            *:*
```

### Проверка списка IP

```bash
wc -l /usr/local/www/ipfw_antizapret.dat
```

Ожидаемый вывод:
```
18742 /usr/local/www/ipfw_antizapret.dat
```

---

## 🔧 Полезные команды

| Команда | Описание |
|---------|----------|
| `service tor start` | Запустить Tor |
| `service tor stop` | Остановить Tor |
| `service tor restart` | Перезапустить Tor |
| `tail -f /var/log/tor/notices.log` | Просмотр логов |
| `/root/antizapret/antizapret.pl` | Обновить список IP |

---

## ❓ Проблемы?

### Tor не запускается

```bash
# Проверьте конфигурацию
tor --verify-config

# Просмотрите логи
cat /var/log/tor/notices.log
```

### Нет доступа к сайтам

```bash
# Проверьте, что Tor подключился к сети
grep -i "Bootstrapped 100%" /var/log/tor/notices.log
```

### Нужны мосты?

Перезапустите установщик и выберите "Configure bridges":

```bash
cd /root/antizapret
./install.sh
```

---

## 📚 Дополнительно

- 📖 [Полная инструкция](INSTALL.md)
- 🔧 [Все возможности](FEATURES.md)
- ❓ [FAQ](FAQ.md)
- 📺 [Пример установки](DEMO.txt)

---

## 💖 Поддержать проект

**USDT (TRC20)**
```
TCyZuUjX3ymFmrDPxTmeSNPMuuWRDtviFy
```

---

<div align="center">

Основано на [Limych/antizapret](https://github.com/Limych/antizapret)

**[⬆ Вернуться наверх](#-быстрый-старт)**

</div>
