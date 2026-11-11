--!nocheck
-- School Hub router. Picks the module for the current place.

local BASE = "https://raw.githubusercontent.com/bryantcamp321-tech/school-hub/main/"
local VERSION = "3"

local MODULES = {
    [82854191372599] = "mechanic-legends.lua", -- Mechanic Legends
}

local file = MODULES[game.PlaceId]

if not file then
    return warn("[School Hub] no module for place " .. game.PlaceId)
end

local url = BASE .. file .. "?v=" .. VERSION

local ok, body = pcall(game.HttpGet, game, url)
if not ok then
    return warn("[School Hub] fetch failed: " .. tostring(body))
end

local chunk, compileErr = loadstring(body)
if not chunk then
    return warn("[School Hub] compile failed: " .. tostring(compileErr))
end

local ran, runErr = pcall(chunk)
if not ran then
    warn("[School Hub] runtime error: " .. tostring(runErr))
end
