# {{MODULE_NAME}}

C модуль workspace, созданный автоматически.

## Технологический стек

- **Стек**: C
- **Тип**: {{TYPE}}
- **Система сборки**: Make
- **Компилятор**: GCC / Clang

## Сборка

```bash
# Из корня workspace
make {{MODULE_NAME}} make        # Сборка проекта
make {{MODULE_NAME}} make clean  # Очистка артефактов
make {{MODULE_NAME}} make all    # Полная пересборка
```

## Разработка

Этот модуль является частью polyglot workspace и разрабатывается с использованием host-first подхода (инструменты запускаются на хосте, если доступны, иначе в Alpine контейнере).

### Запуск

```bash
# После сборки запустить бинарник
make {{MODULE_NAME}} ./build/{{MODULE_NAME}}
```

### Тестирование

```bash
make {{MODULE_NAME}} make test   # Запуск тестов
```

### Отладка

```bash
# Сборка с debug символами
make {{MODULE_NAME}} make debug

# Запуск под GDB
make {{MODULE_NAME}} gdb ./build/{{MODULE_NAME}}
```

### Проверка кода

```bash
# clang-format (форматтер)
make {{MODULE_NAME}} clang-format -i src/*.c include/*.h

# cppcheck (статический анализ)
make {{MODULE_NAME}} cppcheck --enable=all src/

# valgrind (проверка утечек памяти)
make {{MODULE_NAME}} valgrind --leak-check=full ./build/{{MODULE_NAME}}
```

## Структура

```
.
├── src/              # Исходный код (.c файлы)
├── include/          # Заголовочные файлы (.h)
├── tests/            # Тесты
├── build/            # Артефакты сборки
├── Makefile          # Система сборки
├── .clang-format     # Конфигурация форматтера
└── README.md         # Документация
```

## Makefile команды

Основные команды определены в `Makefile` модуля:

- `make` или `make all` - Сборка проекта
- `make clean` - Очистка артефактов
- `make debug` - Сборка с debug информацией
- `make test` - Запуск тестов
- `make install` - Установка (если определена)

## Дополнительные команды

```bash
# Сборка с оптимизацией
make {{MODULE_NAME}} make CFLAGS="-O3"

# Сборка с предупреждениями
make {{MODULE_NAME}} make CFLAGS="-Wall -Wextra -Werror"

# Анализ размера бинарника
make {{MODULE_NAME}} size ./build/{{MODULE_NAME}}

# Дизассемблирование
make {{MODULE_NAME}} objdump -d ./build/{{MODULE_NAME}}
```
