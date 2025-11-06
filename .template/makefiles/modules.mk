# ===================================
# Управление модулями проекта
# ===================================

# ===================================
# Создание новых модулей
# ===================================

# Переменные
MODULE_TARGET ?= modules
MODULE_STACK ?=
MODULE_TYPE ?=
MODULE_NAME ?=

# Получить подкоманду (первый аргумент после module)
MODULE_CMD := $(word 2,$(MAKECMDGOALS))

## module: Команды управления модулями (create, import)
.PHONY: module
module:
	@if [ -z "$(MODULE_CMD)" ]; then \
		$(call run-script,.template/scripts/module/help.sh); \
	elif [ "$(MODULE_CMD)" = "create" ]; then \
		$(MAKE) module-create MODULE_STACK="$(MODULE_STACK)" MODULE_TYPE="$(MODULE_TYPE)" MODULE_NAME="$(MODULE_NAME)" MODULE_TARGET="$(MODULE_TARGET)" || exit $$?; \
	elif [ "$(MODULE_CMD)" = "import" ]; then \
		$(MAKE) module-import MODULE_GIT_URL="$(URL)" MODULE_NAME="$(NAME)" MODULE_GIT_BRANCH="$(BRANCH)" MODULE_TARGET="$(MODULE_TARGET)" || exit $$?; \
	else \
		printf "$(COLOR_ERROR)✗$(COLOR_RESET) Неизвестная подкоманда: $(MODULE_CMD)\n" >&2; \
		printf "$(COLOR_INFO)ℹ$(COLOR_RESET) Доступны: create, import\n"; \
		exit 1; \
	fi

# Создание нового модуля
.PHONY: module-create
module-create:
	@export MODULE_STACK="$(MODULE_STACK)"; \
	export MODULE_TYPE="$(MODULE_TYPE)"; \
	export MODULE_NAME="$(MODULE_NAME)"; \
	export MODULE_TARGET="$(MODULE_TARGET)"; \
	$(call run-script,.template/scripts/module/create.sh)

# Импорт модуля из git репозитория
.PHONY: module-import
module-import:
	@export MODULE_GIT_URL="$(MODULE_GIT_URL)"; \
	export MODULE_NAME="$(MODULE_NAME)"; \
	export MODULE_GIT_BRANCH="$(MODULE_GIT_BRANCH)"; \
	export MODULE_TARGET="$(MODULE_TARGET)"; \
	$(call run-script,.template/scripts/module/import.sh)

# Stub targets для подавления ошибок Make при вызове `make module create/import`
.PHONY: create import
create import:
	@:

# ===================================
# Динамические команды модулей
# ===================================
# Все функции делегируются в .template/scripts/module-command.sh и lib/modules.sh

# Получение списка имён модулей (извлечь basename из путей)
MODULE_NAMES := $(notdir $(ALL_MODULES))

# Проверка: первый аргумент командной строки - имя модуля?
FIRST_GOAL := $(firstword $(MAKECMDGOALS))
SECOND_GOAL := $(word 2,$(MAKECMDGOALS))
REST_GOALS := $(wordlist 3,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))

# Если первый аргумент - имя модуля
ifneq ($(filter $(FIRST_GOAL),$(MODULE_NAMES)),)
  .PHONY: $(FIRST_GOAL)

  # Специальная обработка для git команд (pull, push, convert)
  ifeq ($(SECOND_GOAL),pull)
    $(FIRST_GOAL):
	@export MODULE_GIT_URL="$(URL)"; \
	$(call run-script,.template/scripts/module/git.sh,$(FIRST_GOAL) pull)
  else ifeq ($(SECOND_GOAL),push)
    $(FIRST_GOAL):
	@export MODULE_GIT_URL="$(URL)"; \
	$(call run-script,.template/scripts/module/git.sh,$(FIRST_GOAL) push)
  else ifeq ($(SECOND_GOAL),convert)
    $(FIRST_GOAL):
	@export MODULE_GIT_URL="$(URL)"; \
	$(call run-script,.template/scripts/module/git.sh,$(FIRST_GOAL) convert $(REST_GOALS))
  else
    # Обычная обработка через module/command.sh
    $(FIRST_GOAL):
	@$(call run-script,.template/scripts/module/command.sh,$(FIRST_GOAL) $(SECOND_GOAL) $(REST_GOALS))
  endif

  # Подавить ошибки для остальных аргументов
  .PHONY: $(SECOND_GOAL) $(REST_GOALS)
  $(SECOND_GOAL):
	@:
  $(REST_GOALS):
	@:
endif
