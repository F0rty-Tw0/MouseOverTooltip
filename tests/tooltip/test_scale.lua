local Assert = require("tests.helpers.assert")
local Scale = require("MouseOverTooltip.Tooltip.Scale")

local function spy()
  return {
    SetScale = function(self, scale)
      self.scale = scale
      self.calls = (self.calls or 0) + 1
    end,
  }
end

local function freshFrames()
  _G.GameTooltip, _G.ShoppingTooltip1, _G.ShoppingTooltip2 = spy(), spy(), spy()
end

local function test_default_scale_makes_no_calls()
  freshFrames()
  Scale.Install({ tooltipScale = 100 })
  Assert.equal(_G.GameTooltip.calls, nil)
  Assert.equal(_G.ShoppingTooltip1.calls, nil)
  Assert.equal(_G.ShoppingTooltip2.calls, nil)
end

local function test_install_scales_all_three_frames()
  freshFrames()
  Scale.Install({ tooltipScale = 150 })
  Assert.equal(_G.GameTooltip.scale, 1.5)
  Assert.equal(_G.ShoppingTooltip1.scale, 1.5)
  Assert.equal(_G.ShoppingTooltip2.scale, 1.5)
end

local function test_apply_100_resets_to_one()
  freshFrames()
  Scale.Apply(150)
  Scale.Apply(100)
  Assert.equal(_G.GameTooltip.scale, 1)
  Assert.equal(_G.ShoppingTooltip1.scale, 1)
  Assert.equal(_G.ShoppingTooltip2.scale, 1)
end

local function test_missing_frame_is_skipped()
  freshFrames()
  _G.ShoppingTooltip2 = nil
  Scale.Apply(80)
  Assert.equal(_G.GameTooltip.scale, 0.8)
  Assert.equal(_G.ShoppingTooltip1.scale, 0.8)
end

local function test_frame_without_setscale_is_skipped()
  freshFrames()
  _G.ShoppingTooltip1 = {}
  Scale.Apply(80)
  Assert.equal(_G.GameTooltip.scale, 0.8)
  Assert.equal(_G.ShoppingTooltip2.scale, 0.8)
end

return function()
  test_default_scale_makes_no_calls()
  test_install_scales_all_three_frames()
  test_apply_100_resets_to_one()
  test_missing_frame_is_skipped()
  test_frame_without_setscale_is_skipped()
end
