#!/bin/sh
# ===================================
# UI библиотека для Workspace Template
# ===================================
# Объединяет все UI функции: логирование, спиннер, интерактив
# Использование: . lib/ui.sh
# shellcheck disable=SC2059,SC3043

# ===================================
# Цвета (импортируются из окружения)
# ===================================
COLOR_SUCCESS="${COLOR_SUCCESS:-\033[0;32m}"
COLOR_ERROR="${COLOR_ERROR:-\033[0;31m}"
COLOR_INFO="${COLOR_INFO:-\033[0;36m}"
COLOR_WARNING="${COLOR_WARNING:-\033[0;33m}"
COLOR_SECTION="${COLOR_SECTION:-\033[1;35m}"
COLOR_DIM="${COLOR_DIM:-\033[2m}"
COLOR_RESET="${COLOR_RESET:-\033[0m}"

# ===================================
# Функции логирования
# ===================================

log_info() {
	printf "${COLOR_INFO}ℹ${COLOR_RESET} %s\n" "$1"
}

log_success() {
	printf "${COLOR_SUCCESS}✓${COLOR_RESET} %s\n" "$1"
}

log_warning() {
	printf "${COLOR_WARNING}⚠${COLOR_RESET} %s\n" "$1"
}

log_error() {
	printf "${COLOR_ERROR}✗${COLOR_RESET} %s\n" "$1" >&2
}

log_section() {
	printf "${COLOR_SECTION}▶ %s${COLOR_RESET}\n" "$1"
}

# ===================================
# Вывод таблиц
# ===================================

# Вывод таблицы с фиксированной шириной первой колонки
# Параметр: $1 - ширина первой колонки
# Использование: printf '%s\n' "key1<COL>value1<ROW>key2<COL>value2" | print_table 16
# Разделитель строк - <ROW>, разделитель колонок - <COL>
print_table() {
	col_width=$1
	while IFS= read -r line; do
		# Разбиваем строки по <ROW>
		echo "$line"
	done | sed 's/<ROW>/\n/g' | while read -r row_data; do
		# Пропускаем пустые строки
		[ -z "$row_data" ] && continue

		# Разбиваем колонки по <COL> используя POSIX-совместимый подход
		key=$(echo "$row_data" | sed 's/<COL>.*//')
		value=$(echo "$row_data" | sed 's/^[^<]*<COL>//')

		# Убираем оставшиеся маркеры из value
		value=$(echo "$value" | sed 's/<ROW>//g')

		key_len=$(printf '%s' "$key" | wc -m)
		padding=$((col_width - key_len))
		[ $padding -lt 0 ] && padding=0

		printf "  ${COLOR_SUCCESS}%s%*s${COLOR_RESET} %s\n" "$key" $padding "" "$value"
	done
}

# ===================================
# Определение интерактивного режима
# ===================================

# Проверка является ли stderr терминалом (TTY)
# Возвращает: 0 если интерактивный режим, 1 если CI/CD
is_tty() {
	[ -t 2 ]
}

# ===================================
# Спиннер
# ===================================

# Показать спиннер во время выполнения команды
# Параметры: $1 - сообщение, остальные - команда с аргументами
# Возвращает: exit code команды
# Использование: show_spinner "Загрузка" git clone https://example.com/repo
show_spinner() {
	title="$1"
	shift

	tmpfile=$(mktemp)
	# shellcheck disable=SC2064
	trap "rm -f $tmpfile" EXIT INT TERM

	# Запускаем команду в фоне
	"$@" > "$tmpfile" 2>&1 &
	pid=$!

	# Определяем режим вывода
	if is_tty; then
		# Интерактивный режим - показываем анимированный спиннер
		sp='◐◓◑◒'
		i=0
		while ps -p $pid > /dev/null 2>&1; do
			idx=$((i % 4))
			char=$(printf '%s' "$sp" | awk -v i=$((idx+1)) '{print substr($0,i,1)}')
			printf "\r$char $title..." >&2
			i=$((i + 1))
			sleep 0.15
		done
	else
		# CI/CD режим - статический вывод без анимации
		printf "⠿ $title...\n" >&2
		wait $pid
	fi

	# Ожидаем завершения процесса (для TTY режима)
	if is_tty; then
		wait $pid
	fi
	exit_code=$?

	# Вывод результата
	if [ $exit_code -eq 0 ]; then
		if is_tty; then
			printf "\r${COLOR_SUCCESS}✓${COLOR_RESET} $title   \n" >&2
		else
			printf "${COLOR_SUCCESS}✓${COLOR_RESET} $title\n" >&2
		fi
	else
		if is_tty; then
			printf "\r${COLOR_ERROR}✗${COLOR_RESET} $title   \n" >&2
		else
			printf "${COLOR_ERROR}✗${COLOR_RESET} $title\n" >&2
		fi
		cat "$tmpfile" >&2
	fi

	rm -f "$tmpfile"
	return $exit_code
}

# ===================================
# Интерактивное меню
# ===================================

# Интерактивное меню со стрелками
# Использование: choice=$(select_menu "option1" "option2" "option3")
# Возвращает: выбранную опцию через stdout, exit code 0 при успехе, 1 при отмене (ESC)
select_menu() {
	# Вспомогательные функции для работы с терминалом
	_cursor_blink_off() { printf "\033[?25l" >/dev/tty; }
	_cursor_blink_on() { printf "\033[?25h" >/dev/tty; }
	_cursor_up() { printf "\033[%dA\r" "$1" >/dev/tty; }
	_print_option() { printf "  %s\033[K\r\n" "$1" >/dev/tty; }
	_print_selected() { printf "${COLOR_SUCCESS}▶${COLOR_RESET} %s\033[K\r\n" "$1" >/dev/tty; }

	# Сохраняем текущее состояние stdin/stderr
	exec 3<&0 4>&2

	# Открываем /dev/tty для ввода и вывода
	exec < /dev/tty
	exec 2> /dev/tty

	# Опции из параметров
	num_options=$#
	selected=0

	# Сохраняем старые настройки терминала
	old_stty=$(stty -g </dev/tty)
	# shellcheck disable=SC2064
	trap "stty $old_stty </dev/tty; _cursor_blink_on; exec 0<&3 2>&4; exec 3<&- 4>&-" INT TERM EXIT

	# Вспомогательная функция для отрисовки меню
	_redraw_menu() {
		local sel="$1"
		shift
		local i=0
		for opt in "$@"; do
			if [ $i -eq "$sel" ]; then
				_print_selected "$opt"
			else
				_print_option "$opt"
			fi
			i=$((i + 1))
		done
		printf "\033[90m  используйте ↑↓ и Enter, ESC для отмены\033[0m" >/dev/tty
	}

	# Настройки терминала для сырого ввода
	_cursor_blink_off
	stty raw -echo min 1 time 0 </dev/tty

	# Рисуем начальное меню
	_redraw_menu "$selected" "$@"

	# Главный цикл
	while true; do
		# Читаем один байт из /dev/tty
		key=$(dd bs=1 count=1 </dev/tty 2>/dev/null)

		# Проверяем на ESC последовательность
		if [ "$key" = "$(printf '\033')" ]; then
			# Читаем следующий байт без блокировки (с минимальным timeout)
			old_stty_temp=$(stty -g </dev/tty)
			stty raw -echo min 0 time 1 </dev/tty
			key2=$(dd bs=1 count=1 </dev/tty 2>/dev/null || true)
			stty "$old_stty_temp" </dev/tty

			if [ -z "$key2" ]; then
				# Просто ESC нажат без последующих символов - выход с кодом 1 (отмена)
				printf "\r\033[K" >/dev/tty
				stty "$old_stty" </dev/tty
				_cursor_blink_on
				trap - INT TERM EXIT
				exec 0<&3 2>&4
				exec 3<&- 4>&-
				return 1
			elif [ "$key2" = "[" ]; then
				# Читаем код стрелки
				key=$(dd bs=1 count=1 </dev/tty 2>/dev/null)
				case "$key" in
					"A")  # Стрелка вверх
						selected=$((selected - 1))
						[ $selected -lt 0 ] && selected=$((num_options - 1))

						# Очищаем текущую строку (подсказка) и возвращаемся к началу меню
						printf "\r\033[K" >/dev/tty
						_cursor_up $num_options
						_redraw_menu "$selected" "$@"
						;;
					"B")  # Стрелка вниз
						selected=$((selected + 1))
						[ $selected -ge $num_options ] && selected=0

						# Очищаем текущую строку (подсказка) и возвращаемся к началу меню
						printf "\r\033[K" >/dev/tty
						_cursor_up $num_options
						_redraw_menu "$selected" "$@"
						;;
				esac
			fi
		elif [ "$key" = "$(printf '\n')" ] || [ "$key" = "$(printf '\r')" ]; then
			# Enter нажат - очищаем подсказку и выходим
			printf "\r\033[K" >/dev/tty
			break
		elif [ "$key" = "$(printf '\003')" ]; then
			# Ctrl+C нажат - очищаем подсказку и выход с кодом 130
			printf "\r\033[K" >/dev/tty
			stty "$old_stty" </dev/tty
			_cursor_blink_on
			trap - INT TERM EXIT
			exec 0<&3 2>&4
			exec 3<&- 4>&-
			exit 130
		fi
	done

	# Восстанавливаем терминал
	stty "$old_stty" </dev/tty
	_cursor_blink_on

	# Отключаем trap перед ручным восстановлением
	trap - INT TERM EXIT

	# Восстанавливаем stdin/stderr
	exec 0<&3 2>&4
	exec 3<&- 4>&-

	# Возвращаем выбранную опцию в stdout
	eval "selected_option=\${$((selected + 1))}"
	# shellcheck disable=SC2154
	echo "$selected_option"
	return 0
}

# ===================================
# Интерактивные функции
# ===================================

# Запрос подтверждения через меню выбора
# Параметр: $1 - вопрос
# Возвращает: 0 если "Да", 1 если "Нет" или ESC
# Использование: if ask_yes_no "Продолжить?"; then ...
ask_yes_no() {
	printf "${COLOR_WARNING}? ${COLOR_RESET}%s\n" "$1" >&2
	choice=$(select_menu "Да" "Нет") || {
		log_info "Отменено"
		return 1
	}
	[ "$choice" = "Да" ]
}

# Запросить текстовый ввод от пользователя
# Параметры:
#   $1 - текст запроса (prompt) или placeholder/default (если $2 не указан)
#   $2 - (опционально) default значение - если указано и ввод пустой, вернет default
# Возвращает: введенный текст (или default, если указан $2 и ввод пустой)
# Примеры:
#   url=$(ask_input "Git URL (ssh или https)")                    # Простой ввод, placeholder серым
#   url=$(ask_input "URL удалённого репозитория" "")              # С пустым default
#   name=$(ask_input "Имя модуля" "example-module")               # С дефолтом в квадратных скобках
ask_input() {
	if [ -n "$2" ]; then
		# Режим с дефолтным значением - показываем в квадратных скобках
		printf "${COLOR_INFO}➜ ${COLOR_RESET}%s ${COLOR_DIM}[%s]${COLOR_RESET}: " "$1" "$2" >&2
		read -r input_value </dev/tty
		if [ -z "$input_value" ]; then
			echo "$2"
		else
			echo "$input_value"
		fi
	else
		# Режим без дефолта - показываем placeholder серым
		printf "${COLOR_INFO}➜ ${COLOR_RESET}${COLOR_DIM}%s${COLOR_RESET}: " "$1" >&2
		read -r input_value </dev/tty
		printf "%s" "$input_value"
	fi
}

