#!/bin/bash
# start-filebrowser.sh - Запуск filebrowser и настройка доступа из локальной сети

set -e

# === ПАРАМЕТРЫ (должны совпадать с install-скриптом) ===
FB_PORT=8080
FB_DB_PATH="/home/$USER/.filebrowser.db"
FB_ROOT="/home/$USER/files"
FB_ADDRESS="0.0.0.0"  # Слушать все интерфейсы
# =================================

echo "=================================================="
echo "🚀 Запуск FileBrowser"
echo "=================================================="
echo ""

# Проверяем, установлен ли filebrowser
if ! command -v filebrowser &> /dev/null; then
    echo "❌ FileBrowser не установлен!"
    echo "   Сначала запустите: bash install-filebrowser.sh"
    exit 1
fi

# Проверяем, существует ли база данных
if [ ! -f "$FB_DB_PATH" ]; then
    echo "❌ База данных не найдена: $FB_DB_PATH"
    echo "   Сначала запустите: bash install-filebrowser.sh"
    exit 1
fi

# Проверяем, не запущен ли уже filebrowser
if pgrep -f "filebrowser --database" > /dev/null; then
    echo "⚠️  FileBrowser уже запущен!"
    echo "   Процессы:"
    pgrep -af "filebrowser --database" | sed 's/^/      /'
    echo ""
    read -p "Хотите перезапустить? (да/нет): " -r
    if [[ $REPLY =~ ^[Дд] ]]; then
        echo "🛑 Остановка текущего процесса..."
        pkill -f "filebrowser --database" || true
        sleep 2
    else
        echo "Запуск отменён."
        exit 0
    fi
fi

echo "🔍 Получение IP-адреса WSL..."
WSL_IP=$(hostname -I | awk '{print $1}')
if [ -z "$WSL_IP" ]; then
    WSL_IP="127.0.0.1"
    echo "   ⚠️  Не удалось определить IP, используем localhost"
else
    echo "   ✅ IP-адрес WSL: $WSL_IP"
fi

echo ""
echo "📡 Настройка доступа из локальной сети..."
echo ""

# Определяем тип WSL
WSL_VERSION=$(wsl.exe -l -v 2>/dev/null | grep -i "Ubuntu" | grep -oP '\d+' | head -1)

if [ "$WSL_VERSION" = "2" ]; then
    echo "🔷 Обнаружен WSL2"
    echo ""
    echo "📋 Для доступа из локальной сети выполните в PowerShell (от Администратора):"
    echo ""
    echo "   # 1. Разрешить порт в брандмауэре Windows:"
    echo "   netsh advfirewall firewall add rule name=\"FileBrowser-WSL\" dir=in action=allow protocol=TCP localport=$FB_PORT"
    echo ""
    echo "   # 2. Настроить проброс порта (если нужно):"
    echo "   netsh interface portproxy add v4tov4 listenport=$FB_PORT listenaddress=0.0.0.0 connectport=$FB_PORT connectaddress=$WSL_IP"
    echo ""
    echo "💡 Для автоматического проброса после перезагрузки WSL:"
    echo "   1. Создайте файл: %USERPROFILE%\\wsl-portproxy.bat"
    echo "   2. Вставьте содержимое:"
    echo "      @echo off"
    echo "      for /f \"tokens=3\" %%a in ('wsl hostname -I') do netsh interface portproxy add v4tov4 listenport=$FB_PORT listenaddress=0.0.0.0 connectport=$FB_PORT connectaddress=%%a"
    echo "   3. Добавьте в Планировщик заданий Windows запуск при входе в систему"
    echo ""
else
    echo "🔶 Обнаружен WSL1"
    echo ""
    echo "📋 Для доступа из локальной сети выполните в PowerShell (от Администратора):"
    echo ""
    echo "   netsh advfirewall firewall add rule name=\"FileBrowser-WSL\" dir=in action=allow protocol=TCP localport=$FB_PORT"
    echo ""
fi

echo "=================================================="
echo "🚀 Запуск FileBrowser..."
echo "=================================================="
echo ""

# Запускаем filebrowser в фоне с логированием
nohup filebrowser \
    --database "$FB_DB_PATH" \
    --address "$FB_ADDRESS" \
    --port "$FB_PORT" \
    --root "$FB_ROOT" \
    > /tmp/filebrowser.log 2>&1 &

FB_PID=$!
sleep 3

# Проверяем, что процесс запустился
if kill -0 $FB_PID 2>/dev/null; then
    echo "✅ FileBrowser успешно запущен!"
    echo ""
    echo "📊 PID процесса: $FB_PID"
    echo "📁 Корневая директория: $FB_ROOT"
    echo "🌐 Порт: $FB_PORT"
    echo ""
    echo "🌍 Доступ к веб-интерфейсу:"
    echo "   • На этом ПК:           http://localhost:$FB_PORT"
    echo "   • Из WSL:               http://$WSL_IP:$FB_PORT"
    echo "   • Из локальной сети:    http://<IP-вашего-ПК>:$FB_PORT"
    echo "                           (после настройки брандмауэра)"
    echo ""
    echo "📋 Логи: /tmp/filebrowser.log"
    echo "🛑 Остановить: kill $FB_PID"
    echo "   или: pkill -f filebrowser"
    echo ""
else
    echo "❌ Не удалось запустить FileBrowser!"
    echo "📋 Логи ошибки:"
    cat /tmp/filebrowser.log
    exit 1
fi