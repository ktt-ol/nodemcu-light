local mimeTypes = {
    js = "application/javascript",
    html = "text/html",
    css = "text/css",
}

return function (c, filename)
    if not file.open(filename) then
        c:send("HTTP/1.0 404 Not found\r\n\r\n", function(c) c:close() end)
        return
    end
    file.close()

    local sent = 0
    local sendNextChunk = function (c)
        file.open(filename)
        file.seek("set", sent)
        local data = file.read(1460)
        file.close()

        if not data then
            c:close()
        else
            sent = sent + #data
            c:send(data, sendNextChunk)
        end
    end

    c:send("HTTP/1.0 200 Ok\r\n")

    local ext = filename:match(".(%w+)$")
    if ext == "gz" then
        c:send("Content-Encoding: gzip\r\n")
        ext = filename:match(".(%w+).gz$")
    end
    local contentType = mimeTypes[ext]
    if contentType then
        c:send("Content-type: " .. contentType .. "\r\n")
    end
    c:send("\r\n", sendNextChunk)
end