-- Title: Disco Aquila
-- Author: Wobin
-- Date: 02/10/2026

local mod = get_mod("Disco Aquila")

local PortableRandom = require("scripts/foundation/utilities/portable_random")
local managers = Managers
local os = os
local os_clock = os.clock
local pairs = pairs
local ipairs = ipairs
local table = table
local table_insert = table.insert
local table_is_empty = table.is_empty
local Wwise = Wwise
local Application = Application

local MUSIC_PARAM = "options_music_slider"
local SONG_FADE_OUT = 1
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
mod.drones = {}

local function is_enabled()
  return mod:is_enabled() ~= false
end

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
local mute_drone = false

local function refresh_cached_settings()
	suppress_game_music = mod:get("da_suppress_game_music") and true or false
	stealth_mode = mod:get("da_stealth_mode") and true or false
	mute_drone = mod:get("da_mute_drone") and true or false
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

	if setting_id and string.find(setting_id, "^da_song_") then
		sync_track_settings()
	end
end

mod.on_settings_reset = function()
	refresh_cached_settings()
	sync_track_settings()
end

mod.report_no_tracks = function()
	local TrackOptions = mod.track_options
	local reason = TrackOptions and TrackOptions.scan_error or "unknown"

	mod:echo("%s", "No tracks loaded: " .. reason)
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

local function flashlight_package_loaded()
  return mod.package_manager and mod.package_id and mod.package_manager:has_loaded_id(mod.package_id)
end

local function spawn_lights(socket, drone_unit)
  for _, colour in ipairs(socket.pending_colours) do
    local light = flashlight:new(mod._world, drone_unit, random_range(random, 0, 1000), colour or nil)
    table_insert(socket.lights, light)
    light:spawn_flashlight()
    light:random_rotate()
  end
  socket.pending_colours = nil
end

local function release_drone(socket)
  for _, light in pairs(socket.lights) do
    light:despawn()
  end
  socket.lights = {}
  socket.pending_colours = nil
  if socket.play_id and mod.radio then
    mod.radio:stop_playing(socket.play_id, SONG_FADE_OUT)
    if mod.song == socket.song then
      mod.song = nil
    end
  end
  socket.play_id = nil
end

local function teardown()
  set_music_suppressed(false)
  for _, socket in pairs(mod.drones) do
    release_drone(socket)
  end
  mod.drones = {}
end

mod.deinit = function(self)
  teardown()
  if self.package_manager and self.package_id then
    self.package_manager:release(self.package_id)
    self.package_id = nil
  end
  self.package_manager = nil
  self.radio = nil
  self.initialized = false
end

mod.on_unload = function(exit_game)
  mod:deinit()
end

mod.on_disabled = function(initial_call)
  teardown()
end

local cleanupdelta = 0
local cleanup_interval = 10

local trash = {}

mod.update = function(dt, t)
  if not mod.initialized or not is_enabled() then return end

  set_music_suppressed(suppress_game_music and any_drone_active())

  if table_is_empty(mod.drones) then return end

  for drone_unit, socket in pairs(mod.drones) do
    if not unit_alive(drone_unit) then
      cleanupdelta = cleanup_interval + 1
    elseif socket.pending_colours then
      if flashlight_package_loaded() then
        spawn_lights(socket, drone_unit)
      end
    elseif not stealth_mode then
      socket.delta = socket.delta + dt
      if socket.delta > socket.interval then
        for _, light in pairs(socket.lights) do
          light:random_rotate()
        end
        socket.delta = 0
      end
    end
  end

  if cleanupdelta > cleanup_interval then
    for drone_unit, socket in pairs(mod.drones) do
      if not unit_alive(drone_unit) then
        trash[drone_unit] = true
        release_drone(socket)
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

  local socket = mod.drones[drone_unit] or { lights = {}, delta = 0 }
  local song, play_id = radio:play_random(drone_unit)

  if not song then return end

  local settings = mod:get("da_song_settings") or {}
  local song_settings = settings[song] or {}
  if play_id then
    socket.play_id = play_id
    socket.song = song
  end
  socket.interval = 60 / (song_settings.bpm or 100)
  mod.drones[drone_unit] = socket
  if table_is_empty(socket.lights) and not socket.pending_colours and not stealth_mode then
    if not song_settings.random_rainbow then
      socket.pending_colours = { song_settings.colour_one, song_settings.colour_two, song_settings.colour_one, song_settings.colour_two }
    else
      socket.pending_colours = { false, false, false, false }
    end
    if flashlight_package_loaded() then
      spawn_lights(socket, drone_unit)
    end
  end
  mod.song = song
end

mod.register_audio_hook = function()
  mod:hook_require("scripts/components/area_buff_drone", function(AreaBuffDrone)
    mod:hook_safe(AreaBuffDrone, "_deploy", function(self)
      trip_disco(self)
    end)
    mod:hook_safe(AreaBuffDrone, "destroy", function(self, drone_unit)
      local socket = mod.drones[drone_unit]
      if socket then
        release_drone(socket)
        mod.drones[drone_unit] = nil
      end
    end)
  end)

  mod.simple_audio.hook_sound("buff_drone", function(_, sound_name)
    return not (mute_drone and is_enabled())
  end)
end

if in_gameplay() then
  refresh_cached_settings()
  sync_track_settings()
  if mod:setup_hooks() and not mod.initialized then
    mod:init()
  end
end
