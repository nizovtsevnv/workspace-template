#!/bin/sh
# ===================================
# C Module Generator
# ===================================
# Генератор модулей для C
# Использование: generate-c.sh <type> <name> <target_dir>
# Типы: makefile, cmake

set -e

# Загрузка общих функций
# Используем относительный путь от текущего файла
. "$(dirname "$0")/../../lib/generator-common.sh"

# Параметры
MODULE_TYPE="$1"
MODULE_NAME="$2"
MODULE_TARGET="$3"

# Валидация параметров
validate_generator_params "$MODULE_TYPE" "$MODULE_NAME" "$MODULE_TARGET" "makefile, cmake" || exit 1

# Создать структуру директорий
mkdir -p "$MODULE_TARGET/$MODULE_NAME/src"
mkdir -p "$MODULE_TARGET/$MODULE_NAME/include"

# Создать main.c
cat > "$MODULE_TARGET/$MODULE_NAME/src/main.c" <<EOF
#include <stdio.h>

int main(void) {
    printf("Hello from $MODULE_NAME!\\n");
    return 0;
}
EOF

# ===================================
# Генераторы по типам
# ===================================

case "$MODULE_TYPE" in
	makefile)
		# Создать Makefile
		cat > "$MODULE_TARGET/$MODULE_NAME/Makefile" <<'EOF'
CC = gcc
CFLAGS = -Wall -Wextra -std=c11 -Iinclude
TARGET = $(shell basename $(CURDIR))
SRC = $(wildcard src/*.c)
OBJ = $(SRC:.c=.o)

all: $(TARGET)

$(TARGET): $(OBJ)
	$(CC) $(CFLAGS) -o $@ $^

%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

test:
	@echo "c test passed"

clean:
	rm -f $(OBJ) $(TARGET)

.PHONY: all test clean
EOF
		;;

	cmake)
		# Создать CMakeLists.txt
		cat > "$MODULE_TARGET/$MODULE_NAME/CMakeLists.txt" <<EOF
cmake_minimum_required(VERSION 3.20)
project($MODULE_NAME C)

set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)

include_directories(include)
file(GLOB SOURCES "src/*.c")

add_executable(\${PROJECT_NAME} \${SOURCES})

add_custom_target(test
    COMMAND echo "c test passed"
)
EOF
		;;

	*)
		handle_unknown_type "$MODULE_TYPE" "makefile, cmake"
		;;
esac

# Копирование конфигураций из assets
copy_stack_assets "c" "$MODULE_TARGET/$MODULE_NAME"

# Завершение
finish_generator "C" "$MODULE_TARGET/$MODULE_NAME"
