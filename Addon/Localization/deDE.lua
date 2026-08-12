local ns = select(2, ...)

ns:RegisterLocale("deDE", {
    TAB_TOOLTIP = "BoE — Gebietsbeute aus AllTheThings",
    REFRESH_TOOLTIP = "Leert den Boeloot-Zwischenspeicher und liest die Beute der ausgewählten Instanz erneut aus AllTheThings.",
    NO_INSTANCE = "Wählt einen Schlachtzug oder Dungeon im Abenteuerführer aus.",
    NO_DATA = "AllTheThings enthält für diese Instanz und diesen Schwierigkeitsgrad keine ausrüstbaren Gegenstände unter Gebietsbeute.",
    ATT_MISSING = "AllTheThings ist nicht installiert oder deaktiviert.",
    ATT_LOADING = "AllTheThings lädt seine Datenbank noch…",
    ATT_INCOMPATIBLE = "Die installierte AllTheThings-API ist nicht mit Boeloot kompatibel.",
    ATT_INSTANCE_MISSING = "Diese Instanz ist nicht in der AllTheThings-Datenbank enthalten.",
    TRASH = "Trash",
    UNKNOWN = "Unbekannt",
    ITEM_FALLBACK = "Gegenstand %d",
    REFRESHED = "Die AllTheThings-Daten für die ausgewählte Instanz wurden aktualisiert.",
    CACHE_CLEARED = "Laufzeit-Zwischenspeicher geleert.",
    COMMAND_HELP = "Befehle: /boeloot, refresh, clear, status",
    JOURNAL_LOAD_FAILED = "Blizzard_EncounterJournal konnte nicht geladen werden: %s",
})
