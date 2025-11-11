#!/bin/sh
# ===================================
# Workspace Template - Автотесты
# ===================================
set -e

# Инициализация общих переменных
. "$(dirname "$0")/../lib/init.sh"

# Загружаем библиотеки
. "$SCRIPT_DIR/lib/ui.sh"
. "$SCRIPT_DIR/lib/shellcheck.sh"

# Директория для тестов
TEST_DIR="${TEST_DIR:-/tmp/devcontainer-workspace}"

# ===================================
# Вспомогательные функции
# ===================================
# (Используем show_spinner из ui.sh для всех проверок)

# ===================================
# Основная логика
# ===================================

log_section "Подготовка тестового окружения"

# Очистка старого тестового окружения если есть
rm -rf "$TEST_DIR" 2>/dev/null || true
log_success "Окружение очищено"

# Подготовка изолированного тестового окружения
prepare_test_dir() {
	rm -rf "$TEST_DIR"
	mkdir -p "$TEST_DIR/modules"
	cp Makefile "$TEST_DIR/"
	cp -r .template "$TEST_DIR/"
	echo "=== Test Run: $(date) ===" > "$TEST_DIR/test-results.log"
}

show_spinner "Подготовка изолированной копии шаблона" prepare_test_dir

# Создание тестовых модулей
log_section "Создание модулей пакетными менеджерами"

show_spinner "Создание test-c" make --no-print-directory modules create MODULE_STACK=c MODULE_TYPE=makefile MODULE_NAME=test-c MODULE_TARGET="$TEST_DIR/modules"
show_spinner "Создание test-nodejs" make --no-print-directory modules create MODULE_STACK=nodejs MODULE_TYPE=bun MODULE_NAME=test-nodejs MODULE_TARGET="$TEST_DIR/modules"
show_spinner "Создание test-php" make --no-print-directory modules create MODULE_STACK=php MODULE_TYPE=composer-lib MODULE_NAME=test-php MODULE_TARGET="$TEST_DIR/modules"
show_spinner "Создание test-python" make --no-print-directory modules create MODULE_STACK=python MODULE_TYPE=poetry MODULE_NAME=test-python MODULE_TARGET="$TEST_DIR/modules"
show_spinner "Создание test-rust" make --no-print-directory modules create MODULE_STACK=rust MODULE_TYPE=bin MODULE_NAME=test-rust MODULE_TARGET="$TEST_DIR/modules"
show_spinner "Создание test-zig" make --no-print-directory modules create MODULE_STACK=zig MODULE_TYPE=exe MODULE_NAME=test-zig MODULE_TARGET="$TEST_DIR/modules"

# Тестирование shell-скриптов статическим анализом
log_section "Проверка качества shell-скриптов (shellcheck)"

# Проверяем все shell-скрипты в новой структуре
cd "$TEST_DIR" || exit 1

for script in .template/scripts/*.sh .template/scripts/lib/*.sh .template/scripts/module/*.sh .template/scripts/module/generators/*.sh .template/scripts/template/*.sh; do
	[ -f "$script" ] || continue
	script_rel=$(echo "$script" | sed 's|^\./||')

	# Используем show_spinner для единообразия с остальными тестами
	if ! show_spinner "shellcheck: $script_rel" run_shellcheck -x -P .template/scripts -S warning "$script"; then
		# При ошибке показываем детали
		printf "\n"
		log_error "Ошибка в $script_rel:"
		run_shellcheck -x -P .template/scripts -S warning "$script" 2>&1 | head -20
		exit 1
	fi
done

cd "$WORKSPACE_ROOT" || exit 1

# Тестирование базовых функций
log_section "Тестирование базовых функций"

show_spinner "Проверка существования тестовых модулей" sh -c "[ -d '$TEST_DIR/modules/test-c' ] && [ -d '$TEST_DIR/modules/test-nodejs' ] && [ -d '$TEST_DIR/modules/test-php' ] && [ -d '$TEST_DIR/modules/test-python' ] && [ -d '$TEST_DIR/modules/test-rust' ] && [ -d '$TEST_DIR/modules/test-zig' ]"

show_spinner "Создание тестового файла" sh -c "echo 'test-content' > '$TEST_DIR/test-file.txt' && [ -f '$TEST_DIR/test-file.txt' ]"

show_spinner "Чтение тестового файла" sh -c "[ \"\$(cat '$TEST_DIR/test-file.txt')\" = 'test-content' ]"

# Итоговая информация
printf "\n"
log_success "ВСЕ ТЕСТЫ ПРОЙДЕНЫ!"
printf "\n"
log_info "Тестовое окружение:"
printf '%s\n' "Каталог<COL>$TEST_DIR/<ROW>Модули<COL>$TEST_DIR/modules/<ROW>Журнал<COL>$TEST_DIR/test-results.log" | print_table 16
printf "\n"
log_info "Артефакты в /tmp автоматически очистятся при перезагрузке"
