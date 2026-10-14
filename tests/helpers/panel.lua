local Wow = require("tests.helpers.wow")

local PanelHelper = {}

-- Installs the WoW stubs, registers the options panel and returns a context:
-- W, db, canvas, category, opened, changes, counts, framesBefore,
-- framesAtRegister and the boxes/tabButton/clickTab lookups. Call before the
-- first Panel require: the flavor is read at load. `mountJournal` gives the
-- flavor the mount API, so the Mount rows (and their children) are built.
function PanelHelper.Setup(options)
  local ctx = { W = Wow.Install(), changes = {}, counts = {} }
  local W = ctx.W
  ctx.category = {
    GetID = function()
      return 77
    end,
  }
  _G.Settings = {
    RegisterCanvasLayoutCategory = function(frame, name)
      ctx.canvas, ctx.category.name = frame, name
      return ctx.category
    end,
    RegisterAddOnCategory = function(cat)
      cat.registered = true
    end,
    OpenToCategory = function(id)
      ctx.opened = id
    end,
  }
  if options and options.mountJournal then
    _G.C_MountJournal = { GetMountFromSpell = function() end }
  end
  local SavedState = require("MouseOverTooltip.Settings.SavedState")
  local Panel = require("MouseOverTooltip.Settings.Panel")
  ctx.Panel = Panel
  ctx.db = SavedState.Initialize(nil)
  ctx.framesBefore = #W.frames
  Panel.Register(ctx.db, function(key, value)
    ctx.changes[key] = value
    ctx.counts[key] = (ctx.counts[key] or 0) + 1
  end)
  ctx.framesAtRegister = #W.frames

  function ctx.boxes()
    local byLabel = {}
    for _, frame in ipairs(W.frames) do
      if frame.label then
        byLabel[frame.label:GetText()] = frame
      end
    end
    return byLabel
  end

  -- The "Combat" tab and the "Combat" header share their text; only the tab clicks.
  function ctx.tabButton(name)
    for _, frame in ipairs(W.frames) do
      if frame:GetText() == name and frame.scripts.OnClick then
        return frame
      end
    end
    error("no tab button " .. name, 2)
  end

  function ctx.clickTab(name)
    ctx.tabButton(name):Fire("OnClick")
  end

  function ctx.uncheck(box)
    box:SetChecked(false)
    box:Fire("OnClick")
  end

  return ctx
end

return PanelHelper
