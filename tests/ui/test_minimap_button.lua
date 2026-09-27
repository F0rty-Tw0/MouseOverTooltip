local Assert = require("tests.helpers.assert")
local Wow = require("tests.helpers.wow")
local W = Wow.Install()

_G.Minimap.GetWidth = function()
  return 140
end
_G.Minimap.centerX, _G.Minimap.centerY = 100, 100
local MinimapButton = require("MouseOverTooltip.UI.MinimapButton")

local function button()
  return _G.MouseOverTooltipMinimapButton
end

local function test_hidden_button_is_never_created()
  MinimapButton.SetShown({ minimapAngle = 225 }, false)
  Assert.equal(button(), nil)
end

local function test_click_runs_handler()
  local clicks = 0
  MinimapButton.SetShown({ minimapAngle = 225 }, true, function()
    clicks = clicks + 1
  end)
  button():Fire("OnClick", "LeftButton")
  Assert.equal(clicks, 1)
  Assert.equal(button().shown, true)
end

local function test_drag_follows_ring_at_cursor_angle()
  local db = { minimapAngle = 225 }
  MinimapButton.SetShown(db, true)
  button():Fire("OnDragStart")
  Assert.equal(type(button().scripts.OnUpdate), "function", "follows only while dragging")
  _G.GetCursorPosition = function()
    return 100, 180
  end
  button().scripts.OnUpdate(button())
  Assert.equal(math.floor(db.minimapAngle + 0.5), 90)
end

local function test_drop_stops_following()
  button():Fire("OnDragStop")
  Assert.equal(button().scripts.OnUpdate, nil, "no per-frame work once dropped")
end

local function test_hide_toggles_existing_button()
  MinimapButton.SetShown({ minimapAngle = 225 }, false)
  Assert.equal(button().shown, false)
end

local function test_no_on_update_script()
  Assert.equal(button().scripts.OnUpdate, nil)
end

return function()
  test_hidden_button_is_never_created()
  test_click_runs_handler()
  test_drag_follows_ring_at_cursor_angle()
  test_drop_stops_following()
  test_hide_toggles_existing_button()
  test_no_on_update_script()
end
