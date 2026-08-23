-- Title: Disco Aquila
-- Author: Wobin
-- Date: 23/08/2026

local mod = get_mod("Disco Aquila")

local PortableRandom = require("scripts/foundation/utilities/portable_random")
local managers = Managers
local os = os
local os_clock = os.clock
local pairs = pairs
local table = table
local table_insert = table.insert
local table_is_empty = table.is_empty
local Wwise = Wwise
local Application = Application

local MUSIC_PARAM = "options_music_slider"
local music_suppressed = false

local function set_music_suppressed(suppress)
  if not (Wwise and Wwise.set_parameter) then return end
  if suppress then
    if music_suppressed then return end
    Wwise.set_parameter(MUSIC_PARAM, 0)
    music_suppressed = true
  elseif music_suppressed then
    Wwise.set_parameter(MUSIC_PARAM, Application.user_setting("sound_settings", MUSIC_PARAM) or 100)
    music_suppressed = false
  end
end

mod.version = mod.get_metadata and mod:get_metadata("version") or "unknown"

local flashlight_unit_large = "content/weapons/player/attachments/flashlights/flashlight_01/flashlight_01"

local unit = Unit
local unit_alive = unit.alive
local valid_zones = { 
                      survival = true,
                      shooting_range = true,
                      coop_complete_objective = true
                    }
mod.drones = {}

local function any_drone_active()
  for drone_unit in pairs(mod.drones) do
    if unit_alive(drone_unit) then return true end
  end
  return false
end

local hooks_registered = false

local function in_gameplay()
  return rawget(_G, "Managers") and Managers.state and Managers.state.game_mode ~= nil
end

mod.setup_hooks = function(self)
  if not self.simple_audio then
    self.simple_audio = get_mod("SimpleAudio")
  end
  if not self.simple_audio then
    self:error("Disco Aquila requires the SimpleAudio mod - please install and enable it.")
    return false
  end
  if not hooks_registered then
    self:register_audio_hook()
    hooks_registered = true
  end
  return true
end

local suppress_game_music = false
local stealth_mode = false

local function refresh_cached_settings()
	suppress_game_music = mod:get("da_suppress_game_music") and true or false
	stealth_mode = mod:get("da_stealth_mode") and true or false
end

local function sync_track_settings()
	local TrackOptions = mod.track_options

	if TrackOptions then
		TrackOptions.sync()
	end
end

mod.on_all_mods_loaded = function()
  mod:info(mod.version)
  refresh_cached_settings()
  sync_track_settings()
  if mod:setup_hooks() and not mod.initialized and in_gameplay() then
    mod:init()
  end
end

mod.on_game_state_changed = function(status, state_name)
  if not mod.initialized and status == "enter" and state_name == "StateGameplay" then
    if mod:setup_hooks() then
      mod:init()
    end
  end
end

mod.on_unload = function(exit_game)
    mod:deinit()
end

local random = PortableRandom:new(os_clock())
local random_range = random.random_range
local flashlight = mod:io_dofile("Disco Aquila/scripts/mods/Disco Aquila/modules/flashlight")
local radio = mod:io_dofile("Disco Aquila/scripts/mods/Disco Aquila/modules/radio")

mod.init = function(self)
    self.package_manager = managers.package
    self.package_id = self.package_manager:load(flashlight_unit_large, "DiscoAquila")
    self.radio = radio:new()
    self.initialized = true       
end

mod.on_setting_changed = function(setting_id)
	refresh_cached_settings()

	-- Only the per-track widgets feed the synced table; rebuilding it for a
	-- global toggle would rewrite every track on each slider notch.
	if setting_id and string.find(setting_id, "^da_song_") then
		sync_track_settings()
	end
end

mod.on_settings_reset = function()
	refresh_cached_settings()
	sync_track_settings()
end

mod.preview_selected_track = function()
	local TrackOptions = mod.track_options

	if not TrackOptions or not mod.radio then
		return
	end

	if mod.playingSample then
		mod.radio:stop_playing(mod.playingSample)
		mod.playingSample = nil

		return
	end

	local track = TrackOptions.selected_track()

	if not track then
		return
	end

	mod.playingSample = mod.radio:play_sample(track.name, mod:get(track.id .. "_volume") or 80)
end

mod.spawn_flashlight = function(self, lightFixture, drone_unit, colour)
    local light = flashlight:new(self._world, drone_unit, random_range(random, 0, 1000), colour)
    table_insert(lightFixture, light)
    light:spawn_flashlight()
    light:random_rotate()
end

mod.deinit = function(self)
  set_music_suppressed(false)
  if self.drones then
    for _, socket in pairs(self.drones) do
      for _, light in pairs(socket.lights) do
        light:despawn()
      end
    end
  end
  self.drones = {}
  if self.package_manager and self.package_id then
    self.package_manager:release(self.package_id)
    self.package_id = nil
  end
  self.package_manager = nil
  self.radio = nil
  self.initialized = false
end

local delta = 0
local cleanupdelta = 0
local cleanup_interval = 10

local trash = {}

mod.update = function(dt, t)
  if not mod.initialized then return end

  set_music_suppressed(suppress_game_music and any_drone_active())

  if table_is_empty(mod.drones) then return end

  -- Rotation only runs when lights exist; cleanup must run regardless, or dead
  -- drones accumulate for the whole session while stealth mode is on.
  if not stealth_mode and mod.update_interval then
    if delta > mod.update_interval then
      for drone_unit, socket in pairs(mod.drones) do
        if unit_alive(drone_unit) then
          for _, light in pairs(socket.lights) do
            light:random_rotate()
          end
        else
          cleanupdelta = cleanup_interval + 1
        end
      end
      delta = 0
    else
      delta = delta + dt
    end
  end

  if cleanupdelta > cleanup_interval then
    for drone_unit, drone in pairs(mod.drones) do
      if not unit_alive(drone_unit) then
        trash[drone_unit] = true
        for _, light in pairs(drone.lights) do
          light:despawn()
        end
      end
    end
    for rubbish in pairs(trash) do
      mod.drones[rubbish] = nil
    end
    table.clear(trash)
    cleanupdelta = 0
  else
    cleanupdelta = cleanupdelta + dt
  end
end


local trip_disco = function(drone)
  if not mod.initialized or not drone or not drone._world then return end
  mod._world = drone._world
  local drone_unit = drone._unit

  local socket = mod.drones[drone_unit] or {lights = {}}
  local song = radio:play_random(drone_unit)

  if not song then return end

  local settings = mod:get("da_song_settings") or {}
  local song_settings = settings[song] or {}
  if table_is_empty(socket.lights) then
    mod.drones[drone_unit] = socket
    if not stealth_mode then
      if not song_settings.random_rainbow then
        mod:spawn_flashlight(socket.lights, drone_unit, song_settings.colour_one)
        mod:spawn_flashlight(socket.lights, drone_unit, song_settings.colour_two)
        mod:spawn_flashlight(socket.lights, drone_unit, song_settings.colour_one)
        mod:spawn_flashlight(socket.lights, drone_unit, song_settings.colour_two)
      else
        mod:spawn_flashlight(socket.lights, drone_unit)
        mod:spawn_flashlight(socket.lights, drone_unit)
        mod:spawn_flashlight(socket.lights, drone_unit)
        mod:spawn_flashlight(socket.lights, drone_unit)
      end
    end
  end
  mod.song = song
  mod.update_interval = 60 / (song_settings.bpm or 100)
end

mod.register_audio_hook = function()
  mod:hook_require("scripts/components/area_buff_drone", function(AreaBuffDrone)
    mod:hook_safe(AreaBuffDrone, "_deploy", function(self)
      trip_disco(self)
    end)
  end)

  mod.simple_audio.hook_sound("buff_drone", function(_, sound_name)
    return not mod:get("da_mute_drone")
  end)
end

-- Hot-reload safety: on_all_mods_loaded / StateGameplay-enter don't re-fire when
-- the mod is reloaded mid-mission, so set up immediately if already in gameplay.
if in_gameplay() then
  refresh_cached_settings()
  sync_track_settings()
  if mod:setup_hooks() and not mod.initialized then
    mod:init()
  end
end
