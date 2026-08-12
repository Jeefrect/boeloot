local ns = select(2, ...)

ns:RegisterLocale("koKR", {
    TAB_TOOLTIP = "BoE — AllTheThings 지역 전리품",
    REFRESH_TOOLTIP = "Boeloot 캐시를 비우고 선택한 인스턴스의 전리품을 AllTheThings에서 다시 읽습니다.",
    NO_INSTANCE = "모험 안내서에서 공격대 또는 던전을 선택하세요.",
    NO_DATA = "AllTheThings의 이 인스턴스와 난이도에 해당하는 지역 전리품에 착용 가능한 아이템이 없습니다.",
    ATT_MISSING = "AllTheThings가 설치되지 않았거나 비활성화되어 있습니다.",
    ATT_LOADING = "AllTheThings가 아직 데이터베이스를 불러오는 중입니다…",
    ATT_INCOMPATIBLE = "설치된 AllTheThings API가 Boeloot와 호환되지 않습니다.",
    ATT_INSTANCE_MISSING = "이 인스턴스가 AllTheThings 데이터베이스에 없습니다.",
    TRASH = "일반 몬스터",
    UNKNOWN = "알 수 없음",
    ITEM_FALLBACK = "아이템 %d",
    REFRESHED = "선택한 인스턴스의 AllTheThings 데이터를 새로 고쳤습니다.",
    CACHE_CLEARED = "임시 캐시를 비웠습니다.",
    COMMAND_HELP = "명령어: /boeloot, refresh, clear, status",
    JOURNAL_LOAD_FAILED = "Blizzard_EncounterJournal을 불러올 수 없습니다: %s",
})
