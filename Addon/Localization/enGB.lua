local _, ns = ...

ns:RegisterLocale("enGB", {
    TAB_TOOLTIP = "BoE — Zone Drops from AllTheThings",
    REFRESH_TOOLTIP = "Clear the Boeloot cache and read the selected instance's loot from AllTheThings again.",
    NO_INSTANCE = "Select a raid or dungeon in the Adventure Guide.",
    NO_DATA = "AllTheThings has no equippable items in Zone Drops for this instance and difficulty.",
    ATT_MISSING = "AllTheThings is not installed or is disabled.",
    ATT_LOADING = "AllTheThings is still loading its database…",
    ATT_INCOMPATIBLE = "The installed AllTheThings API is incompatible with Boeloot.",
    ATT_INSTANCE_MISSING = "This instance is not present in the AllTheThings database.",
    TRASH = "Trash",
    UNKNOWN = "Unknown",
    ITEM_FALLBACK = "Item %d",
    REFRESHED = "AllTheThings data refreshed for the selected instance.",
    CACHE_CLEARED = "Runtime cache cleared.",
    COMMAND_HELP = "Commands: /boeloot, refresh, clear, status",
    JOURNAL_LOAD_FAILED = "Unable to load Blizzard_EncounterJournal: %s",
})
