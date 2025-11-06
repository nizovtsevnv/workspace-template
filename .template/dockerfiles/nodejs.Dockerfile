# Легковесный Alpine образ для генерации Node.js модулей
# Включает: node, npm, bun, pnpm, yarn (yarn уже есть в базовом образе), bunx
# Размер: ~150MB

FROM node:23-alpine

# Установка пакетных менеджеров и очистка кеша в одном слое
# yarn уже включен в базовый образ node:23-alpine
RUN npm install -g --no-cache bun pnpm \
    && npm cache clean --force

# Рабочая директория соответствует монтированию workspace
WORKDIR /workspace

# Entrypoint позволяет запускать любые команды
ENTRYPOINT ["/bin/sh"]
