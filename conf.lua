function love.conf(t)
    t.window.width = 1920
    t.window.height = 960
    if love._version_major > 11 then
        t.window.depth = true
    else
        t.window.depth = 24
    end
    t.window.title = "Menori Examples"
    t.window.vsync = true
    t.highdpi = true
    t.window.resizable = true
end
