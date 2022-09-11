--[[ Promise implementation for lua ]]

---@alias FunArg1toNil fun(res: any): nil
---@alias FunArg1toAny fun(res: any): any

---@alias OnSettleFun fun(state: number, result: any): nil

---@class Promise
---@field after fun(self: Promise, onResolve: FunArg1toAny, onReject: FunArg1toAny?): Promise
---@field catch fun(self: Promise, onReject: FunArg1toAny): Promise
---@field finally fun(self: Promise, onFinally: fun(): any): Promise
---@field private __PromiseType__ "true"

local Promise = {}

---@param action fun(resolve: FunArg1toNil, reject: FunArg1toNil): nil
---@return Promise
function Promise.new(action)
    -- Private Promise state
    local state = 0         ---@type 0 | 1 | 2          @ 0 - Pending, 1 - Resolved, 2 - Rejected
    local result = nil      ---@type any                @ nil (if Pending) or Result (if Resolved) or Error (if Rejected)
    local OnSettleArr = {}  ---@type OnSettleFun[]      @ Call these on settle

    -- 'action' will call this with its result
    local resolve = function(res)
        if state ~= 0 then return end
        result = res
        state = 1
        for i,f in ipairs(OnSettleArr) do
            f(state, result)
        end
    end

    -- 'action' will call this with its error
    local reject = function(err)
        if state ~= 0 then return end
        result = err
        state = 2
        for i,f in ipairs(OnSettleArr) do
            f(state, result)
        end
    end

    -- execute action
    action(resolve, reject)

    -- implement Promise chaining via after() and catch()

    ---@param targetState 1 | 2
    ---@return fun(self: Promise, continuation: FunArg1toAny): Promise
    local continuationToPromise = function (targetState)
        ---@param self Promise
        ---@param continuation FunArg1toAny
        ---@return Promise
        return function (self, continuation)
            assert(Promise.isInstance(self), "Incorrect method call on Promise. Use ':', not '.'")

            if state == 0 then      -- Promise is yet to be settled
                return Promise.new(function (resolve, reject)
                    table.insert(OnSettleArr, function (state, result)
                        if state == targetState then        -- When Promise will settle to targetState
                            local ok, resultNext = pcall(continuation, result)
                            if ok and Promise.isInstance(resultNext) then
                                resultNext:after(resolve):catch(reject)
                            else
                                (ok and resolve or reject)(resultNext)
                            end
                        else                                -- When Promise will settle to NOT targetState
                            (targetState == 1 and reject or resolve)(result)
                        end
                    end)
                end)
            elseif state == targetState then    -- Promise have settled to targetState 
                local ok, resultNext = pcall(continuation, result)
                if ok and Promise.isInstance(resultNext) then
                    return resultNext           -- If continuation returnd a Promise, return it unmodified
                end
                return Promise.new(function (resolve, reject)
                    (ok and resolve or reject)(resultNext)
                end)
            end

            return self -- Promise have settled to NOT targetState 
        end
    end

    local afterResolve = continuationToPromise(1)
    local after = function (self, onResolve, onReject)
        local p = afterResolve(self, onResolve)
        return onReject and p:catch(onReject) or p
    end
    local catch = continuationToPromise(2)

    return {
        __PromiseType__ = true,
        after = after,
        catch = catch,
        finally = function (self, onFinally)
            local f = function () onFinally() end
            return after(self, f, f)
        end
    }
end

---@param result any
---@return Promise
function Promise.resolve(result)
    return Promise.new(function (resolve) resolve(result) end)
end

---@param result any
---@return Promise
function Promise.reject(result)
    return Promise.new(function (_, reject) reject(result) end)
end

---@param promise any
---@return boolean
function Promise.isInstance(promise)
    return type(promise) == "table" and promise.__PromiseType__
end

return Promise