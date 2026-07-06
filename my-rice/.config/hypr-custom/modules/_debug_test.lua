hl.on("workspace.active", function(ws)
    local monInfo = "ws.monitor is nil"
    if ws.monitor ~= nil then
        monInfo = "ws.monitor.name = " .. tostring(ws.monitor.name)
    end
    local line = "ws.id=" .. tostring(ws.id) .. " | " .. monInfo .. "\n"
    local f = io.open(os.getenv("HOME") .. "/.config/hypr/modules/_debug_test.log", "a")
    if f then
        f:write(line)
        f:close()
    end
end)
