httputil = {}

-- allow mocking of file for tests
if file then
    httputil.file = file
end

httputil.newRequest = function (payload)
    local r = {}
    local path, args

    if not payload then
        return
    end

    r.method, path = payload:match("(%u+) (%S+) HTTP/1.[01]")

    if not path then
        return
    end

    q = path:find("?")
    if q then
        r.path = path:sub(1, q-1)
        args = path:sub(q+1)
    else
        r.path = path
    end

    r.args = {}
    if args then
        for k, v in string.gmatch(args, "(%w+)=([^&#]+)&*") do
            r.args[k] = v
        end
    end

    return r
end

mimeTypes = {
    js = "application/javascript",
    html = "text/html",
    css = "text/css",
}

httputil.okHeader = "HTTP/1.0 200 Ok\r\n\r\n"

httputil.sendFile = function (c, filename, contentType)
    local sent = 0
    local chunkSize = 1400

    if not httputil.file.open(filename) then
        c:send("HTTP/1.0 404 Not found\r\n\r\n", function(c) c:close() end)
        return
    end
    httputil.file.close()

    sendNextChunk = function (c)
        httputil.file.open(filename)
        httputil.file.seek("set", sent)
        local data = httputil.file.read(chunkSize)
        httputil.file.close()

        if not data then
            c:close()
        else
            sent = sent + data:len()
            c:send(data, sendNextChunk)
        end
    end

    c:send("HTTP/1.0 200 Ok\r\n")

    local ext = filename:match(".(%w+)$")
    if ext == "gz" then
        c:send("Content-Encoding: gzip\r\n")
        ext = filename:match(".(%w+).gz$")
    end
    if not contentType then
        contentType = mimeTypes[ext]
    end
    if contentType and type(contentType) == "string" then
        c:send("Content-type: " .. contentType .. "\r\n")
    end
    c:send("\r\n", sendNextChunk)
end

httputil.newResponse = function (c, status, headers)
    local headerSent = false

    if headers == nil then
        headers = {}
    end

    local sendHeader = function ()
        c:send("HTTP/1.0 " .. status .. "\r\n")
        for k, v in ipairs(headers) do
            c:send(k .. ": " .. v .. "\r\n")
        end
        c:send("\r\n")
        headerSent = true
    end
    local send = function (data)
        if not headerSent then
            sendHeader()
        end
        c:send(data)
    end

    return {
        send = send
    }
end
