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

# Получить подкоманду (первый аргумент после modules)
MODULE_CMD := $(word 2,$(MAKECMDGOALS))

## modules: Команды управления модулями (create, import, pull, push, sync, status)
.PHONY: modules
modules:
	@if [ -z "$(MODULE_CMD)" ]; then \
		$(call run-script,.template/scripts/module/help.sh); \
	elif [ "$(MODULE_CMD)" = "create" ]; then \
		$(MAKE) modules-create MODULE_STACK="$(MODULE_STACK)" MODULE_TYPE="$(MODULE_TYPE)" MODULE_NAME="$(MODULE_NAME)" MODULE_TARGET="$(MODULE_TARGET)" || exit $$?; \
	elif [ "$(MODULE_CMD)" = "import" ]; then \
		$(MAKE) modules-import MODULE_GIT_URL="$(URL)" MODULE_NAME="$(NAME)" MODULE_GIT_BRANCH="$(BRANCH)" MODULE_TARGET="$(MODULE_TARGET)" || exit $$?; \
	elif [ "$(MODULE_CMD)" = "pull" ]; then \
		$(call run-script,.template/scripts/module/bulk.sh,pull); \
	elif [ "$(MODULE_CMD)" = "push" ]; then \
		$(call run-script,.template/scripts/module/bulk.sh,push); \
	elif [ "$(MODULE_CMD)" = "sync" ]; then \
		$(call run-script,.template/scripts/module/bulk.sh,sync); \
	elif [ "$(MODULE_CMD)" = "status" ]; then \
		$(call run-script,.template/scripts/module/bulk.sh,status); \
	else \
		printf "$(COLOR_ERROR)✗$(COLOR_RESET) Неизвестная подкоманда: $(MODULE_CMD)\n" >&2; \
		printf "$(COLOR_INFO)ℹ$(COLOR_RESET) Доступны: create, import, pull, push, sync, status\n"; \
		exit 1; \
	fi

# Создание нового модуля
.PHONY: modules-create
modules-create:
	@export MODULE_STACK="$(MODULE_STACK)"; \
	export MODULE_TYPE="$(MODULE_TYPE)"; \
	export MODULE_NAME="$(MODULE_NAME)"; \
	export MODULE_TARGET="$(MODULE_TARGET)"; \
	$(call run-script,.template/scripts/module/create.sh)

# Импорт модуля из git репозитория
.PHONY: modules-import
modules-import:
	@export MODULE_GIT_URL="$(MODULE_GIT_URL)"; \
	export MODULE_NAME="$(MODULE_NAME)"; \
	export MODULE_GIT_BRANCH="$(MODULE_GIT_BRANCH)"; \
	export MODULE_TARGET="$(MODULE_TARGET)"; \
	$(call run-script,.template/scripts/module/import.sh)

# Stub targets для подавления ошибок Make при вызове `make modules create/import/pull/push/sync/status`
.PHONY: create import pull push sync
create import pull push sync:
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
  # Создаем stub targets для всех аргументов после имени модуля,
  # чтобы Make не пытался выполнить их как отдельные команды
  # (например, при `make site init` не должен выполняться корневой init)
  #
  # Исключаем аргументы с двоеточием (например, migration:new),
  # так как Make не может создать target с : в имени
  ifneq ($(SECOND_GOAL),)
    ifeq ($(findstring :,$(SECOND_GOAL)),)
      .PHONY: $(SECOND_GOAL)
      $(SECOND_GOAL):
	@:
    endif
  endif

  # Фильтруем аргументы без двоеточия для создания stub targets
  ifneq ($(REST_GOALS),)
    SAFE_REST_GOALS := $(filter-out %:%,$(REST_GOALS))
    ifneq ($(SAFE_REST_GOALS),)
      .PHONY: $(SAFE_REST_GOALS)
      $(SAFE_REST_GOALS):
	@:
    endif
  endif
endif

# ===================================
# Catch-all правило для неизвестных целей
# ===================================
# Используется когда команда модуля содержит спецсимволы (например, migration:new),
# которые Make не может обработать как обычные target names.
# Это правило применяется только к целям, для которых нет других правил.
.DEFAULT:
	@:
