local _, ns = ...

ns:RegisterLocale("esMX", {
    TAB_TOOLTIP = "BoE — Botín de zona de AllTheThings",
    REFRESH_TOOLTIP = "Vacía la caché de Boeloot y vuelve a leer en AllTheThings el botín de la instancia seleccionada.",
    NO_INSTANCE = "Selecciona una banda o calabozo en la guía de aventuras.",
    NO_DATA = "AllTheThings no contiene objetos equipables en Botín de zona para esta instancia y dificultad.",
    ATT_MISSING = "AllTheThings no está instalado o está desactivado.",
    ATT_LOADING = "AllTheThings todavía está cargando su base de datos…",
    ATT_INCOMPATIBLE = "La API de AllTheThings instalada no es compatible con Boeloot.",
    ATT_INSTANCE_MISSING = "Esta instancia no está presente en la base de datos de AllTheThings.",
    TRASH = "Enemigos comunes",
    UNKNOWN = "Desconocido",
    ITEM_FALLBACK = "Objeto %d",
    REFRESHED = "Se actualizaron los datos de AllTheThings para la instancia seleccionada.",
    CACHE_CLEARED = "Caché temporal vaciada.",
    COMMAND_HELP = "Comandos: /boeloot, refresh, clear, status",
    JOURNAL_LOAD_FAILED = "No se pudo cargar Blizzard_EncounterJournal: %s",
})
