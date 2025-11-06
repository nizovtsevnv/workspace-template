# Файловая структура рабочего пространства проекта

```
/
├── .editorconfig                 # Настройки форматирования кода для всех редакторов
├── .git/                         # Git repository
├── .gitignore                    # Базовые Git ignore правила
├── .gitmodules                   # Конфигурация git субмодулей
├── Makefile                      # Главный makefile с системой многоуровневых команд
├── README.md                     # Документация (шаблона или проекта)
├── .template/                    # Шаблонные файлы и инфраструктура
│   ├── makefiles/                # Модули системы автоматизации
│   │   ├── config.mk             # Конфигурация, переменные, определение окружения
│   │   ├── core.mk               # Базовые команды (init)
│   │   ├── help.mk               # Система справки с секциями и приоритетами
│   │   ├── devenv.mk             # Управление шаблоном (test, update)
│   │   └── modules.mk            # Работа с модулями (создание, команды)
│   ├── scripts/                  # Shell-скрипты (вся бизнес-логика)
│   │   ├── lib/                  # Переиспользуемые библиотеки
│   │   │   ├── ui.sh             # UI функции (логирование, меню, спиннеры)
│   │   │   ├── stack-runner.sh   # Запуск инструментов стеков (host-first + container-fallback)
│   │   │   ├── modules.sh        # Работа с модулями (детектирование, версии)
│   │   │   ├── git.sh            # Git операции (версии, теги)
│   │   │   ├── template.sh       # Операции с шаблоном
│   │   │   └── generator.sh      # Генераторы модулей
│   │   ├── module/               # Команды управления модулями
│   │   │   ├── command.sh        # Выполнение команд модулей (система приоритетов)
│   │   │   ├── create.sh         # Создание новых модулей (wizard)
│   │   │   ├── git.sh            # Git операции с модулями
│   │   │   ├── help.sh           # Справка по командам модулей
│   │   │   ├── import.sh         # Импорт модулей из git
│   │   │   └── generators/       # Генераторы для разных стеков
│   │   │       ├── nodejs.sh     # Генератор Node.js модулей
│   │   │       ├── php.sh        # Генератор PHP модулей
│   │   │       ├── python.sh     # Генератор Python модулей
│   │   │       ├── rust.sh       # Генератор Rust модулей
│   │   │       ├── c.sh          # Генератор C модулей
│   │   │       └── zig.sh        # Генератор Zig модулей
│   │   ├── template/             # Команды управления шаблоном
│   │   │   ├── help.sh           # Справка по командам шаблона
│   │   │   ├── test.sh           # Автотесты шаблона (shellcheck + smoke tests)
│   │   │   └── update.sh         # Обновление шаблона из upstream
│   │   ├── help.sh               # Главная справка (make help)
│   │   └── init.sh               # Инициализация проекта из шаблона
│   ├── dockerfiles/              # Dockerfiles для специализированных Alpine контейнеров
│   │   ├── sh.Dockerfile         # Shell-утилиты (shellcheck, jq, yq, bash, curl, git)
│   │   ├── nodejs.Dockerfile     # Node.js инструменты
│   │   ├── php.Dockerfile        # PHP инструменты
│   │   ├── python.Dockerfile     # Python инструменты
│   │   ├── rust.Dockerfile       # Rust инструменты
│   │   ├── c.Dockerfile          # C инструменты
│   │   └── zig.Dockerfile        # Zig инструменты
│   └── assets/                   # Конфигурации стандартов качества и шаблоны
│       ├── README.md             # Шаблон README для проекта (копируется при инициализации)
│       ├── nodejs/               # Node.js стандарты (eslint, prettier, tsconfig)
│       │   └── README.md         # Шаблон README для Node.js модулей
│       ├── php/                  # PHP стандарты (php-cs-fixer, phpcs, phpstan)
│       │   └── README.md         # Шаблон README для PHP модулей
│       ├── python/               # Python стандарты (flake8, ruff, pylint)
│       │   └── README.md         # Шаблон README для Python модулей
│       ├── rust/                 # Rust стандарты (rustfmt, clippy)
│       │   └── README.md         # Шаблон README для Rust модулей
│       ├── c/                    # C стандарты (clang-format, editorconfig)
│       │   └── README.md         # Шаблон README для C модулей
│       └── zig/                  # Zig стандарты
│           └── README.md         # Шаблон README для Zig модулей
├── doc/                          # Документация
│   ├── README.md                 # Описание структуры документации
│   ├── development/              # Документация процессов разработки (автообновляемая)
│   │   ├── template/             # Документация workspace шаблона
│   │   │   ├── generators.md     # Децентрализованные генераторы модулей
│   │   │   ├── makefile.md       # Документация системы автоматизации
│   │   │   ├── coding-style.md   # Правила оформления shell-скриптов
│   │   │   └── file-tree.md      # Этот файл
│   │   ├── standards/            # Стандарты разработки (принципы, требования)
│   │   │   └── .gitkeep
│   │   └── guides/               # Руководства по процессам (workflow, CI/CD)
│   │       └── .gitkeep
│   └── project/                  # Документация проекта (защищена от обновлений)
│       ├── .gitkeep              # Placeholder для защиты каталога
│       └── <module>/             # Документация модуля (одноименный каталог)
│           └── README.md         # Описание модуля
└── modules/                      # Git субмодули (компоненты проекта: сервисы, приложения, библиотеки)
    └── .gitkeep                  # Placeholder для защиты каталога от удаления из Git
```

## Примечания

- **Метаданные шаблона**: коммит определяется из git (`git rev-parse --short=7 HEAD`) или из файла `.template-commit`
- **Статус инициализации**: определяется наличием git remote 'template'
- **Файлы удаляемые при `make init`**: `README.md` (заменяется на `.template/assets/README.md`)
- **Шаблоны README**: `.template/assets/README.md` - для проекта, `.template/assets/<stack>/README.md` - для модулей
- **Документация**:
  - `doc/development/` - автоматически заменяется при `make template update`
  - `doc/project/` - защищена от обновлений
  - `doc/project/<module>/` - документация модуля в одноименном каталоге
- **Стиль кода**: см. [coding-style.md](coding-style.md) для правил оформления shell-скриптов
