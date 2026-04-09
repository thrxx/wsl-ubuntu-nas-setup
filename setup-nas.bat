@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

echo ==================================================
echo    Установка WSL + FileBrowser NAS
echo ==================================================
echo.

:: Проверяем права администратора
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [!] Запустите этот скрипт от имени Администратора!
    echo     Правый клик по файлу -^> "Запуск от имени администратора"
    echo.
    pause
    exit /b 1
)

echo [1/5] Проверка WSL...
wsl --status >nul 2>&1
if %errorlevel% neq 0 (
    echo [!] WSL не установлен. Установка...
    echo.
    echo [i] Будет установлена Ubuntu (по умолчанию)
    echo [i] Для отмены закройте это окно или нажмите Ctrl+C
    timeout /t 5 /nobreak >nul
    
    wsl --install -d Ubuntu
    if %errorlevel% neq 0 (
        echo [!] Ошибка установки WSL!
        pause
        exit /b 1
    )
    
    echo.
    echo [i] WSL установлен!
    echo [i] Если потребуется перезагрузка - перезагрузите ПК и запустите скрипт снова
    echo.
    pause
    exit /b 0
) else (
    echo [+] WSL уже установлен
)

echo.
echo [2/5] Проверка Ubuntu...
wsl -l -v | findstr /i "Ubuntu" >nul 2>&1
if %errorlevel% neq 0 (
    echo [!] Ubuntu не найдена. Установка...
    wsl --install -d Ubuntu
    if %errorlevel% neq 0 (
        echo [!] Ошибка установки Ubuntu!
        pause
        exit /b 1
    )
    echo.
    echo [i] Ubuntu установлена! Перезагрузите ПК и запустите скрипт снова
    echo.
    pause
    exit /b 0
) else (
    echo [+] Ubuntu найдена
)

echo.
echo [3/5] Определение пути к скриптам...
:: Путь к директории со скриптами (где лежит этот bat)
set "SCRIPT_DIR=%~dp0"
set "INSTALL_SCRIPT=%SCRIPT_DIR%install-filebrowser.sh"
set "START_SCRIPT=%SCRIPT_DIR%start-filebrowser.sh"

:: Проверяем наличие скриптов
if not exist "%INSTALL_SCRIPT%" (
    echo [!] Не найден файл: %INSTALL_SCRIPT%
    echo.
    echo [i] Поместите install-filebrowser.sh в ту же директорию, что и setup-nas.bat
    pause
    exit /b 1
)

if not exist "%START_SCRIPT%" (
    echo [!] Не найден файл: %START_SCRIPT%
    echo.
    echo [i] Поместите start-filebrowser.sh в ту же директорию, что и setup-nas.bat
    pause
    exit /b 1
)

echo [+] Скрипты найдены:
echo     - install-filebrowser.sh
echo     - start-filebrowser.sh

echo.
echo [4/5] Копирование скриптов в WSL...
:: Копируем скрипты в домашнюю директорию WSL
set "WSL_DEST=~/nas-setup"

wsl -u root mkdir -p "%WSL_DEST%" >nul 2>&1
wsl -u root cp "%SCRIPT_DIR%install-filebrowser.sh" "%WSL_DEST%/" >nul 2>&1
wsl -u root cp "%SCRIPT_DIR%start-filebrowser.sh" "%WSL_DEST%/" >nul 2>&1
wsl -u root chmod +x "%WSL_DEST%/install-filebrowser.sh" >nul 2>&1
wsl -u root chmod +x "%WSL_DEST%/start-filebrowser.sh" >nul 2>&1

echo [+] Скрипты скопированы в: %WSL_DEST%

echo.
echo [5/5] Запуск установки FileBrowser...
echo.
echo [i] Следуйте инструкциям в окне WSL
echo.
pause

:: Запускаем установку
wsl bash "%WSL_DEST%/install-filebrowser.sh"
if %errorlevel% neq 0 (
    echo.
    echo [!] Ошибка при установке FileBrowser!
    pause
    exit /b 1
)

echo.
echo ==================================================
echo    Настройка брандмауэра Windows
echo ==================================================
echo.
echo [i] Для доступа из локальной сети нужно открыть порт 8080
echo.
set /p "FIREWALL=Открыть порт 8080 в брандмауэре? (да/нет): "
if /i "%FIREWALL%"=="да" (
    echo [i] Открытие порта...
    netsh advfirewall firewall delete rule name="FileBrowser-WSL" >nul 2>&1
    netsh advfirewall firewall add rule name="FileBrowser-WSL" dir=in action=allow protocol=TCP localport=8080
    echo [+] Порт 8080 открыт!
)

echo.
echo ==================================================
echo    Запуск FileBrowser
echo ==================================================
echo.
set /p "START=Запустить FileBrowser сейчас? (да/нет): "
if /i "%START%"=="да" (
    echo [i] Запуск...
    echo.
    wsl bash "%WSL_DEST%/start-filebrowser.sh"
) else (
    echo.
    echo [i] Для запуска используйте: wsl bash ~/nas-setup/start-filebrowser.sh
)

echo.
echo ==================================================
echo    Готово!
echo ==================================================
echo.
echo [+] FileBrowser установлен и настроен!
echo [+] Веб-интерфейс: http://localhost:8080
echo.
pause
