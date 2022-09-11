local Promise = require("Promise")

--- In order to distinguish between a dead coroutine and one that has thrown an error
--- we will compere the second returned value of 'coroutine.resume()' against this constant.
---@type string
local DEAD_COROUTINE_ERROR_MSG = (function()
    local co = coroutine.create(function() end)
    coroutine.resume(co) -- success
    local _, res = coroutine.resume(co) -- res == "cannot resume dead coroutine" or some other stable message
    return res
end)()

---@param body fun(...): any   @ a coroutine which yields a Promise and expects its result
---@return fun(...): Promise
local async = function (body)
    return function (...)
        local co = coroutine.create(body)
        local lastValidResult
        local function continuation(...)
            local cont, pRes = coroutine.resume(co, ...)
            if not cont then
                -- coroutine completed successfully
                if pRes == DEAD_COROUTINE_ERROR_MSG then
                    return Promise.isInstance(lastValidResult) and lastValidResult or Promise.resolve(lastValidResult)
                end
                return Promise.isInstance(pRes) and pRes or Promise.reject(pRes)
            end
            lastValidResult = pRes
            if not Promise.isInstance(pRes) then
                return continuation(pRes)
            end
            -- res is Promise
            return pRes:after(continuation)
        end
        return continuation(...)
    end
end

---@param promise Promise
local await = function (promise)
    return coroutine.yield(promise)
end

---@param body fun(): nil   @ a coroutine which yields a Promise and expects its result on resume
---@param onError nil | fun(error: any): any
---@param finally nil | fun(): any
local asyncTryCatchFinaly = function (body, onError, finally)
    local p = async(body)()
    p = onError and p:catch(onError) or p
    p = finally and p:finally(finally) or p
    await(p)
end

return function ()
    return async, await, asyncTryCatchFinaly
end
