local ns = select(2, ...)

ns.Events = {
    ATT_DATA_READY = "ATT_DATA_READY",
    listeners = {},
}

function ns.Events:Register(event, listener)
    local listeners = self.listeners[event]
    if not listeners then
        listeners = {}
        self.listeners[event] = listeners
    end
    listeners[#listeners + 1] = listener
end

function ns.Events:Emit(event, ...)
    for _, listener in ipairs(self.listeners[event] or {}) do
        listener(...)
    end
end
