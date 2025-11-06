# Легковесный Alpine образ для генерации Python модулей
# Включает: python, pip, uv, poetry
# Размер: ~100MB

FROM python:3.13-alpine

# Установка инструментов для сборки и менеджеров пакетов в одном слое
RUN apk add --no-cache gcc musl-dev libffi-dev \
    && pip install --no-cache-dir uv poetry

# Рабочая директория соответствует монтированию workspace
WORKDIR /workspace

# Entrypoint позволяет запускать любые команды
ENTRYPOINT ["/bin/sh"]
