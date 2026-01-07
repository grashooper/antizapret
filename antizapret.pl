#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';
use File::Basename;
use Getopt::Std;

$| = 1;

# Обработка флагов командной строки: -d для включения режима отладки
my %opts;
getopts('d', \%opts);
my $debug = $opts{d} || 0;

# Директория, в которой находится скрипт
my $scriptdir = dirname(__FILE__);

print "Скрипт запущен в " . localtime() . "\n" if $debug;

# Пути к временным файлам
my $temp_gz = '/tmp/dump.csv.gz';
my $temp_csv = '/tmp/dump.csv';

# URL для загрузки gzipped CSV файла
my $url = 'https://raw.githubusercontent.com/zapret-info/z-i/master/dump.csv.gz';
my $host = 'raw.githubusercontent.com';

# GitHub IP адреса для обхода DNS
my @github_ips = (
    '185.199.108.133',
    '185.199.109.133',
    '185.199.110.133',
    '185.199.111.133',
);

# Таймауты
my $connect_timeout = 15;
my $max_timeout = 120;

# Функция для загрузки файла
sub download_file {
    my ($url, $output, $use_ip, $ip) = @_;
    
    # Поиск доступной утилиты для загрузки
    my $which_output = `which curl fetch wget 2>/dev/null`;
    my $downloader = '';
    
    if ($which_output =~ /(\/\S*curl)/) {
        $downloader = 'curl';
    } elsif ($which_output =~ /(\/\S*fetch)/) {
        $downloader = 'fetch';
    } elsif ($which_output =~ /(\/\S*wget)/) {
        $downloader = 'wget';
    } else {
        die "ERROR: Не удается найти программу для загрузки данных (curl/fetch/wget).";
    }
    
    my $cmd;
    
    if ($use_ip && $ip && $downloader eq 'curl') {
        # Загрузка через IP (обход DNS)
        $cmd = "curl -s --connect-timeout $connect_timeout --max-time $max_timeout " .
               "--resolve '${host}:443:${ip}' -o '$output' '$url' 2>/dev/null";
    } else {
        # Обычная загрузка
        if ($downloader eq 'curl') {
            $cmd = "curl -s --connect-timeout $connect_timeout --max-time $max_timeout -o '$output' '$url' 2>/dev/null";
        } elsif ($downloader eq 'fetch') {
            $cmd = "fetch -T $connect_timeout -q -o '$output' '$url' 2>/dev/null";
        } elsif ($downloader eq 'wget') {
            $cmd = "wget --timeout=$connect_timeout -q -O '$output' '$url' 2>/dev/null";
        }
    }
    
    print "Выполнение: $cmd\n" if $debug;
    my $result = system($cmd);
    
    return ($result == 0 && -s $output);
}

# Определение способа получения данных
if (@ARGV) {
    # Если файл передан как аргумент, использовать его напрямую
    $temp_csv = $ARGV[0];
    print "Используется указанный файл: $temp_csv\n" if $debug;
}
else {
    my $download_success = 0;
    
    # Попытка 1: Прямая загрузка
    print "Попытка прямой загрузки с $url\n" if $debug;
    if (download_file($url, $temp_gz, 0, undef)) {
        print "Файл успешно загружен напрямую\n" if $debug;
        $download_success = 1;
    }
    
    # Попытка 2: Загрузка через IP (если прямая не удалась)
    if (!$download_success) {
        print "Прямая загрузка не удалась, пробуем через IP...\n" if $debug;
        
        foreach my $ip (@github_ips) {
            print "Попытка загрузки через IP: $ip\n" if $debug;
            if (download_file($url, $temp_gz, 1, $ip)) {
                print "Файл успешно загружен через IP $ip\n" if $debug;
                $download_success = 1;
                last;
            }
        }
    }
    
    # Проверка успешности загрузки
    if (!$download_success) {
        die "ERROR: Не удалось загрузить файл ни напрямую, ни через IP.";
    }
    
    # Автоматическая распаковка gzipped файла
    print "Распаковка файла $temp_gz в $temp_csv\n" if $debug;
    system("gunzip -c $temp_gz > $temp_csv") == 0 or die "ERROR: Не удалось распаковать файл.";
    print "Файл успешно распакован в $temp_csv\n" if $debug;
}

# Функция для проверки, является ли строка IPv4 адресом
sub is_ipv4 {
    my ($ip) = @_;
    return $ip =~ /^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/;
}

# Чтение данных из CSV файла
open my $csv_fh, '<', $temp_csv or die "ERROR: Не удается открыть $temp_csv: $!";
my $header = <$csv_fh>;  # Пропуск строки заголовка
my @entries;
while (my $line = <$csv_fh>) {
    chomp $line;
    my ($first_field) = split /;/, $line, 2;  # Извлечение первого поля
    my @parts = map { s/^\s+|\s+$//g; $_ } split /\|/, $first_field;  # Разделение по "|" и очистка пробелов
    push @entries, @parts;
}
close $csv_fh;
print "Из CSV файла извлечено " . scalar(@entries) . " записей\n" if $debug;

# Чтение белого списка из файла white.list
my @whitelist_entries;
if (open my $whitelist_fh, '<', "$scriptdir/white.list") {
    while (my $line = <$whitelist_fh>) {
        chomp $line;
        $line =~ s/^\s+|\s+$//g;  # Удаление начальных и конечных пробелов
        next if $line eq '';
        push @whitelist_entries, $line;  # Добавление как IPv4 или домена
    }
    close $whitelist_fh;
    print "Из white.list добавлено " . scalar(@whitelist_entries) . " записей\n" if $debug;
}

# Объединение всех записей и удаление дубликатов
my %all_entries;
foreach my $entry (@entries, @whitelist_entries) {
    $all_entries{$entry} = 1;
}
my @unique_entries = keys %all_entries;
print "Всего уникальных записей: " . scalar(@unique_entries) . "\n" if $debug;

# Разделение записей на IPv4 адреса и домены
my @ipv4_addresses;
my @domains;
foreach my $entry (@unique_entries) {
    if (is_ipv4($entry)) {
        push @ipv4_addresses, $entry;
    } else {
        push @domains, $entry;  # Все, что не IPv4, считается доменом
    }
}
print "IPv4 адресов: " . scalar(@ipv4_addresses) . ", доменов: " . scalar(@domains) . "\n" if $debug;

# Сортировка IPv4 адресов по числовому порядку
@ipv4_addresses = sort {
    my @a = split /\./, $a;
    my @b = split /\./, $b;
    $a[0] <=> $b[0] || $a[1] <=> $b[1] || $a[2] <=> $b[2] || $a[3] <=> $b[3]
} @ipv4_addresses;

# Группировка IPv4 адресов по подсетям /24
my $current_subnet = '';
my @subnet_addresses;
foreach my $ip (@ipv4_addresses) {
    my ($subnet) = $ip =~ /^(\d{1,3}\.\d{1,3}\.\d{1,3}\.)/;  # Извлечение первых трех октетов
    if ($subnet ne $current_subnet) {
        # Обработка предыдущей подсети
        if (@subnet_addresses >= 10) {
            print "${current_subnet}0/24\n";  # Вывод подсети, если >= 10 адресов
        } else {
            print "$_\n" for @subnet_addresses;  # Вывод отдельных адресов
        }
        $current_subnet = $subnet;
        @subnet_addresses = ($ip);
    } else {
        push @subnet_addresses, $ip;
    }
}
# Обработка последней подсети
if (@subnet_addresses >= 10) {
    print "${current_subnet}0/24\n";
} else {
    print "$_\n" for @subnet_addresses;
}

# Вывод доменов по одному на строку
print "$_\n" for @domains;

# Очистка временных файлов, если они были созданы
if (!@ARGV) {
    unlink $temp_gz, $temp_csv;
    print "Временные файлы $temp_gz и $temp_csv удалены\n" if $debug;
}

print "Скрипт завершен в " . localtime() . "\n" if $debug;
