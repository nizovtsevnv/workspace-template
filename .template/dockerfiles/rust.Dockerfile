# Легковесный Alpine образ для генерации Rust модулей
# Включает: rustc, cargo, rustfmt, clippy
# Размер: ~500MB

FROM rust:alpine

# Установка инструментов для сборки и компонентов Rust в одном слое
RUN apk add --no-cache musl-dev \
    && rustup component add rustfmt clippy

# Рабочая директория соответствует монтированию workspace
WORKDIR /workspace

# Entrypoint позволяет запускать любые команды
ENTRYPOINT ["/bin/sh"]
