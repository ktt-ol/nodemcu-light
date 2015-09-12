if srv then
    srv:close()
    srv = nil
end

-- wifi.sta.config("bwlan", "73CV44767R668RKR")
wifi.setmode(wifi.STATION)
wifi.sta.config("mainframe-legacy", "spacebeta")
wifi.sta.connect()

tmr.alarm(1, 1000, 1, function()
    if wifi.sta.getip()== nil then
        print("IP unavaiable, Waiting...")
    else
        tmr.stop(1)
        print("ESP8266 mode is: " .. wifi.getmode())
        print("The module MAC address is: " .. wifi.ap.getmac())
        print("Config done, IP is " .. wifi.sta.getip())
     end
end)

-- http://www.nxp.com/documents/data_sheet/TDA8444.pdf

pin_sda = 6 -- GPIO12
pin_scl = 7 -- GPIO13
i2c.setup(0, pin_sda, pin_scl, i2c.SLOW)


function debounce(ms, func)
    local last = 0
    local delay = ms * 1000

    return function (...)
        local now = tmr.now()
        if now - last < delay then return end

        last = now
        return func(...)
    end
end

brightness = 0
gpio.mode(5, gpio.INPUT, gpio.PULLUP)
gpio.trig(5, "low", debounce(200,
    function()
        brightness = brightness + 64
        if brightness > 255 then
            brightness = 0
        end
        dofile("rgbtube.lc")(brightness, brightness, brightness, brightness)
    end)
)

function hangup(conn)
    conn:close()
end

-- A simple http server
srv = net.createServer(net.TCP)
srv:listen(80, function(conn)
  conn:on("receive", function(conn, payload)
    dofile("httputil.lc")
    local r = httputil.newRequest(payload)
    if not r then
        print("bad request")
        conn:close()
        return
    end
    if r.path == '/rgb' then
        dofile("rgbtube.lc")(
            tonumber(r.args['r']),
            tonumber(r.args['g']),
            tonumber(r.args['b']))
        conn:send(httputil.okHeader, hangup)
    elseif r.path == '/' or r.path:match('^/static/') then
        local fname = r.path:match('^/static/(.*)')
        if not fname then fname = "index.html" end
        httputil.sendFile(conn, "static-" .. fname)
    elseif r.path == '/heap' then
        conn:send(tostring(node.heap()), hangup)
    else
        conn:send("HTTP/1.0 404 Not found\r\n\r\n", hangup)
    end
  end)
end)


-- 1a:fe:34:fa:f5:20

-- dofile("rgb_i2c.lua")
