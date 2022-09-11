local Promise = require("Promise")

local function test1()

    local callAfter ---@type fun(arg: string):nil

    local p = Promise.new(function (resolve, reject)
        -- resolve("hi! -1")
        callAfter = resolve
    end)

    p:after(function (res)
        print("Resolved to: " .. res)
        return "hi! -2"
    end)
    :catch(function (err)
        print("This should never print: " .. err)
    end)
    :after(function (res)
        print("Resolved to: " .. res)
        return Promise.resolve("hi! -3")
    end):catch(function (res)
        print("This should never print: " .. res)
    end):after(function (res)
        print("Resolved to: " .. res)
        error({msg = "hi! -4"})
    end):after(function (res)
        print("This should never print: " .. res)
    end):catch(function (res)
        print("Catched: " .. res.msg)
        error({msg = "hi! -5"})
    end):after(function (res)
        print("This should never print: " .. res)
    end):catch(function (res)
        print("Catched: " .. res.msg)
        return "hi! -6"
    end):after(function (res)
        print("Resolved to: " .. res)
        return Promise.reject("hi! -7")
    end):after(function (res)
        print("This should never print: " .. res)
    end)
    :finally(function ()
        print("Finally")
        error({msg = "hi! -7"})
    end) 
    :after(function (res)
            print("This should never print: " .. res)
        end, function (res)
            print("Catched: " .. res.msg)
        end
    )
    :finally(function ()
        collectgarbage("collect")
        print("SZ: " .. collectgarbage("count"))
    end)

    callAfter("hi! -1 async")
end

local function test()
    -- collectgarbage("collect")
    -- print("SZ: " .. collectgarbage("count"))

    for i = 1,1 do
        test1()
    end

    -- collectgarbage("collect")
    -- print("SZ: " .. collectgarbage("count"))
end

test()
