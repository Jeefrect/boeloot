local _, ns = ...

ns:RegisterLocale("itIT", {
    TAB_TOOLTIP = "BoE — Bottino di zona da AllTheThings",
    REFRESH_TOOLTIP = "Svuota la cache di Boeloot e rilegge da AllTheThings il bottino dell’istanza selezionata.",
    NO_INSTANCE = "Seleziona un’incursione o una spedizione nella Guida alle Avventure.",
    NO_DATA = "AllTheThings non contiene oggetti equipaggiabili nel Bottino di zona per questa istanza e difficoltà.",
    ATT_MISSING = "AllTheThings non è installato o è disattivato.",
    ATT_LOADING = "AllTheThings sta ancora caricando il database…",
    ATT_INCOMPATIBLE = "L’API di AllTheThings installata non è compatibile con Boeloot.",
    ATT_INSTANCE_MISSING = "Questa istanza non è presente nel database di AllTheThings.",
    TRASH = "Nemici comuni",
    UNKNOWN = "Sconosciuto",
    ITEM_FALLBACK = "Oggetto %d",
    REFRESHED = "I dati di AllTheThings per l’istanza selezionata sono stati aggiornati.",
    CACHE_CLEARED = "Cache temporanea svuotata.",
    COMMAND_HELP = "Comandi: /boeloot, refresh, clear, status",
    JOURNAL_LOAD_FAILED = "Impossibile caricare Blizzard_EncounterJournal: %s",
})
