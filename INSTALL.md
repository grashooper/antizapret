# 📘 Полное руководство по установке

Подробная инструкция по установке и настройке AntiZapret на OPNsense/FreeBSD.

---

## 📋 Содержание

- [Требования](#-требования)
- [Подготовка](#-подготовка)
- [Установка](#-установка)
- [Настройка OPNsense](#-настройка-opnsense)
- [Проверка работы](#-проверка-работы)
- [Дополнительная настройка](#-дополнительная-настройка)
- [Решение проблем](#-решение-проблем)
- [Обновление](#-обновление)
- [Удаление](#-удаление)

---

## 📌 Требования

### Системные требования

| Компонент | Минимум | Рекомендуется |
|-----------|---------|---------------|
| **ОС** | FreeBSD 13.x | FreeBSD 14.x |
| **Платформа** | OPNsense 23.x | OPNsense 24.x |
| **RAM** | 512 MB свободно | 1 GB свободно |
| **Диск** | 100 MB свободно | 500 MB свободно |
| **Архитектура** | amd64, arm64 | amd64 |

### Сетевые требования

- ✅ Доступ в интернет с роутера
- ✅ Возможность подключения к Tor (или наличие мостов)
- ✅ SSH-доступ к роутеру

### Необходимые знания

- 🔧 Базовые навыки работы с командной строкой
- 🌐 Понимание основ сетевых настроек
- 🛡️ Доступ к веб-интерфейсу OPNsense

---

## 🔧 Подготовка

### 1. Подключение к роутеру

#### Через SSH (рекомендуется)

```bash
ssh root@192.168.1.1
```

> 💡 Замените `192.168.1.1` на IP вашего роутера

#### Через консоль OPNsense

1. Откройте веб-интерфейс OPNsense
2. Перейдите в **System → Settings → Administration**
3. Включите **Enable Secure Shell**
4. Подключитесь по SSH

### 2. Проверка доступа в интернет

```bash
# Проверка DNS
host google.com

# Проверка HTTP
fetch -qo /dev/null https://www.google.com && echo "OK" || echo "FAIL"
```

### 3. Проверка свободного места

```bash
df -h /
```

Убедитесь, что свободно минимум 100 MB.

---

## 📦 Установка

### Автоматическая установка (рекомендуется)

#### Шаг 1: Клонирование репозитория

```bash
cd /root
git clone https://github.com/grashooper/antizapret.git
cd antizapret
```

#### Шаг 2: Запуск установщика

```bash
chmod +x install.sh
./install.sh
```

#### Шаг 3: Ответы на вопросы установщика

```
┌─────────────────────────────────────────────────────────────────────────┐
│                      Интерактивные вопросы                              │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  ? Use this IP address? [Y/n]                                           │
│    └─ Y — если автоопределённый IP верен                                │
│    └─ n — чтобы ввести другой IP                                        │
│                                                                         │
│  ? Package selection [A]:                                               │
│    └─ A — установить все опциональные пакеты                            │
│    └─ 1 2 3 — выбрать конкретные пакеты                                 │
│    └─ 0 — не устанавливать опциональные пакеты                          │
│                                                                         │
│  ? Enable IPv6 support? [Y/n]                                           │
│    └─ Y — включить IPv6 (рекомендуется)                                 │
│    └─ n — отключить IPv6                                                │
│                                                                         │
│  ? Configure Tor bridges? [y/N]                                         │
│    └─ N — прямое подключение к Tor                                      │
│    └─ y — настроить мосты (если Tor заблокирован)                       │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

### Ручная установка

<details>
<summary>📖 <b>Развернуть инструкцию по ручной установке</b></summary>

#### 1. Установка пакетов

```bash
# Базовые пакеты
pkg install -y tor obfs4proxy-tor webtunnel-tor

# Опциональные пакеты
pkg install -y mc git curl wget nano
```

#### 2. Создание директорий

```bash
mkdir -p /var/log/tor /var/run/tor
chown _tor:_tor /var/log/tor /var/run/tor
```

#### 3. Настройка torrc

```bash
cat > /usr/local/etc/tor/torrc << 'EOF'
# Logging
Log notice file /var/log/tor/notices.log

# DNS
DNSPort 127.0.0.1:9053
DNSPort 192.168.1.1:9053

# Virtual addresses
VirtualAddrNetworkIPv4 10.192.0.0/10
AutomapHostsOnResolve 1

# Daemon
RunAsDaemon 1

# SOCKS
SocksPort 127.0.0.1:9050
SocksPort 192.168.1.1:9050

# Transparent proxy
TransPort 9040

# Exit policy
ExitPolicy reject *:*
ExitPolicy reject6 *:*
ExitRelay 0

# Excluded nodes
ExcludeNodes {RU}, {BY}, {KG}, {KZ}, {UZ}, {TJ}, {TM}, {TR}, {AZ}, {AM}
ExcludeExitNodes {RU}, {BY}, {KG}, {KZ}, {UZ}, {TJ}, {TM}, {TR}, {AZ}, {AM}
StrictNodes 1

# Transport plugins
ClientTransportPlugin obfs4 exec /usr/local/bin/obfs4proxy managed
ClientTransportPlugin webtunnel exec /usr/local/bin/webtunnel-tor-client

# IPv6
ClientUseIPv6 1
ClientUseIPv4 1
ClientPreferIPv6ORPort 1

# Bridges (disabled by default)
UseBridges 0
EOF
```

> ⚠️ Замените `192.168.1.1` на IP вашего роутера

#### 4. Настройка автозапуска

```bash
sysrc tor_enable="YES"
```

#### 5. Установка AntiZapret

```bash
cd /root
git clone https://github.com/grashooper/antizapret.git
chmod +x /root/antizapret/antizapret.pl
```

#### 6. Создание списка IP

```bash
/root/antizapret/antizapret.pl > /usr/local/www/ipfw_antizapret.dat
```

#### 7. Запуск Tor

```bash
service tor start
```

</details>

---

## 🖥️ Настройка OPNsense

После завершения установки необходимо настроить OPNsense через веб-интерфейс.

### 1️⃣ Создание Firewall Alias

#### Путь: Firewall → Aliases → Add

| Параметр | Значение |
|----------|----------|
| **Enabled** | ✅ |
| **Name** | `AntiZapret_IPs` |
| **Type** | External (advanced) |
| **Content** | `https://192.168.1.1/ipfw_antizapret.dat` |
| **Description** | AntiZapret blocked IP addresses |

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         Firewall Alias                                  │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  Name:        [AntiZapret_IPs                    ]                      │
│                                                                         │
│  Type:        [External (advanced)           ▼]                         │
│                                                                         │
│  Content:     [https://192.168.1.1/ipfw_antizapret.dat]                 │
│                                                                         │
│  Description: [AntiZapret blocked IP addresses   ]                      │
│                                                                         │
│                                              [Save] [Cancel]            │
└─────────────────────────────────────────────────────────────────────────┘
```

> ⚠️ Замените `192.168.1.1` на IP вашего роутера

#### После сохранения:
1. Нажмите **Apply Changes**
2. Перейдите в **Firewall → Diagnostics → Aliases**
3. Найдите `AntiZapret_IPs` и нажмите 🔄 для обновления

### 2️⃣ Создание NAT Port Forward

#### Путь: Firewall → NAT → Port Forward → Add

| Параметр | Значение |
|----------|----------|
| **Interface** | LAN |
| **TCP/IP Version** | IPv4 |
| **Protocol** | TCP |
| **Source** | any |
| **Destination** | AntiZapret_IPs |
| **Destination port range** | any |
| **Redirect target IP** | 127.0.0.1 |
| **Redirect target port** | 9040 |
| **Description** | AntiZapret transparent proxy |

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         NAT Port Forward                                │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  Interface:               [LAN                           ▼]            │
│  TCP/IP Version:          [IPv4                          ▼]            │
│  Protocol:                [TCP                           ▼]            │
│                                                                         │
│  ─── Source ───────────────────────────────────────────────────────    │
│  Source:                  [any                           ▼]            │
│                                                                         │
│  ─── Destination ──────────────────────────────────────────────────    │
│  Destination:             [AntiZapret_IPs                ▼]            │
│  Destination port range:  [any            ] to [any            ]       │
│                                                                         │
│  ─── Redirect target ──────────────────────────────────────────────    │
│  Redirect target IP:      [127.0.0.1                     ]             │
│  Redirect target port:    [9040                          ]             │
│                                                                         │
│  ─── Misc ─────────────────────────────────────────────────────────    │
│  Description:             [AntiZapret transparent proxy  ]             │
│                                                                         │
│                                              [Save] [Cancel]            │
└─────────────────────────────────────────────────────────────────────────┘
```

#### После сохранения:
1. Нажмите **Apply Changes**

### 3️⃣ Настройка Cron для обновления списков

#### Путь: System → Settings → Cron → Add

| Параметр | Значение |
|----------|----------|
| **Enabled** | ✅ |
| **Minutes** | 0 |
| **Hours** | 4 |
| **Day of month** | * |
| **Month** | * |
| **Day of week** | * |
| **Command** | Renew AntiZapret IP-list |
| **Description** | Daily AntiZapret update |

```
┌─────────────────────────────────────────────────────────────────────────┐
│                            Cron Job                                     │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  Enabled:       [✓]                                                     │
│                                                                         │
│  Minutes:       [0          ]                                           │
│  Hours:         [4          ]                                           │
│  Day of month:  [*          ]                                           │
│  Month:         [*          ]                                           │
│  Day of week:   [*          ]                                           │
│                                                                         │
│  Command:       [Renew AntiZapret IP-list                    ▼]        │
│                                                                         │
│  Description:   [Daily AntiZapret update     ]                          │
│                                                                         │
│                                              [Save] [Cancel]            │
└─────────────────────────────────────────────────────────────────────────┘
```

> 💡 Список будет обновляться каждый день в 4:00 утра

---

## ✅ Проверка работы

### Проверка статуса Tor

```bash
service tor status
```

✅ Ожидаемый вывод:
```
tor is running as pid 12345.
```

### Проверка подключения к сети Tor

```bash
grep "Bootstrapped 100%" /var/log/tor/notices.log
```

✅ Ожидаемый вывод:
```
[notice] Bootstrapped 100% (done): Done
```

### Проверка открытых портов

```bash
sockstat -4l | grep tor
```

✅ Ожидаемый вывод:
```
_tor     tor      12345 6  tcp4   192.168.1.1:9050    *:*
_tor     tor      12345 7  tcp4   127.0.0.1:9050      *:*
_tor     tor      12345 8  tcp4   192.168.1.1:9053    *:*
_tor     tor      12345 9  tcp4   127.0.0.1:9053      *:*
_tor     tor      12345 10 tcp4   *:9040              *:*
```

### Проверка списка IP

```bash
# Количество IP в списке
wc -l /usr/local/www/ipfw_antizapret.dat

# Первые 10 IP
head -10 /usr/local/www/ipfw_antizapret.dat
```

### Проверка работы прокси

```bash
# Через SOCKS-прокси
curl --socks5 127.0.0.1:9050 https://check.torproject.org/api/ip

# Ожидаемый вывод (ваш Tor IP)
{"IsTor":true,"IP":"xxx.xxx.xxx.xxx"}
```

### Проверка с клиентского устройства

1. Подключите устройство к сети через роутер
2. Откройте браузер
3. Перейдите на ранее заблокированный сайт
4. Сайт должен открыться без дополнительных настроек

---

## ⚙️ Дополнительная настройка

### Настройка мостов Tor

Если Tor заблокирован в вашей сети, используйте мосты.

#### Получение мостов

1. Перейдите на https://bridges.torproject.org/
2. Выберите тип транспорта:
   - **obfs4** — рекомендуется для большинства случаев
   - **webtunnel** — выглядит как HTTPS-трафик
3. Скопируйте bridge-строки

#### Добавление мостов в конфигурацию

```bash
nano /usr/local/etc/tor/torrc
```

Найдите секцию `BRIDGE CONFIGURATION` и измените:

```ini
# ─────────────────────────────────────────────────────────────────────────────
# BRIDGE CONFIGURATION
# ─────────────────────────────────────────────────────────────────────────────
UseBridges 1

# OBFS4 bridges
Bridge obfs4 192.0.2.1:443 FINGERPRINT cert=CERTIFICATE iat-mode=0
Bridge obfs4 192.0.2.2:9001 FINGERPRINT cert=CERTIFICATE iat-mode=0

# WebTunnel bridges
Bridge webtunnel 192.0.2.3:443 FINGERPRINT url=https://example.com/path
```

Перезапустите Tor:

```bash
service tor restart
```

### Изменение страны выхода

По умолчанию используются узлы из любых не-СНГ стран. Чтобы указать конкретную страну:

```bash
nano /usr/local/etc/tor/torrc
```

Добавьте или раскомментируйте:

```ini
# Использовать только польские exit-ноды
ExitNodes {PL}
```

Коды стран:
| Код | Страна |
|-----|--------|
| {US} | США |
| {DE} | Германия |
| {NL} | Нидерланды |
| {PL} | Польша |
| {SE} | Швеция |
| {CH} | Швейцария |

### Настройка DNS через Tor

По умолчанию DNS-запросы к заблокированным доменам также идут через Tor. Для использования Tor DNS для всех запросов:

#### OPNsense: Services → Unbound DNS → General

| Параметр | Значение |
|----------|----------|
| **Custom options** | `forward-zone: name: "." forward-addr: 127.0.0.1@9053` |

### Добавление своих IP в список

```bash
# Добавить IP вручную
echo "1.2.3.4" >> /usr/local/www/ipfw_antizapret.dat

# Добавить подсеть
echo "1.2.3.0/24" >> /usr/local/www/ipfw_antizapret.dat

# Обновить alias в OPNsense
pfctl -t AntiZapret_IPs -T add 1.2.3.4
```

---

## 🔧 Решение проблем

### Tor не запускается

#### Проверка конфигурации

```bash
tor --verify-config
```

#### Частые ошибки

| Ошибка | Решение |
|--------|---------|
| `Permission denied` | `chown -R _tor:_tor /var/log/tor /var/run/tor` |
| `Address already in use` | Другой процесс занял порт: `sockstat -4l \| grep 9050` |
| `Could not bind to address` | Проверьте IP-адрес в torrc |

### Tor не подключается к сети

#### Проверка логов

```bash
tail -50 /var/log/tor/notices.log
```

#### Возможные причины

| Симптом | Причина | Решение |
|---------|---------|---------|
| `Connection refused` | Tor заблокирован | Настройте мосты |
| `Timeout` | Сетевые проблемы | Проверьте интернет |
| `No route to host` | Проблемы с маршрутизацией | Проверьте настройки сети |

### Сайты не открываются

#### Чеклист

- [ ] Tor запущен: `service tor status`
- [ ] Tor подключён: `grep "Bootstrapped 100%" /var/log/tor/notices.log`
- [ ] Alias обновлён: проверьте в OPNsense
- [ ] NAT правило активно: проверьте в OPNsense
- [ ] IP сайта в списке: `grep "IP_АДРЕС" /usr/local/www/ipfw_antizapret.dat`

### Ошибка обновления списка IP

```bash
# Проверка скрипта
/root/antizapret/antizapret.pl

# Проверка доступа к источнику
fetch -qo - "https://raw.githubusercontent.com/zapret-info/z-i/master/dump.csv" | head
```

---

## 🔄 Обновление

### Обновление AntiZapret

```bash
cd /root/antizapret
git pull
chmod +x install.sh
```

### Обновление списка IP вручную

```bash
/root/antizapret/antizapret.pl > /usr/local/www/ipfw_antizapret.dat

# Обновить alias в памяти
pfctl -t AntiZapret_IPs -T replace -f /usr/local/www/ipfw_antizapret.dat
```

### Обновление Tor

```bash
pkg update
pkg upgrade tor obfs4proxy-tor webtunnel-tor
service tor restart
```

---

## 🗑️ Удаление

### Полное удаление AntiZapret

```bash
# Остановка Tor
service tor stop

# Отключение автозапуска
sysrc -x tor_enable

# Удаление пакетов
pkg delete -y tor obfs4proxy-tor webtunnel-tor

# Удаление файлов
rm -rf /root/antizapret
rm -f /usr/local/www/ipfw_antizapret.dat
rm -f /usr/local/etc/tor/torrc
rm -rf /var/log/tor
rm -rf /var/run/tor

# Удаление OPNsense actions
rm -f /usr/local/opnsense/service/conf/actions.d/actions_antizapret.conf
rm -f /usr/local/opnsense/service/conf/actions.d/actions_tor.conf
service configd restart
```

### В OPNsense GUI

1. **Firewall → NAT → Port Forward** — удалите правило AntiZapret
2. **Firewall → Aliases** — удалите AntiZapret_IPs
3. **System → Settings → Cron** — удалите задание обновления

---

## 📚 Дополнительные ресурсы

| Ресурс | Описание |
|--------|----------|
| [README.md](README.md) | Общее описание проекта |
| [QUICKSTART.md](QUICKSTART.md) | Быстрый старт |
| [FEATURES.md](FEATURES.md) | Полный список возможностей |
| [FAQ.md](FAQ.md) | Часто задаваемые вопросы |
| [TOR.md](TOR.md) | Подробнее о настройке Tor |
| [WireGuard.md](WireGuard.md) | Альтернатива с WireGuard |
| [CHANGELOG.md](CHANGELOG.md) | История изменений |

---

## 💖 Поддержать проект

Если AntiZapret оказался полезен:

<div align="center">

**USDT (TRC20)**

```
TCyZuUjX3ymFmrDPxTmeSNPMuuWRDtviFy
```

</div>

---

<div align="center">

Основано на [Limych/antizapret](https://github.com/Limych/antizapret)

**[⬆ Вернуться наверх](#-полное-руководство-по-установке)**

</div>
