local baseUrl = "https://raw.githubusercontent.com/WGOS/cc/refs/heads/master/quarry-settings"
local blacklistName = "bl.txt"
local paramsName = "params.txt"
local quarryProgName = "quarry.lua"

fs.delete(blacklistName)
fs.delete(paramsName)
fs.delete(quarryProgName)

shell.execute("wget", baseUrl .. "/" .. blacklistName, blacklistName)
shell.execute("wget", baseUrl .. "/" .. paramsName, paramsName)
shell.execute("wget", baseUrl .. "/" .. quarryProgName, quarryProgName)

shell.execute(quarryProgName, "-file", "params.txt")