local ns = select(2, ...)

ns:RegisterLocale("ptBR", {
    TAB_TOOLTIP = "BoE — Saque da área do AllTheThings",
    REFRESH_TOOLTIP = "Limpa o cache do Boeloot e relê no AllTheThings o saque da instância selecionada.",
    NO_INSTANCE = "Selecione uma raide ou masmorra no Guia de Aventuras.",
    NO_DATA = "O AllTheThings não contém itens equipáveis no Saque da área para esta instância e dificuldade.",
    ATT_MISSING = "O AllTheThings não está instalado ou está desativado.",
    ATT_LOADING = "O AllTheThings ainda está carregando o banco de dados…",
    ATT_INCOMPATIBLE = "A API instalada do AllTheThings é incompatível com o Boeloot.",
    ATT_INSTANCE_MISSING = "Esta instância não está presente no banco de dados do AllTheThings.",
    TRASH = "Inimigos comuns",
    UNKNOWN = "Desconhecido",
    ITEM_FALLBACK = "Item %d",
    REFRESHED = "Os dados do AllTheThings para a instância selecionada foram atualizados.",
    CACHE_CLEARED = "Cache temporário limpo.",
    COMMAND_HELP = "Comandos: /boeloot, refresh, clear, status",
    JOURNAL_LOAD_FAILED = "Não foi possível carregar Blizzard_EncounterJournal: %s",
})
