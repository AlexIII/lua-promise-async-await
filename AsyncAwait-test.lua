print("Start: " .. collectgarbage("count"))
local async, await, asyncTryCatchFinaly = require("AsyncAwait")()
local Promise = require("Promise")
print("After load: " .. collectgarbage("count"))


local function runAll()
    ---@type fun()[]
    local callLater = {}

    ---@param ms number
    ---@param result any
    ---@param toReject boolean?
    ---@return Promise
    local asyncDelay = function (ms, result, toReject)
        return Promise.new(function (resolve, reject)
            -- test for Node MCU
            -- local mytimer = tmr.create()
            -- mytimer:register(ms, tmr.ALARM_SINGLE, function () (toReject and reject or resolve)(result) end)
            -- mytimer:start()

            -- (toReject and reject or resolve)(result)

            table.insert(callLater, function () (toReject and reject or resolve)(result) end)
        end)
    end

    ---@param p Promise
    local test1 = async(function (p)
        print("Started")
        local pre = await(p)
        print(pre .. " Resolved to: " .. await(asyncDelay(1000, "1 sec")))
        print(pre .. " Resolved to: " .. await(asyncDelay(1000, "2 sec")))
        print(pre .. " Resolved to: " .. await(asyncDelay(1000, "3 sec")))
        if pre == "me 2" then
            error(Promise.reject(pre .. " ooopse"))
            -- error(" ooopse")
        end
        print(pre .. " Resolved to: " .. await(asyncDelay(1000, "4 sec")))
        print(pre .. " Resolved to: " .. await(asyncDelay(1000, "5 sec")))
        return pre .. " the end!"
    end)

    ---@param name string
    local test2 = async(function (name)
        asyncTryCatchFinaly(function ()
            await(test1(Promise.resolve(name)))
        end, function (error)
            print("catched", name, error)
        end, function ()
            print("finally", name)
        end)
        return name .. " the end!"
    end)

    test2("me 1"):after(print):catch(function (err)
        print("me 1 err:", err)
    end)
    -- test2("me 2"):after(print):catch(function (err)
    --     print("me 2 err:", err)
    -- end)


    print("Before run: " .. collectgarbage("count"))
    for i,f in ipairs(callLater) do
        f()
        callLater[i] = nil
    end
    print("After run: " .. collectgarbage("count"))

end

runAll()

collectgarbage("collect")
print("Collected: " .. collectgarbage("count"))