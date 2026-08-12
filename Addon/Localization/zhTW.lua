local ns = select(2, ...)

ns:RegisterLocale("zhTW", {
    TAB_TOOLTIP = "BoE — AllTheThings區域掉落",
    REFRESH_TOOLTIP = "清除Boeloot快取，並從AllTheThings重新讀取所選副本的掉落。",
    NO_INSTANCE = "請在冒險指南中選擇一個團隊副本或地城。",
    NO_DATA = "AllTheThings的區域掉落中沒有適用於此副本和難度的可裝備物品。",
    ATT_MISSING = "AllTheThings未安裝或已停用。",
    ATT_LOADING = "AllTheThings仍在載入資料庫…",
    ATT_INCOMPATIBLE = "已安裝的AllTheThings API與Boeloot不相容。",
    ATT_INSTANCE_MISSING = "AllTheThings資料庫中沒有此副本。",
    TRASH = "小怪",
    UNKNOWN = "未知",
    ITEM_FALLBACK = "物品 %d",
    REFRESHED = "已重新整理所選副本的AllTheThings資料。",
    CACHE_CLEARED = "執行階段快取已清除。",
    COMMAND_HELP = "指令：/boeloot、refresh、clear、status",
    JOURNAL_LOAD_FAILED = "無法載入Blizzard_EncounterJournal：%s",
})
