local ns = select(2, ...)

local CACHE_SCHEMA = 1

ns.PersistentCache = {}

local function GetSignature()
    local _, attVersion = ns.ATTRepository:GetStatus()
    return {
        schema = CACHE_SCHEMA,
        attVersion = tostring(attVersion or "unknown"),
        locale = GetLocale(),
    }
end

local function MatchesSignature(db, signature)
    return type(db) == "table"
        and db.schema == signature.schema
        and db.attVersion == signature.attVersion
        and db.locale == signature.locale
end

function ns.PersistentCache:Initialize()
    local signature = GetSignature()
    if not MatchesSignature(BoelootDB, signature) then
        BoelootDB = {
            schema = signature.schema,
            attVersion = signature.attVersion,
            locale = signature.locale,
            expansions = {},
            instances = {},
        }
    end
    BoelootDB.expansions = type(BoelootDB.expansions) == "table" and BoelootDB.expansions or {}
    BoelootDB.instances = type(BoelootDB.instances) == "table" and BoelootDB.instances or {}
    self.db = BoelootDB
end

function ns.PersistentCache:EnsureReady()
    if not self.db then self:Initialize() end
    local signature = GetSignature()
    if not MatchesSignature(self.db, signature) then self:Initialize() end
end

function ns.PersistentCache:GetCollection(name)
    self:EnsureReady()
    return self.db[name]
end
