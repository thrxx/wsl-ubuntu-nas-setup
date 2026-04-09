# WSL Ubuntu NAS Setup

Автоматическая установка и настройка **FileBrowser** на WSL (Ubuntu) для создания домашнего NAS с веб-интерфейсом.

## Возможности

- 📦 Автоматическая установка WSL и Ubuntu (если не установлены)
- 🌐 Веб-интерфейс для загрузки/скачивания файлов
- 🔐 Авторизация и права доступа
- 📱 Доступ с любого устройства в локальной сети
- 🚀 Полная автоматизация через один BAT-файл

## Быстрый старт

### 1. Скачайте репозиторий

```bash
git clone https://github.com/thrxx/wsl-ubuntu-nas-setup.git
cd wsl-ubuntu-nas-setup
```

Или скачайте ZIP-архив через кнопку **Code → Download ZIP**.

### 2. Запустите установку

1. Нажмите правой кнопкой на `setup-nas.bat`
2. Выберите **"Запуск от имени администратора"**
3. Следуйте инструкциям на экране

### 3. Откройте веб-интерфейс

После установки откройте браузер и перейдите по адресу:

- **На этом ПК:** http://localhost:8080
- **Из локальной сети:** http://<IP-вашего-ПК>:8080

## Структура файлов

```
wsl-ubuntu-nas-setup/
├── setup-nas.bat              # Главный скрипт установки (Windows)
├── install-filebrowser.sh     # Скрипт установки FileBrowser (WSL)
├── start-filebrowser.sh       # Скрипт запуска FileBrowser (WSL)
└── README.md                  # Этот файл
```

## Ручная установка (для продвинутых)

Если вы предпочитаете контролировать процесс:

### В WSL (Ubuntu):

```bash
# Установка FileBrowser
bash install-filebrowser.sh

# Запуск FileBrowser
bash start-filebrowser.sh
```

### Настройка доступа из локальной сети

В PowerShell (от Администратора):

```powershell
# Открыть порт в брандмауэре
netsh advfirewall firewall add rule name="FileBrowser-WSL" dir=in action=allow protocol=TCP localport=8080

# Для WSL2 - проброс порта (если нужно)
netsh interface portproxy add v4tov4 listenport=8080 listenaddress=0.0.0.0 connectport=8080 connectaddress=<IP-WSL>
```

## Настройка

Параметры можно изменить в начале скриптов:

| Параметр | Описание | Значение по умолчанию |
|----------|----------|----------------------|
| `FB_PORT` | Порт веб-интерфейса | `8080` |
| `FB_ROOT` | Директория для файлов | `/home/$USER/files` |
| `FB_DB_PATH` | Путь к базе данных | `/home/$USER/.filebrowser.db` |
| `FB_ADMIN_USER` | Имя администратора | `admin` |
| `FB_ADDRESS` | Адрес прослушивания | `0.0.0.0` (все интерфейсы) |

## Управление FileBrowser

### Запуск
```bash
wsl bash ~/nas-setup/start-filebrowser.sh
```

### Остановка
```bash
wsl pkill -f filebrowser
```

### Проверка статуса
```bash
wsl pgrep -af filebrowser
```

### Логи
```bash
wsl cat /tmp/filebrowser.log
```

## Автозапуск после перезагрузки

Для автоматического проброса порта после перезагрузки WSL:

1. Создайте файл: `%USERPROFILE%\wsl-portproxy.bat`
2. Вставьте содержимое:
```batch
@echo off
for /f "tokens=3" %%a in ('wsl hostname -I') do netsh interface portproxy add v4tov4 listenport=8080 listenaddress=0.0.0.0 connectport=8080 connectaddress=%%a
```
3. Добавьте в Планировщик заданий Windows запуск при входе в систему

## Безопасность

- ⚠️ **Смените пароль администратора** после первого входа!
- 🔒 По умолчанию FileBrowser доступен только в вашей локальной сети
- 🛡️ Брандмауэр Windows блокирует внешние подключения по умолчанию

## Требования

- Windows 10/11
- Права администратора (для установки WSL и настройки брандмауэра)
- Интернет-соединение (для скачивания FileBrowser)

## Решение проблем

### FileBrowser не запускается
```bash
# Проверьте логи
wsl cat /tmp/filebrowser.log

# Убейте все процессы filebrowser
wsl pkill -f filebrowser

# Запустите заново
wsl bash ~/nas-setup/start-filebrowser.sh
```

### Нет доступа из локальной сети
1. Проверьте правило брандмауэра в Windows
2. Для WSL2 настройте portproxy (см. выше)
3. Узнайте IP вашего ПК: `ipconfig` (в Windows) или `hostname -I` (в WSL)

### Порт 8080 уже занят
Измените `FB_PORT=8080` на другой порт в скриптах `install-filebrowser.sh` и `start-filebrowser.sh`

## Лицензия

MIT License — см. файл [LICENSE](LICENSE)

## 📬 Контакты

- GitHub: [thrxx](https://github.com/thrxx)
- Issues: [Сообщить о проблеме](https://github.com/thrxx/arch-linux-maintenance/issues)

---
