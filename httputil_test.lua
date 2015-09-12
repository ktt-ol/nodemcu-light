require("httputil")


function testRequest()
    local r = httputil.newRequest("GET / HTTP/1.1\r\n\r\n")
    assert(r.method == "GET")
    assert(r.path == "/", "path not / but " .. r.path)

    r = httputil.newRequest("GET /foo?bar=baz&foo=42 HTTP/1.1")
    assert(r.method == "GET")
    assert(r.path == "/foo", "path not /foo but " .. r.path)
    assert(r.args['bar'] == "baz", "bar!=baz")
    assert(r.args['foo'] == "42", "foo!=42")
end

function mockConnection()
    return {
        data = {},
        closed = false,
        send = function(c, d, callback)
            c.data[#c.data+1] = d
            if callback then
                return callback(c)
            end
        end,
        close = function(c)
            c.closed = true
        end,
    }
end

function testSendFile()
    local c = mockConnection()
    httputil.sendFile(c, "missingfile", "text/plain")
    assert(#c.data == 1)
    assert(c.data[1] == "HTTP/1.0 404 Not found\r\n\r\n")
    assert(c.closed)

    local c = mockConnection()
    httputil.sendFile(c, "httputil.lua", "text/plain")
    assert(#c.data >= 3)
    assert(c.data[1] == "HTTP/1.0 200 Ok\r\n")
    assert(c.data[2] == "Content-type: text/plain\r\n")
    assert(c.data[3] == "\r\n")
    assert(#c.data[4] == 1400) -- chunk size
    assert(c.closed)
end

function mockFile()
    local f
    return {
        open = function(filename, mode)
            f = io.open(filename, mode)
            if f then
                return true
            else
                return false
            end
        end,
        seek = function(pos)
            f:seek("set", pos)
        end,
        read = function(len)
            return f:read(len)
        end,
        close = function()
            f:close()
            f = nil
        end,
    }
end

httputil.file = mockFile()

testRequest()
testSendFile()