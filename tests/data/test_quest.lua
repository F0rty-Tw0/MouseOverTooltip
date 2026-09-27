local Assert = require("tests.helpers.assert")
local Quest = require("MouseOverTooltip.Data.Quest")

local function test_open_objective_gets_count_left()
  local text, done = Quest.Objective(" - 6/10 Boar slain")
  Assert.equal(text, " - 6/10 Boar slain (4 left)")
  Assert.equal(done, false)
end

local function test_done_objective_keeps_text_and_reports_done()
  local text, done = Quest.Objective(" - 10/10 Boar slain")
  Assert.equal(text, " - 10/10 Boar slain")
  Assert.equal(done, true)
end

local function test_classic_style_objective_is_parsed()
  local text, done = Quest.Objective("Boar slain: 3/8")
  Assert.equal(text, "Boar slain: 3/8 (5 left)")
  Assert.equal(done, false)
end

local function test_already_decorated_line_is_left_alone()
  Assert.equal(Quest.Objective(" - 6/10 Boar slain (4 left)"), nil)
end

local function test_non_objective_returns_nil()
  Assert.equal(Quest.Objective("Boar Hunt"), nil)
  Assert.equal(Quest.Objective(nil), nil)
end

return function()
  test_open_objective_gets_count_left()
  test_done_objective_keeps_text_and_reports_done()
  test_classic_style_objective_is_parsed()
  test_already_decorated_line_is_left_alone()
  test_non_objective_returns_nil()
end
