# ===================================
# Автоопределение окружения
# ===================================
# Определение runtime, версии шаблона и контекста выполнения

# Автоопределение container runtime (docker или podman)
# Проверяем реальный runtime, т.к. docker может быть symlink на podman
CONTAINER_RUNTIME := $(shell \
	if command -v podman >/dev/null 2>&1 && (podman --version 2>/dev/null | grep -q podman || docker --version 2>/dev/null | grep -qi podman); then \
		echo podman; \
	elif command -v docker >/dev/null 2>&1; then \
		echo docker; \
	else \
		echo podman; \
	fi)

# Автоопределение commit hash шаблона (короткий, 7 символов)
# Commit hash сохраняется в .template-commit для отслеживания версии
TEMPLATE_COMMIT := $(shell \
	if [ -f .template-commit ]; then \
		cat .template-commit 2>/dev/null || echo "unknown"; \
	else \
		git rev-parse --short=7 HEAD 2>/dev/null || echo "unknown"; \
	fi)

# Определение даты коммита шаблона (YYYY-MM-DD)
TEMPLATE_DATE := $(shell \
	commit=$$(cat .template-commit 2>/dev/null || git rev-parse HEAD 2>/dev/null); \
	if [ -n "$$commit" ]; then \
		git log -1 --format=%ci "$$commit" 2>/dev/null | cut -d' ' -f1 || echo "unknown"; \
	else \
		echo "unknown"; \
	fi)
