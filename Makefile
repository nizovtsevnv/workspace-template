# ===================================
# Workspace Template - Makefile
# ===================================
#
# Система многоуровневых команд для управления workspace и модулями
#
# Использование:
#   make help              - справка
#   make <модуль> <команда> - работа с модулем
#   make template <cmd>    - управление шаблоном (test, update)
#

.DEFAULT_GOAL := help
MAKEFLAGS += --no-print-directory

# Подключение модулей в правильном порядке
# Порядок важен:
# 1. detect.mk - автоопределение окружения (runtime, версия шаблона)
# 2. config.mk - переменные конфигурации
# 3. functions.mk - вспомогательные функции
# 4. core, modules, template, help
include .template/makefiles/detect.mk
include .template/makefiles/config.mk
include .template/makefiles/functions.mk
include .template/makefiles/core.mk
include .template/makefiles/modules.mk
include .template/makefiles/template.mk
include .template/makefiles/help.mk

# Универсальное правило для подавления ошибок о несуществующих targets
# Позволяет передавать произвольные аргументы в команды модулей
%:
	@:
