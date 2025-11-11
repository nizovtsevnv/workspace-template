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

printf "make modules create<COL>Создать новый модуль (Node.js, PHP, Python, Rust)<ROW>make modules import<COL>Импортировать модуль из git репозитория<ROW>make modules pull<COL>Обновить workspace и все субмодули<ROW>make modules push<COL>Отправить изменения субмодулей и обновить workspace<ROW>make modules status<COL>Статус всех субмодулей\n" | print_table 24
