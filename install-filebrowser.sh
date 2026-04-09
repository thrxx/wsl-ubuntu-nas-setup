#!/bin/bash
# install-filebrowser.sh - Установка и первоначальная настройка filebrowser в WSL/Ubuntu

set -e  # Остановка при ошибке

# === НАСТРАИВАЕМЫЕ ПАРАМЕТРЫ ===
FB_PORT=8080                    # Порт для веб-интерфейса
FB_ROOT="/home/$USER/files"     # Корневая директория для файлов
FB_DB_PATH="/home/$USER/.filebrowser.db"  # Путь к базе данных
FB_ADMIN_USER="admin"           # Имя администратора
FB_ADMIN_PASS=""                # Пароль администратора (будет запрошен, если пустой)
FB_ADDRESS="0.0.0.0"            # Слушать все интерфейсы (для доступа из локальной сети)
# =================================

echo "=================================================="
echo "📦 Установка FileBrowser для WSL/Ubuntu NAS"
echo "=================================================="
echo ""

# Проверка прав суперпользователя
if [ "$EUID" -eq 0 ]; then 
    echo "❌ Не запускайте этот скрипт от имени root!"
    echo "   Запустите: bash install-filebrowser.sh"
    exit 1
fi

# Проверяем, установлен ли уже filebrowser
if command -v filebrowser &> /dev/null; then
    echo "⚠️  FileBrowser уже установлен!"
    echo "   Версия: $(filebrowser version 2>/dev/null || echo 'неизвестна')"
    read -p "Хотите продолжить настройку? (да/нет): " -r
    if [[ ! $REPLY =~ ^[Дд] ]]; then
        echo "Установка отменена."
        exit 0
    fi
fi

# Запрос пароля, если не задан
if [ -z "$FB_ADMIN_PASS" ]; then
    echo "🔐 Введите пароль для администратора (минимум 6 символов):"
    while true; do
        read -s -p "Пароль: " FB_ADMIN_PASS
        echo ""
        read -s -p "Подтвердите пароль: " FB_ADMIN_PASS_CONFIRM
        echo ""
        
        if [ "$FB_ADMIN_PASS" = "$FB_ADMIN_PASS_CONFIRM" ] && [ ${#FB_ADMIN_PASS} -ge 6 ]; then
            break
        elif [ "$FB_ADMIN_PASS" != "$FB_ADMIN_PASS_CONFIRM" ]; then
            echo "❌ Пароли не совпадают!"
        else
            echo "❌ Пароль слишком короткий (минимум 6 символов)!"
        fi
    done
fi

echo ""
echo "🔄 Обновление системы..."
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl wget unzip

echo ""
echo "📥 Скачивание и установка filebrowser..."
# Официальный скрипт установки
curl -fsSL https://raw.githubusercontent.com/filebrowser/get/master/get.sh | bash

# Проверяем, что filebrowser установлен
if ! command -v filebrowser &> /dev/null; then
    echo "❌ Ошибка: filebrowser не установлен!"
    exit 1
fi

echo ""
echo "📁 Создание директории для файлов..."
mkdir -p "$FB_ROOT"
chmod 755 "$FB_ROOT"
echo "   Директория: $FB_ROOT"

echo ""
echo "⚙️ Инициализация конфигурации..."
# Инициализируем базу данных (если ещё не существует)
if [ ! -f "$FB_DB_PATH" ]; then
    filebrowser config init --database "$FB_DB_PATH"
    echo "   ✅ База данных создана: $FB_DB_PATH"
else
    echo "   ⚠️  База данных уже существует"
fi

echo ""
echo "⚙️ Настройка параметров..."
# Настраиваем адрес, порт, корневую директорию
filebrowser config set \
    --database "$FB_DB_PATH" \
    --address "$FB_ADDRESS" \
    --port "$FB_PORT" \
    --root "$FB_ROOT"

echo "   ✅ Настройки применены:"
echo "      • Адрес: $FB_ADDRESS"
echo "      • Порт: $FB_PORT"
echo "      • Корень: $FB_ROOT"

echo ""
echo "👤 Создание пользователя администратора..."
# Проверяем, существует ли уже админ
if filebrowser users ls --database "$FB_DB_PATH" 2>/dev/null | grep -q "$FB_ADMIN_USER"; then
    echo "   ⚠️  Пользователь '$FB_ADMIN_USER' уже существует"
    echo "   Для изменения пароля запустите:"
    echo "   filebrowser users update $FB_ADMIN_USER --database $FB_DB_PATH --password НОВЫЙ_ПАРОЛЬ"
else
    # Добавляем администратора
    filebrowser users add "$FB_ADMIN_USER" "$FB_ADMIN_PASS" \
        --database "$FB_DB_PATH" \
        --perm.admin
    
    echo "   ✅ Администратор '$FB_ADMIN_USER' создан"
fi

echo ""
echo "=================================================="
echo "✅ Установка завершена!"
echo "=================================================="
echo ""
echo "📁 Файлы: $FB_ROOT"
echo "🌐 Веб-интерфейс: http://localhost:$FB_PORT"
echo "👤 Логин: $FB_ADMIN_USER"
echo "🔑 Пароль: [указан вами]"
echo ""
echo "📋 Следующие шаги:"
echo "   1. Запустите: bash start-filebrowser.sh"
echo "   2. Откройте в браузере: http://localhost:$FB_PORT"
echo "   3. Для доступа из локальной сети следуйте инструкциям из start-filebrowser.sh"
echo ""