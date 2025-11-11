# Легковесный Alpine образ для генерации PHP модулей
# Включает: php, composer, laravel installer
# Размер: ~100MB

FROM php:8.3-cli-alpine

# Установка расширений PHP в одном слое
RUN apk add --no-cache \
    zip \
    unzip \
    git

# Установка Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Установка Laravel Installer с очисткой кеша в одном слое
RUN composer global require laravel/installer --no-cache \
    && rm -rf /root/.composer/cache

# Добавить composer bin в PATH
ENV PATH="${PATH}:/root/.composer/vendor/bin"

# Рабочая директория соответствует монтированию workspace
WORKDIR /workspace
