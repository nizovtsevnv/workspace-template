# ===================================
# Вспомогательные функции Makefile
# ===================================

# Универсальная функция для запуска shell-скриптов
# Экспортирует все необходимые переменные окружения и запускает скрипт
# Использование: $(call run-script,путь/к/скрипту.sh,аргументы)
#
# Экспортируемые переменные:
# - Цвета (COLOR_*)
# - Пути (WORKSPACE_ROOT, MODULES_DIR)
# - Контейнер (CONTAINER_RUNTIME, CONTAINER_NAME, CONTAINER_IMAGE, CONTAINER_WORKDIR)
# - Окружение (IS_INSIDE_CONTAINER, HOST_UID, HOST_GID)
define run-script
	export COLOR_SUCCESS='$(COLOR_SUCCESS)'; \
	export COLOR_ERROR='$(COLOR_ERROR)'; \
	export COLOR_INFO='$(COLOR_INFO)'; \
	export COLOR_WARNING='$(COLOR_WARNING)'; \
	export COLOR_SECTION='$(COLOR_SECTION)'; \
	export COLOR_RESET='$(COLOR_RESET)'; \
	export COLOR_DIM='$(COLOR_DIM)'; \
	export WORKSPACE_ROOT='$(WORKSPACE_ROOT)'; \
	export MODULES_DIR='$(MODULES_DIR)'; \
	export CONTAINER_RUNTIME='$(CONTAINER_RUNTIME)'; \
	export CONTAINER_NAME='$(CONTAINER_NAME)'; \
	export CONTAINER_IMAGE='$(CONTAINER_IMAGE)'; \
	export CONTAINER_IMAGE_VERSION='$(CONTAINER_IMAGE_VERSION)'; \
	export CONTAINER_WORKDIR='$(CONTAINER_WORKDIR)'; \
	export IS_INSIDE_CONTAINER='$(IS_INSIDE_CONTAINER)'; \
	export HOST_UID='$(HOST_UID)'; \
	export HOST_GID='$(HOST_GID)'; \
	sh $(1) $(2)
endef
