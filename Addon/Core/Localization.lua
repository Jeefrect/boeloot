local ns = select(2, ...)

ns.L = {}

local activeLocale = GetLocale()

function ns:RegisterLocale(locale, strings)
    if locale ~= "enUS" and locale ~= activeLocale then return end

    for key, value in pairs(strings) do
        ns.L[key] = value
    end
end
