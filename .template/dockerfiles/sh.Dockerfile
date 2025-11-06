# Легковесный Alpine образ для shell-утилит
# Используется когда инструменты отсутствуют на хосте
# Размер: ~15-20MB
#
# Включает:
# - shellcheck: проверка shell скриптов
# - jq: парсинг и обработка JSON
# - yq: парсинг и обработка YAML
# - bash: расширенный shell
# - curl: загрузка файлов
# - git: работа с репозиториями

FROM alpine:3.19

# Установка shell-утилит одним слоем для минимизации размера образа
RUN apk add --no-cache \
    shellcheck \
    jq \
    yq \
    bash \
    curl \
    git \
    && rm -rf /var/cache/apk/*

# Рабочая директория соответствует монтированию workspace
WORKDIR /workspace

# Используем sh -c как ENTRYPOINT для максимальной гибкости
# Позволяет запускать команды как строки:
# - docker run image "shellcheck file.sh"
# - docker run image "jq '.' file.json"
# Для интерактивного режима: docker run -it image
ENTRYPOINT ["/bin/sh", "-c"]
CMD ["sh"]
