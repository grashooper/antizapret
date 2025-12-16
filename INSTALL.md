# Автоматическая установка AntiZapret

Интерактивный скрипт для автоматической установки и настройки AntiZapret на OPNsense/FreeBSD.

## Возможности скрипта

- Автоматическое определение системы (FreeBSD версия и архитектура)
- Автоматическое определение локального IP адреса
- Поиск актуальных версий пакетов из репозитория FreeBSD
- Установка всех необходимых компонентов:
  - Tor
  - obfs4proxy
  - webtunnel
  - AntiZapret скрипты
- Интерактивная настройка мостов (bridges)
- Автоматическая настройка конфигурации Tor
- Настройка автозапуска
- Интеграция с OPNsense

## Требования

- FreeBSD 13+ или OPNsense 21+
- Права root
- Подключение к интернету
- Tor bridges (можно получить на https://bridges.torproject.org/)

## Использование

### Шаг 1: Загрузка

Подключитесь к консоли OPNsense/FreeBSD через SSH или прямой доступ.

```bash
cd /root
fetch https://raw.githubusercontent.com/grashooper/antizapret/master/install.sh
chmod +x install.sh
```

Или клонируйте репозиторий:

```bash
cd /root
git clone https://github.com/grashooper/antizapret.git
cd antizapret
chmod +x install.sh
```

### Шаг 2: Получение мостов

Перед запуском скрипта получите Tor bridges:

1. Посетите https://bridges.torproject.org/
2. Выберите тип моста: obfs4 и/или webtunnel
3. Скопируйте строки с мостами

Или отправьте email на bridges@torproject.org с темой "get transport obfs4"

### Шаг 3: Запуск установки

```bash
./install.sh
```

Скрипт выполнит следующие действия:

1. Проверит права root
2. Определит систему и архитектуру
3. Определит локальный IP адрес (с возможностью ручного ввода)
4. Установит необходимые пакеты
5. Запросит ввод bridge-линий для obfs4 и webtunnel
6. Настроит Tor конфигурацию
7. Настроит автозапуск
8. Установит скрипты обновления IP списков
9. Интегрируется с OPNsense (если применимо)
10. Запустит Tor

### Шаг 4: Настройка файрвола

После установки необходимо настроить правила в веб-интерфейсе OPNsense:

#### 4.1. Создание алиаса

`Firewall > Aliases`

- Name: `AntiZapret_IPs`
- Type: `External (advanced)`
- Content: URL вашего файрвола (скрипт подскажет адрес)

#### 4.2. Настройка NAT

`Firewall > NAT > Port Forward`

Создайте правило:
- Interface: `LAN`
- Protocol: `TCP`
- Destination: `AntiZapret_IPs`
- Destination port range: `any`
- Redirect target IP: `127.0.0.1`
- Redirect target port: `9040`
- Description: `AntiZapret`

#### 4.3. Настройка автоматического обновления

`System > Settings > Cron`

Добавьте задачу:
- Command: `Renew AntiZapret IP-list`
- Расписание: ежедневно в удобное время

## Проверка работы

### Проверить статус Tor

```bash
ps aux | grep tor
```

### Просмотр логов

```bash
tail -f /var/log/tor/notices.log
```

### Перезапуск Tor

```bash
pkill tor
/usr/local/bin/tor
```

### Обновление списка IP

```bash
/root/antizapret/antizapret.pl
```

## Файлы конфигурации

- Tor config: `/usr/local/etc/tor/torrc`
- IP список: `/usr/local/www/ipfw_antizapret.dat`
- Автозапуск: `/usr/local/etc/rc.d/tor.sh`
- OPNsense actions: `/usr/local/opnsense/service/conf/actions.d/actions_antizapret.conf`

## Устранение неполадок

### Tor не запускается

Проверьте логи:
```bash
tail -100 /var/log/tor/notices.log
```

Проверьте конфигурацию:
```bash
tor --verify-config
```

### Bridges не работают

1. Убедитесь, что bridges введены правильно в `/usr/local/etc/tor/torrc`
2. Попробуйте получить новые bridges
3. Проверьте, что obfs4proxy и webtunnel установлены:
   ```bash
   which obfs4proxy
   which webtunnel-tor-client
   ```

### Ошибка "Invalid argument" при создании алиаса

Увеличьте лимит таблиц файрвола:
`Firewall > Settings > Advanced`
- Найдите `Firewall Maximum Table Entries`
- Установите значение `200000`

## Ручная установка

Если автоматический скрипт не подходит, следуйте инструкциям:
- [Настройка с Tor](TOR.md)
- [Настройка с WireGuard](WireGuard.md)

## Обновление

Для обновления скриптов AntiZapret:

```bash
cd /root/antizapret
git pull
```

## Удаление

```bash
pkill tor
rm -rf /root/antizapret
rm -f /usr/local/etc/rc.d/tor.sh
rm -f /usr/local/etc/tor/torrc
rm -f /usr/local/www/ipfw_antizapret.dat
rm -f /usr/local/opnsense/service/conf/actions.d/actions_antizapret.conf
pkg delete tor obfs4proxy-tor webtunnel-tor
```

## Поддержка

Если у вас возникли проблемы:

1. Проверьте логи Tor
2. Убедитесь, что все пакеты установлены
3. Проверьте конфигурацию файрвола
4. Создайте issue на GitHub

## Лицензия

MIT License - см. файл LICENSE
