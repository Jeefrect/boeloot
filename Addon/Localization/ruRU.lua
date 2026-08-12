local ns = select(2, ...)

ns:RegisterLocale("ruRU", {
    TAB_TOOLTIP = "BoE — добыча локации из AllTheThings",
    REFRESH_TOOLTIP = "Очистить кеш Boeloot и заново прочитать добычу выбранного подземелья или рейда из AllTheThings.",
    NO_INSTANCE = "Выберите рейд или подземелье в Путеводителе по приключениям.",
    NO_DATA = "В добыче локации AllTheThings нет экипируемых предметов для выбранного инстанса и сложности.",
    ATT_MISSING = "AllTheThings не установлен или отключён.",
    ATT_LOADING = "AllTheThings всё ещё загружает свою базу данных…",
    ATT_INCOMPATIBLE = "API установленной версии AllTheThings несовместим с Boeloot.",
    ATT_INSTANCE_MISSING = "Этого инстанса нет в базе данных AllTheThings.",
    TRASH = "Обычные противники",
    UNKNOWN = "Неизвестно",
    ITEM_FALLBACK = "Предмет %d",
    REFRESHED = "Данные AllTheThings для выбранного инстанса обновлены.",
    CACHE_CLEARED = "Временный кеш очищен.",
    COMMAND_HELP = "Команды: /boeloot, refresh, clear, status",
    JOURNAL_LOAD_FAILED = "Не удалось загрузить Blizzard_EncounterJournal: %s",
    ITEM_ID_BUTTON = "ID",
    COPY_ITEM_ID_TOOLTIP = "Скопировать ID предмета",
    COPY_ITEM_ID_PROMPT = "Нажмите Ctrl+C, чтобы скопировать ID предмета.",
})
