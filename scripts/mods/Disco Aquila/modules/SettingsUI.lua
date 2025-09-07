local mod = get_mod("Disco Aquila")

local ui_scale = 2
local WIDTH = 360
local HEIGHT = 240
local OFFSET = 550
local PADDING = 16
local first_run = true
local window_width = math.min(WIDTH * ui_scale, RESOLUTION_LOOKUP.width - OFFSET)
local window_height = math.min(HEIGHT * ui_scale, RESOLUTION_LOOKUP.height - OFFSET)
local padded_width = window_width - PADDING

-- local refs
local Imgui = Imgui
local Imgui_checkbox = Imgui.checkbox
local Imgui_is_item_hovered = Imgui.is_item_hovered
local Imgui_begin_tool_tip = Imgui.begin_tool_tip
local Imgui_text = Imgui.text
local Imgui_end_tool_tip = Imgui.end_tool_tip
local Imgui_set_next_window_size = Imgui.set_next_window_size
local Imgui_begin_window = Imgui.begin_window
local Imgui_set_next_window_pos = Imgui.set_next_window_pos
local Imgui_set_window_font_scale = Imgui.set_window_font_scale
local Imgui_begin_combo = Imgui.begin_combo
local Imgui_selectable = Imgui.selectable
local Imgui_end_combo = Imgui.end_combo
local Imgui_slider_int = Imgui.slider_int
local Imgui_color_edit_3 = Imgui.color_edit_3
local Imgui_end_window = Imgui.end_window

local DiscoAquilaConfig = class("DiscoAquilaConfig")

function DiscoAquilaConfig:init()
	self._is_open = false
end

function DiscoAquilaConfig:open()
	local input_manager = Managers.input
	local name = self.__class_name
  
	if not input_manager:cursor_active() then
		input_manager:push_cursor(name)
    self.pushedcursor = true
	end

	self._is_open = true
	Imgui.open_imgui()
end

function DiscoAquilaConfig:close()
	local input_manager = Managers.input
	local name = self.__class_name
  
	if self.pushedcursor then    
		input_manager:pop_cursor(name)
    self.pushedcursor = false
	end

	self._is_open = false
	Imgui.close_imgui()
end

local updateCheckbox = function(setting, tooltip)
  local current_setting = mod:get(setting)
	local updated_setting = Imgui_checkbox(mod:localize(setting), current_setting)
  if tooltip then
    if Imgui_is_item_hovered() then
      Imgui_begin_tool_tip()
      Imgui_text(mod:localize(tooltip))
      Imgui_end_tool_tip()
    end
  end
  if current_setting ~= updated_setting then mod:set(setting, updated_setting) end
end

function DiscoAquilaConfig:update()
	if not self._is_open then
		return
	end

	Imgui_set_next_window_size(window_width, window_height)
	if first_run then
		Imgui_set_next_window_pos((RESOLUTION_LOOKUP.width / 2) - (WIDTH / 2) - 100, (RESOLUTION_LOOKUP.height / 2) - (HEIGHT / 2) - 100)
		first_run = false
	end
	local _, closed = Imgui_begin_window("Disco Aquila Config", "always_auto_resize")

	if closed then
		self:close()
	end
  
  local all_settings = mod:get("da_song_settings") or {}
  
  local saveSettings = function(song_settings)
    all_settings[mod.selectedSong] = song_settings
    mod:set("da_song_settings", all_settings, false)
  end
  
  local song_settings = {}
  
  if mod.selectedSong then
    song_settings = all_settings[mod.selectedSong]
  end

	Imgui_set_window_font_scale(ui_scale)
  
  updateCheckbox("da_play_once","da_play_desc")
  updateCheckbox("da_mute_drone")
  updateCheckbox("da_stealth_mode")
  updateCheckbox("da_remove_filter")
  updateCheckbox("da_print_song")
  updateCheckbox("da_apply_master_volume")
  if mod:get("da_apply_master_volume") then
    local currentMasterVolume = mod:get("da_master_volume")
    local newMasterVolume = Imgui_slider_int(mod:localize("da_master_volume"), currentMasterVolume or 80, 1, 100)          
    if newMasterVolume ~= currentMasterVolume then
      mod:set("da_master_volume", newMasterVolume, false)      
    end
  end
  local songList = mod.radio:get_music()
  Imgui_text("-----------------------------------")  
  if Imgui_begin_combo(mod:localize("da_song_settings"), mod.selectedSong) then
    Imgui_selectable(mod:localize("da_select_song"), not mod.selectedSong  )
    for i,v in ipairs(songList) do
      if Imgui_selectable(v.file_path, mod.selectedSong == v.file_path) then
        if mod.selectedSong ~= v.file_path then
          mod.selectedSong = v.file_path
          song_settings = all_settings[mod.selectedSong] or {volume = 80, bpm = 100}
        end
      end
    end
  Imgui_end_combo()
  end  
  Imgui_text("-----------------------------------")
  if mod.selectedSong then
    local newVolume = Imgui_slider_int(mod:localize("da_song_volume"), song_settings.volume or 80, 1, 100)          
    if newVolume ~= song_settings.volume then      
      song_settings.volume = newVolume
      saveSettings(song_settings)
    end
    Imgui.same_line()
    local button_text = mod.playingSample and "||" or ">" 
    if Imgui.button(button_text) then
      if mod.playingSample then
        mod.radio:stop_playing(mod.playingSample)
        mod.playingSample = nil
      else
        mod.playingSample = mod.radio:play_sample(mod.selectedSong, song_settings.volume)        
      end
      
    
    end
    local newBpm = Imgui_slider_int(mod:localize("da_song_bpm"), song_settings.bpm or 100, 50, 200)          
    if newBpm ~= song_settings.bpm then      
      song_settings.bpm = newBpm
      saveSettings(song_settings)
    end
   	
    local updated_setting = Imgui_checkbox(mod:localize("da_random_lights"), song_settings.random_rainbow)
    if updated_setting ~= song_settings.random_rainbow  then
      song_settings.random_rainbow = updated_setting 
      saveSettings(song_settings)
    end    
    
    if not song_settings.random_rainbow then
      local existingColorOne = song_settings.colour_one or {r = 0, g = 0, b = 0}      
      local r,g,b = Imgui_color_edit_3(mod:localize("da_light_one"), existingColorOne.r, existingColorOne.g, existingColorOne.b)      
      if r ~= existingColorOne.r or g ~= existingColorOne.g or b ~= existingColorOne.b then        
        song_settings.colour_one = { r = r, g = g, b = b}
        saveSettings(song_settings)
      end
        local existingColorTwo = song_settings.colour_two or {r = 0, g = 0, b = 0}      
      local r,g,b = Imgui_color_edit_3(mod:localize("da_light_two"), existingColorTwo.r, existingColorTwo.g, existingColorTwo.b)      
      if r ~= existingColorTwo.r or g ~= existingColorTwo.g or b ~= existingColorTwo.b then        
        song_settings.colour_two = { r = r, g = g, b = b}
        saveSettings(song_settings)
      end
    end
  end
	Imgui_end_window()
end

return DiscoAquilaConfig