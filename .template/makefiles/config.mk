# ===================================
# Конфигурация workspace
# ===================================
# Переменные конфигурации проекта
# Автоопределение окружения см. в detect.mk
# Вспомогательные функции см. в functions.mk

# Определение проекта
PROJECT_NAME := polyglot-workspace
WORKSPACE_ROOT := $(shell pwd)

# URL репозитория шаблона для обновлений
# Можно переопределить через переменную окружения перед вызовом make
TEMPLATE_REPO_URL ?= https://github.com/nizovtsevnv/workspace-template.git
export TEMPLATE_REPO_URL

# Экспортировать UID и GID хоста
# Это обеспечивает корректные права доступа к файлам в контейнерах
# Используем HOST_UID/HOST_GID, т.к. GID - встроенная переменная bash
export HOST_UID := $(shell id -u)
export HOST_GID := $(shell id -g)

# Пути для субмодулей
MODULES_DIR := modules
MODULES := $(wildcard $(MODULES_DIR)/*)
# Все модули: только директории (исключая файлы типа .gitkeep)
ALL_MODULES := $(filter-out $(MODULES_DIR)/.gitkeep,$(filter-out %/.gitkeep,$(MODULES)))

# Цвета для вывода (экспортируются в shell-скрипты через run-script)
COLOR_RESET := \033[0m
COLOR_INFO := \033[0;36m
COLOR_SUCCESS := \033[0;32m
COLOR_WARNING := \033[0;33m
COLOR_ERROR := \033[0;31m
COLOR_SECTION := \033[1;35m
COLOR_DIM := \033[2m
