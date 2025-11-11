# Легковесный Alpine образ для генерации C модулей
# Включает: gcc, make, cmake, clang-format
# Размер: ~50MB

FROM alpine:3.19

# Установка инструментов разработки на C
RUN apk add --no-cache \
    gcc \
    make \
    cmake \
    musl-dev \
    clang-extra-tools

# Рабочая директория соответствует монтированию workspace
WORKDIR /workspace
