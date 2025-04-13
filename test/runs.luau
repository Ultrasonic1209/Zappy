local frktest = require("@frktest/frktest")
local test = frktest.test
local check = frktest.assert.check
local req = frktest.assert.require

local zap = require("../src/Zappy/zap")

return function()
    test.case("runs with valid IDL", function()
        local resp = zap([[
funct Test = {
    call: Async,
    args: (Foo: u8, Bar: string),
    rets: enum { Success, Fail }
}
        ]], true)

        req.not_nil(resp.client)
        req.not_nil(resp.server)
    end)

end