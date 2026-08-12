local ns = select(2, ...)

ns:RegisterLocale("zhCN", {
    TAB_TOOLTIP = "BoE — AllTheThings区域掉落",
    REFRESH_TOOLTIP = "清除Boeloot缓存，并从AllTheThings重新读取所选副本的掉落。",
    NO_INSTANCE = "请在冒险指南中选择一个团队副本或地下城。",
    NO_DATA = "AllTheThings的区域掉落中没有适用于此副本和难度的可装备物品。",
    ATT_MISSING = "AllTheThings未安装或已禁用。",
    ATT_LOADING = "AllTheThings仍在加载数据库…",
    ATT_INCOMPATIBLE = "已安装的AllTheThings API与Boeloot不兼容。",
    ATT_INSTANCE_MISSING = "AllTheThings数据库中没有此副本。",
    TRASH = "小怪",
    UNKNOWN = "未知",
    ITEM_FALLBACK = "物品 %d",
    REFRESHED = "已刷新所选副本的AllTheThings数据。",
    CACHE_CLEARED = "运行时缓存已清除。",
    COMMAND_HELP = "命令：/boeloot、refresh、clear、status",
    JOURNAL_LOAD_FAILED = "无法加载Blizzard_EncounterJournal：%s",
    ITEM_ID_BUTTON = "ID",
    COPY_ITEM_ID_TOOLTIP = "复制物品 ID",
    COPY_ITEM_ID_PROMPT = "按 Ctrl+C 复制物品 ID。",
})
