#!/bin/sh
# ===================================
# Workspace Template - Справка по командам module
# ===================================

# Инициализация общих переменных
. "$(dirname "$0")/../lib/init.sh"

# Загружаем библиотеки
. "$SCRIPT_DIR/lib/ui.sh"

# ===================================
# Основная логика
# ===================================

log_info "Команды управления модулями"

printf "make module create<COL>Создать новый модуль (Node.js, PHP, Python, Rust)<ROW>make module import<COL>Импортировать модуль из git репозитория<ROW>make module pull<COL>Инициализация и обновление всех субмодулей<ROW>make module push<COL>Отправка изменений во все субмодули<ROW>make module status<COL>Статус всех субмодулей\n" | print_table 24
