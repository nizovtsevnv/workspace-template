# ===================================
# Базовые команды управления средой
# ===================================

.PHONY: init versions

## init: Инициализация проекта из шаблона
init:
	@$(call run-script,.template/scripts/init.sh)

## versions: Показать версии инструментов технологических стеков
versions:
	@$(call run-script,.template/scripts/versions.sh)
