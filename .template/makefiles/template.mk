# ===================================
# Управление шаблоном Workspace Template
# ===================================

.PHONY: template

# Получить подкоманду (первый аргумент после template)
TEMPLATE_CMD := $(word 2,$(MAKECMDGOALS))

## template: Команды управления шаблоном (test, update, status)
template:
	@if [ -z "$(TEMPLATE_CMD)" ]; then \
		$(call run-script,.template/scripts/template/help.sh); \
	elif [ "$(TEMPLATE_CMD)" = "test" ]; then \
		$(call run-script,.template/scripts/template/test.sh) || exit $$?; \
	elif [ "$(TEMPLATE_CMD)" = "update" ]; then \
		$(call run-script,.template/scripts/template/update.sh) || exit $$?; \
	elif [ "$(TEMPLATE_CMD)" = "status" ]; then \
		$(call run-script,.template/scripts/template/status.sh) || exit $$?; \
	else \
		printf "$(COLOR_ERROR)✗$(COLOR_RESET) Неизвестная подкоманда: $(TEMPLATE_CMD)\n" >&2; \
		printf "$(COLOR_INFO)ℹ$(COLOR_RESET) Доступны: test, update, status\n"; \
		exit 1; \
	fi

# Stub targets для подавления ошибок Make при вызове `make template test/update/status`
.PHONY: test update status
test update status:
	@:
