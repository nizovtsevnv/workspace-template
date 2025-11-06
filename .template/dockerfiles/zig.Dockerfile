# Легковесный Alpine образ для генерации Zig модулей
# Включает: zig
# Размер: ~200MB

FROM alpine:edge

# Установка Zig из edge репозитория
RUN apk add --no-cache zig

# Рабочая директория соответствует монтированию workspace
WORKDIR /workspace

# Entrypoint позволяет запускать любые команды
ENTRYPOINT ["/bin/sh"]
