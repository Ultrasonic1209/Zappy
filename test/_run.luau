-- filename: _run.luau

-- require test files and call the returned function
require("./runs")()

-- initialize a reporter (there is currently only one... this one, but you can make your own!)
local lune_console_reporter = require("@frktest/reporters/lune_console_reporter")
lune_console_reporter.init()

-- run the tests
local frktest = require("@frktest/frktest")
frktest.run()