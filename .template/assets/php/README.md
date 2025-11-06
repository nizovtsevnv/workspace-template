# {{MODULE_NAME}}

PHP модуль workspace, созданный автоматически.

## Технологический стек

- **Стек**: PHP
- **Тип**: {{TYPE}}
- **Пакетный менеджер**: Composer

## Установка зависимостей

```bash
# Из корня workspace
make {{MODULE_NAME}} composer install
```

## Разработка

Этот модуль является частью polyglot workspace и разрабатывается с использованием host-first подхода (инструменты запускаются на хосте, если доступны, иначе в Alpine контейнере).

### Запуск в dev режиме

```bash
make {{MODULE_NAME}} composer run dev
# или для Laravel
make {{MODULE_NAME}} php artisan serve
```

### Тестирование

```bash
make {{MODULE_NAME}} composer test
# или напрямую PHPUnit
make {{MODULE_NAME}} composer exec phpunit
```

### Линтинг и анализ кода

```bash
# PHP CS Fixer
make {{MODULE_NAME}} composer run lint

# PHPStan
make {{MODULE_NAME}} composer exec phpstan analyse

# PHPCS
make {{MODULE_NAME}} composer exec phpcs
```

## Структура

```
.
├── src/              # Исходный код PHP
├── tests/            # Тесты (PHPUnit)
├── composer.json     # Зависимости и скрипты
├── .php-cs-fixer.php # Конфигурация PHP CS Fixer
├── phpstan.neon      # Конфигурация PHPStan
├── phpcs.xml         # Конфигурация PHPCS
└── README.md         # Документация
```

## Доступные скрипты

См. секцию `scripts` в `composer.json` для полного списка доступных команд.

## Дополнительные команды

```bash
# Добавить зависимость
make {{MODULE_NAME}} composer require <package>

# Добавить dev зависимость
make {{MODULE_NAME}} composer require --dev <package>

# Обновить зависимости
make {{MODULE_NAME}} composer update

# Автозагрузка классов
make {{MODULE_NAME}} composer dump-autoload

# Запустить произвольный скрипт
make {{MODULE_NAME}} composer run <script-name>
```

## Laravel специфичные команды

Если это Laravel проект:

```bash
# Миграции
make {{MODULE_NAME}} php artisan migrate

# Создание контроллера
make {{MODULE_NAME}} php artisan make:controller <Name>

# Очистка кеша
make {{MODULE_NAME}} php artisan cache:clear

# Запуск очередей
make {{MODULE_NAME}} php artisan queue:work
```
