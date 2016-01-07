return function (payload)
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