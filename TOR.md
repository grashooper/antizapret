# AntiZapret

Прозрачный обход блокировок для локальной сети.

Мне это решение особенно нравится тем, что оно корректно отрабатывает любой трафик. В том числе и HTTPS. При этом никаких настроек на клиентах делать не надо.

Система отлично работает с роутерами на базе **OPNsense** (на роутерах на базе **pfSense** не проверял, но также должно работать без проблем). Возможно, также будет работать с другими роутерами, т.к. используются только базовые возможности файрвола.

## Установка и настройка с использованием TOR + obfs4 + webtunnel

*Обновлено в 2025:* Этот метод снова работает благодаря использованию obfs4-мостов и webtunnel для обхода блокировок самого TOR.

### Быстрая установка (рекомендуется)

Для автоматической установки используйте интерактивный скрипт:

```bash
cd /root
git clone https://github.com/grashooper/antizapret.git
cd antizapret
chmod +x install.sh
./install.sh
```

Скрипт автоматически установит все необходимые компоненты, включая Tor, obfs4proxy и webtunnel. Подробная инструкция: [INSTALL.md](INSTALL.md)

### Ручная установка

*NB.* Для настройки системы понадобится доступ к командной строке через консоль или SSH. Все команды надо исполнять от имени **root**, т.к. иначе часть не сработает!

1.  Установите Tor и необходимые транспорты.

    **Для FreeBSD/OPNsense (прямая установка):**

    ```bash
    pkg install nano
    pkg add https://pkg.freebsd.org/FreeBSD:14:amd64/latest/All/zstd-1.5.6.pkg
    pkg add https://pkg.freebsd.org/FreeBSD:14:amd64/latest/All/tor-0.4.8.12.pkg
    pkg add https://pkg.freebsd.org/FreeBSD:14:amd64/latest/All/obfs4proxy-tor-0.0.14_17.pkg
    pkg add https://pkg.freebsd.org/FreeBSD:14:amd64/latest/All/webtunnel-tor-0.0.1_10.pkg
    ```

    *Примечание:* Версии пакетов могут измениться. Проверьте актуальные на https://pkg.freebsd.org/

    **Для OPNsense (через плагин, устаревший метод без obfs4):**\
    Установите плагин `os-tor` через вкладку *System > Firmware > Plugins*.\
    *Внимание:* Этот метод не поддерживает obfs4 и может не работать из-за блокировок TOR.

2.  Настройте Tor конфигурацию.

    Удалите старую конфигурацию:
    ```bash
    rm -rf /usr/local/etc/tor/torrc
    ```

    Создайте новую конфигурацию `/usr/local/etc/tor/torrc`:
    ```
    DNSPort 192.168.1.1:53
    VirtualAddrNetworkIPv4 10.192.0.0/10
    AutomapHostsOnResolve 1
    RunAsDaemon 1
    TransPort 9040
    ExcludeNodes {RU}, {BY}, {KG}, {KZ}, {UZ}, {TJ}, {TM}, {TR}, {AZ}, {AM}
    ExcludeExitNodes {RU}, {BY}, {KG}, {KZ}, {UZ}, {TJ}, {TM}, {TR}, {AZ}, {AM}
    HeartbeatPeriod 1 hours
    ExitRelay 0

    ClientTransportPlugin obfs4 exec /usr/local/bin/obfs4proxy managed
    ClientTransportPlugin webtunnel exec /usr/local/bin/webtunnel-tor-client

    UseBridges 1

    Bridge obfs4 [ваш мост]
    Bridge webtunnel [ваш мост]
    ```

    Замените `192.168.1.1` на IP адрес вашего роутера в локальной сети.

    Получите мосты на https://bridges.torproject.org/ или отправьте email на bridges@torproject.org

3.  Настройте автозапуск Tor.

    ```bash
    cd /usr/local/etc/rc.d/
    touch ./tor.sh
    echo "/usr/local/bin/tor" >> tor.sh
    chmod +x tor.sh
    ```

4.  Установите скрипты AntiZapret.

    ```bash
    cd /root
    git clone https://github.com/grashooper/antizapret.git
    cd antizapret
    ```

5.  Настройте правила файрвола.

    **Для OPNsense ...**\
    сначала в настройках файрвола на вкладке *Firewall > Aliases* создайте алиас для удобства использования списка.\
    Name = *AntiZapret_IPs*\
    Type = *External (advanced)*\
    
    Дальше на вкладке *Firewall > NAT > Port Forward* создаём новое правило:\
    Interface = *LAN*\
    Protocol = *TCP*\
    Destination = *AntiZapret_IPs*\
    Destination port range = *any*\
    Redirect target IP = *127.0.0.1* (адрес, где запущен Tor; в данном случае — та же машина)\
    Redirect target port = *9040* (порт, на котором Tor принимает запросы как прозрачный прокси)\
    Description = *AntiZapret*
   
    **Для других систем ...**\
    к сожалению, точно описать настройку не могу. Но нужно сделать всё по-аналогии.

6.  Настройте регулярное обновление списков блокировки.

    **Для OPNsense ...**\
    просто запустите скрипт
    ```bash
    sh opnsense/install.sh
    ```
    После этого в настройках cron (*System > Settings > Cron*) добавить новую задачу на ежесуточное обновление списка:\
    Command = *Renew AntiZapret IP-list*.
   
    **Для других систем ...**\
    необходимо в cron добавить что-то типа
    ```
    0   0   *   *   *   /root/antizapret/antizapret.pl | tee /usr/local/www/ipfw_antizapret.dat | xargs pfctl -t AntiZapret_IPs -T add
    ```
    после, чтобы не ждать сутки первого обновления списка, в консоле исполняем команду
    ```
    /root/antizapret/antizapret.pl | tee /usr/local/www/ipfw_antizapret.dat | xargs pfctl -t AntiZapret_IPs -T add
    ```

7.  Запустите Tor.

    ```bash
    /usr/local/bin/tor
    ```

8.  Всё. :)
    
    Через некоторое время система сама подгрузит список и файрвол начнёт прозрачно перенаправлять любые обращения к заблокированным сайтам на Tor. В то же время весь прочий трафик будет идти напрямую, как обычно.

При необходимости вы всегда можете получать список заблокированных адресов со своего файрволла по адресу `https://<firewall_ip>/ipfw_antizapret.dat`

## Troubleshooting

Если при создании алиаса вы получили сообщение `Invalid argument`, загляните на вкладку *Firewall> Settings> Advanced*, найдите там поле *Firewall Maximum Table Entries* и измените его значение.

Известно, что на версии OPNsense v21.1 был явный баг: при значении по-умолчанию мы имели почему-то лимит в 32 768 адресов (хотя в справке написано, что по-умолчанию он 200 000 записей). Если явно указать там лимит в 200 000 записей, по факту он был 131 072 записи...
