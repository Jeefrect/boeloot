local _, ns = ...

ns:RegisterLocale("frFR", {
    TAB_TOOLTIP = "BoE — Butin de zone d’AllTheThings",
    REFRESH_TOOLTIP = "Vide le cache de Boeloot et relit dans AllTheThings le butin de l’instance sélectionnée.",
    NO_INSTANCE = "Sélectionnez un raid ou un donjon dans le guide de l’aventurier.",
    NO_DATA = "AllTheThings ne contient aucun objet équipable dans le Butin de zone pour cette instance et cette difficulté.",
    ATT_MISSING = "AllTheThings n’est pas installé ou est désactivé.",
    ATT_LOADING = "AllTheThings charge encore sa base de données…",
    ATT_INCOMPATIBLE = "L’API AllTheThings installée n’est pas compatible avec Boeloot.",
    ATT_INSTANCE_MISSING = "Cette instance n’est pas présente dans la base de données d’AllTheThings.",
    TRASH = "Ennemis communs",
    UNKNOWN = "Inconnu",
    ITEM_FALLBACK = "Objet %d",
    REFRESHED = "Les données d’AllTheThings ont été actualisées pour l’instance sélectionnée.",
    CACHE_CLEARED = "Cache temporaire vidé.",
    COMMAND_HELP = "Commandes : /boeloot, refresh, clear, status",
    JOURNAL_LOAD_FAILED = "Impossible de charger Blizzard_EncounterJournal : %s",
})
