dofile_once( "data/scripts/lib/coroutines.lua" )
dofile_once( "data/scripts/lib/utilities.lua" )
dofile_once( "data/hax/superhackykb.lua")

local CHEATGUI_VERSION = "0.0.1"
local CHEATGUI_TITLE = "le-shoppe " .. CHEATGUI_VERSION
if not _keyboard_present then CHEATGUI_TITLE = CHEATGUI_TITLE .. "S" end

local created_gui = false

local _type_target = nil
local _shift_target = nil

local function handle_typing()
  local type_target = _type_target
  local req_shift = false
  if type_target == nil then 
    type_target = _shift_target
    req_shift = true
  end
  if not type_target then return end
  local prev_val = type_target.value
  local hit_enter = false
  type_target.value, hit_enter = hack_type(prev_val, not req_shift)
  if (prev_val ~= type_target.value) and (type_target.on_change) then
    type_target:on_change()
  end
  if hit_enter and (type_target.on_hit_enter) then
    type_target:on_hit_enter()
  end
end

local function set_type_target(target)
  if not _keyboard_present then return end
  if _type_target and _type_target.on_lose_focus then
    _type_target:on_lose_focus()
  end
  _type_target = target
  if _type_target and _type_target.on_gain_focus then
    _type_target:on_gain_focus()
  end
end

local function set_type_default(target)
  _shift_target = target
end

if not _cheat_gui then
  print("Creating cheat GUI")
  _cheat_gui = GuiCreate()
  _gui_frame_function = nil
  created_gui = true
else
  print("Reloading onto existing GUI")
end

local gui = _cheat_gui

local hax_btn_id = 123

local closed_panel, menu_panel

function Panel(options)
  if not options.name then
    options.name = options[1]
  end
  if not options.func then
    options.func = options[2]
  end
  return options
end

local panel_stack = {}
local _active_panel = nil

local function dummy_frame_func() 
  GamePrint("dummy frame func")
end

local function _change_active_panel(panel)
  if panel == _active_panel then return end
  set_type_default(nil)
  set_type_target(nil)
  if panel then
    _gui_frame_function = panel.func 
  else
    _gui_frame_function = dummy_frame_func
  end
end

function prev_panel()
  if #panel_stack < 2 then
    _change_active_panel(nil)
    panel_stack = {}
  else
    -- pop off last panel
    panel_stack[#panel_stack] = nil
    _change_active_panel(panel_stack[#panel_stack])
  end
end

local function jump_back_panel(idx)
  if #panel_stack <= idx then return end
  for i = idx+1, #panel_stack do
    panel_stack[i] = nil
  end
  _change_active_panel(panel_stack[#panel_stack])
end

local function enter_panel(panel)
  panel_stack[#panel_stack+1] = panel
  _change_active_panel(panel)
end

local function hide_gui()
  _change_active_panel(nil)
end

local function goto_subpanel(panel)
  panel_stack = {}
  enter_panel(menu_panel)
  enter_panel(panel)
end

function goto_subpanel_clean(panel)
    panel_stack = {}
    GamePrint("entering panel " .. panel.name)
    enter_panel(panel)
end

function show_gui()
  if #panel_stack == 0 then
    enter_panel(menu_panel)
  else
    _change_active_panel(panel_stack[#panel_stack])
  end
end

function breadcrumbs(x, y)
  GuiLayoutBeginHorizontal(gui, x, y)
  if GuiButton( gui, 0, 0, "[-]", hax_btn_id+1) then
    hide_gui()
  end
  for idx, panel in ipairs(panel_stack) do
    if GuiButton( gui, 0, 0, panel.name .. ">", hax_btn_id+1+idx) then
      jump_back_panel(idx)
    end
  end
  GuiLayoutEnd(gui)
  GuiLayoutBeginHorizontal( gui, x, y+3)
  if #panel_stack > 1 and GuiButton( gui, 0, 0, "< back", hax_btn_id+30) then
    prev_panel()
  end
  GuiLayoutEnd( gui )
end

local _info_widgets = {}
local _sorted_info_widgets = {}
local _all_info_widgets = {}

local function _update_info_widgets()
  _sorted_info_widgets = {}
  for wname, widget in pairs(_info_widgets) do
    table.insert(_sorted_info_widgets, {wname, widget})
  end
  table.sort(_sorted_info_widgets, function(a, b)
    return a[1] < b[1]
  end)
end

local function add_info_widget(wname, w)
  _info_widgets[wname] = w
  _update_info_widgets()
end

local function remove_info_widget(wname)
  _info_widgets[wname] = nil
  _update_info_widgets()
end

local function register_widget(wname, w)
  table.insert(_all_info_widgets, {wname, w})
end

local function get_player()
  return (EntityGetWithTag( "player_unit" ) or {})[1]
end

local function get_player_pos()
  local player = get_player()
  if not player then return 0, 0 end
  return EntityGetTransform(player)
end

local function maybe_call(s_or_f, opt)
  if type(s_or_f) == 'function' then 
    return s_or_f(opt)
  else
    return s_or_f
  end
end

local function get_option_text(opt)
  return maybe_call(opt.text or opt[1], opt)
end

local function grid_layout(options, col_width)
  local num_options = #options
  local col_size = 28
  local ncols = math.ceil(num_options / col_size)
  local xoffset = col_width or 25
  local xpos = 5
  local opt_pos = 1
  for col = 1, ncols do
    if not options[opt_pos] then break end
    GuiLayoutBeginVertical( gui, xpos, 11 )
    for row = 1, col_size do
      if not options[opt_pos] then break end
      local opt = options[opt_pos]
      local text = get_option_text(opt)
      if GuiButton( gui, 0, 0, text, hax_btn_id+opt_pos+40 ) then
        (opt.f or opt[2])(opt)
      end
      opt_pos = opt_pos + 1
    end
    GuiLayoutEnd( gui)
    xpos = xpos + xoffset
  end
end

local function grid_panel(title, options, col_width)
  breadcrumbs(1, 0)
  grid_layout(options, col_width)
end

local function filter_options(options, str)
  local ret = {}
  for _, opt in ipairs(options) do
    local text = maybe_call(opt.text, opt):lower()
    if text:find(str) then
      table.insert(ret, opt)
    end
  end
  return ret
end

local function create_radio(title, options, default, x_spacing)
  if not default then default = options[1][2] end
  local selected = default --1
  -- for i, v in ipairs(options) do
  --   if v[2] == default then selected = i end
  -- end
  local wrapper = {
    index = selected, 
    value = options[selected][2],
    reset = function(_self)
      _self.index = default
      _self.value = options[default][2]
    end
  }
  return function(button_id, xpos, ypos)
    button_id = (button_id or 200) + 1  
    GuiLayoutBeginHorizontal(gui, xpos, ypos)
    GuiText(gui, 0, 0, title)
    GuiLayoutEnd(gui)
    GuiLayoutBeginHorizontal(gui, xpos+(x_spacing or 12), ypos)
    for idx, option in ipairs(options) do
      local text = option[1]
      if idx == wrapper.index then text = "[" .. text .. "]" end
      if GuiButton( gui, 0, 0, text, button_id ) then
        wrapper.index = idx
        wrapper.value = option[2]
      end
      button_id = button_id + 1
    end
    GuiLayoutEnd(gui)
    return button_id
  end, wrapper
end

local function alphabetize(options, do_it)
  if not do_it then return options end
  local keys = {}
  for idx, opt in ipairs(options) do
    keys[idx] = {get_option_text(opt):lower(), opt}
  end
  table.sort(keys, function(a, b) return a[1] < b[1] end)
  local sorted = {}
  for idx, v in ipairs(keys) do
    sorted[idx] = v[2]
  end
  return sorted
end

local alphabetize_widget, alphabetize_val = create_radio("Alphabetize:", {
  {"Yes", true}, {"No", false}
}, 2, 16)

local function breakup_pages(options, page_size)
  local pages = {}
  local npages = math.ceil(#options / page_size)
  local opt_pos = 1
  for page = 1, npages do
    if not options[opt_pos] then break end
    pages[page] = {}
    for idx = 1, page_size do
      if not options[opt_pos] then break end
      table.insert(pages[page], options[opt_pos])
      opt_pos = opt_pos + 1
    end
  end
  return pages
end

function wrap_paginate(title, options, page_size)
  page_size = page_size or 28*4
  local cur_page = 1
  local pages = breakup_pages(options, page_size)

  local prev_alphabetize = false
  local filtered_set = options
  local filter_thing = {
    value = "", on_change = function(_self)
      filtered_set = alphabetize(
        filter_options(options, _self.value), 
        alphabetize_val.value
      )
    end
  }
  return function(force_refilter)
    if force_refilter or (prev_alphabetize ~= alphabetize_val.value) then
      force_refilter = true
      pages = breakup_pages(
        alphabetize(options, alphabetize_val.value), page_size
      )
    end
    prev_alphabetize = alphabetize_val.value
    set_type_default(filter_thing)
    local filter_str = filter_thing.value
    local filter_text = "[shift+type to filter]"
    if filter_str and (filter_str ~= "") then
      filter_text = filter_str
    end

    if _keyboard_present then
      GuiLayoutBeginVertical( gui, 61, 0)
      GuiText(gui, 0, 0, "Filter:")
      GuiLayoutEnd( gui )
      GuiLayoutBeginVertical( gui, 61 + 11, 0 )
      if GuiButton( gui, 0, 0, filter_text, hax_btn_id+11 ) then
        filter_thing.value = ""
      end
      GuiLayoutEnd( gui)
    end
    alphabetize_widget(hax_btn_id+24, 31, 0)

    if (not filter_str) or (filter_str == "") then
      grid_panel(title, pages[cur_page])
      if cur_page > 1 then
        GuiLayoutBeginHorizontal(gui, 46, 96)
        if GuiButton( gui, 0, 0, "<-", hax_btn_id+12 ) then
          cur_page = cur_page - 1
        end
        GuiLayoutEnd(gui)
      end
      if #pages > 1 then
        GuiLayoutBeginHorizontal(gui, 48, 96)
        GuiText( gui, 0, 0, ("%d/%d"):format(cur_page, #pages))
        GuiLayoutEnd(gui)
      end
      if cur_page < #pages then
        GuiLayoutBeginHorizontal(gui, 51, 96)
        if GuiButton( gui, 0, 0, "->", hax_btn_id+13 ) then
          cur_page = cur_page + 1
        end
        GuiLayoutEnd(gui)
      end
    else
      if force_refilter then
        filtered_set = alphabetize(
          filter_options(options, filter_str), 
          alphabetize_val.value
        )
      end
      grid_panel(title, filtered_set)
    end
  end
end

local function round(v)
  local upper = math.ceil(v)
  local lower = math.floor(v)
  if math.abs(v - upper) < math.abs(v - lower) then
    return upper
  else
    return lower
  end
end

local num_types = {
  float = {function(x) return x end, "%0.2f", 1.0},
  int = {function(x) return round(x) end, "%d", 1.0},
  frame = {function(x) return round(x) end, "%0.2f", 1.0/60.0},
  mills = {function(x) return round(x) end, "%0.2f", 1.0/1000.0},
  hearts = {function(x) return x end, "%d", 25.0}
}

local function create_numerical(title, increments, default, kind)
  local validate, fstr, multiplier = unpack(num_types[kind or "float"])

  local text_wrapper = {
    value = "",
    on_change = function(_self)
      -- eh?
    end,
    on_gain_focus = function(_self)
      _self.has_focus = true
      _self.value = _self.numeric:display_val()
    end,
    set_value = function(_self)
      local temp = tonumber(_self.value)
      if temp then
        _self.numeric.value = validate(temp / multiplier)
      end
    end,
    on_lose_focus = function(_self)
      _self.has_focus = false
      _self:set_value()
    end,
    on_hit_enter = function(_self)
      _self:set_value()
      set_type_target(nil)
    end,
    display_val = function(_self)
      if not _self.has_focus then return nil end
      return _self.value .. "_"
    end
  }

  local wrapper = {
    text = text_wrapper,
    value = default or 0.0,
    display_val = function(_self)
      return fstr:format(_self.value * multiplier)
    end,
    temp_val = "",
    reset = function(_self)
      _self.value = default
    end
  }

  text_wrapper.numeric = wrapper

  return function(button_id, xpos, ypos)
    button_id = (button_id or 200) + 1
    GuiLayoutBeginHorizontal(gui, xpos, ypos)
      GuiText(gui, 0, 0, title)
    GuiLayoutEnd(gui)
    GuiLayoutBeginHorizontal(gui, xpos + 12, ypos)
      for idx = #increments, 1, -1 do
        local s = "[" .. string.rep("-", idx) .. "]"
        if GuiButton( gui, 0, 0, s, button_id ) then
          wrapper.value = wrapper.value - increments[idx]
        end
        button_id = button_id + 1
      end
      if GuiButton(gui, 0, 0, "" .. (text_wrapper:display_val() or wrapper:display_val()), button_id) then
        if text_wrapper.has_focus then
          set_type_target(nil)
        else
          set_type_target(text_wrapper)
        end
      end
      button_id = button_id + 1
      for idx = 1, #increments do
        local s = "[" .. string.rep("+", idx) .. "]"
        if GuiButton( gui, 0, 0, s, button_id ) then
          wrapper.value = wrapper.value + increments[idx]
        end
        button_id = button_id + 1
      end
    GuiLayoutEnd(gui)
    return button_id
  end, wrapper
end

-- build these button lists once so we aren't rebuilding them every frame
local function resolve_localized_name(s, default)
  if s:sub(1,1) ~= "$" then return s end
  local rep = GameTextGet(s)
  if rep and rep ~= "" then return rep else return default or s end
end

local function localized_name(thing)
  if localization_val.value then return thing.ui_name else return thing.id end
end

local seedval = "?"
SetRandomSeed(0, 0)
seedval = tostring(Random() * 2^31)

local extra_buttons = {}

function register_extra_button(title, f)
  table.insert(extra_buttons, {title, f})
end

function draw_extra_buttons(startid)
  for _, button in ipairs(extra_buttons) do
    local title, f = button[1], button[2]
    if type(title) == 'function' then title = title() end
    if f then
      if GuiButton( gui, 0, 0, title, startid) then
        f()
      end
      startid = startid + 1
    else
      GuiText( gui, 0, 0, title)
    end
  end
  return startid
end

local main_panels = {}

function register_main_panel(panel) 
  table.insert(main_panels, panel)
end

local function draw_main_panels(startid)
  for idx, panel in ipairs(main_panels) do
    if GuiButton( gui, 0, 0, panel.name .. "->", startid + idx ) then
      enter_panel(panel)
    end
  end
  return startid + #main_panels + 1
end

local function draw_panels(panels)
  for idx, panel in ipairs(panels) do
    if GuiButton( gui, 0, 0, panel.name .. "->", startid + idx ) then
      enter_panel(panel)
    end
  end
  return startid + #main_panels + 1
end

menu_panel = Panel{CHEATGUI_TITLE, function()
  breadcrumbs(1, 0)
  GuiLayoutBeginVertical( gui, 1, 11 )
  local next_id = draw_main_panels(hax_btn_id+4)
  draw_extra_buttons(next_id)
  GuiLayoutEnd( gui)
end}

-- widgets
local function StatsWidget(dispname, keyname, extra_pad)
  local width = math.ceil(#dispname * 0.9) + (extra_pad or 3)
  return {
    text = function()
      return ("%s: %s"):format(dispname, StatsGetValue(keyname) or "?")
    end,
    on_click = function()
      goto_subpanel(info_panel)
    end,
    width = width
  }
end

-- register_widget("position", {
--   text = function()
--     local x, y = get_player_pos()
--     return ("X: %d, Y: %d"):format(x, y)
--   end,
--   on_click = function()
--     goto_subpanel(info_panel)
--   end,
--   width = 15
-- })

function _cheat_gui_main()
  if gui ~= nil then
    GuiStartFrame( gui )
  end

  if _gui_frame_function ~= nil then
    handle_typing()
    local happy, errstr = pcall(_gui_frame_function)
    if not happy then
      print("Gui error: " .. errstr)
      GamePrint("cheatgui err: " .. errstr)
      hide_gui()
    end
  end
end

local buy_panel, sell_panel

local function create_trading_panels()  
  buy_panel = Panel{"Buy", function()
    breadcrumbs(1, 0)
    GuiLayoutBeginVertical( gui, 1, 11 )
    GuiLayoutEnd( gui)
  end}

  sell_panel = Panel{"Sell", function()
    breadcrumbs(1, 0)
    GuiLayoutBeginVertical( gui, 1, 11 )
    GuiLayoutEnd( gui)
  end}

  return {buy_panel, sell_panel}
end

local function register_trading_panels() 
  local trading_panels = create_trading_panels()
  for idx, panel in ipairs(trading_panels) do
    register_main_panel(panel)
  end
end

register_trading_panels()

enter_panel(menu_panel)

hide_gui()