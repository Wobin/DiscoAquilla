local mod = get_mod("Disco Aquila")

--local mt = get_mod("modding_tools")

local DiscoAquilaRadio = class("DiscoAquilaRadio")
local SA
local song_list = {}
local path_lookup = {}
local os = os
local os_clock = os.clock
local playlist = {}
local random = PortableRandom:new(os_clock())
local random_range = random.random_range
local table = table
local table_clone = table.shallow_copy
local table_remove = table.remove
local ipairs = ipairs
local pcall = pcall
local Unit = Unit
local unit_alive = Unit.alive

local AUDIO_DIR = "mods/Disco Aquila/audio/"
local EXTENSIONS = { "opus", "mp3", "ogg", "wav", "flac", "m4a", "aac", "mp4", "webm", "mkv", "mov", "flv" }
local FOLLOW_INTERVAL = 0.1

local function basename(path)
  return path:match("[^/\\]+$") or path
end

local function build_song_list()
  local items = {}
  for _, ext in ipairs(EXTENSIONS) do
    local ok, g = pcall(SA.glob, AUDIO_DIR .. "*." .. ext)
    if ok and g and g:count() > 0 then
      for _, p in ipairs(g:list()) do
        items[#items + 1] = { file_path = basename(p), _path = p }
      end
    end
  end
  return items
end

local function play(path, opts, unit)
  local settings = {
    audio_type  = "sfx",
    volume      = opts.volume,
    duration    = opts.duration,
    on_finished = opts.on_finished,
  }
  if opts.filter then
    settings.filters = "chorus=" .. opts.filter
  end
  if unit then
    local acc = 0
    settings.on_update = function(pid, dt)
      acc = acc + dt
      if acc >= FOLLOW_INTERVAL then
        acc = 0
        if unit_alive(unit) then
          SA.set_position(pid, unit)
        end
      end
    end
  end
  return SA.play_file(path, settings, unit)
end

DiscoAquilaRadio.init = function(self, retried)
  if not Managers.backend:authenticated() and (retried or 0) > 0 then
    Promise.delay(10):next(function() self:init((retried or 0) - 1) end)
    return
  end

  SA = mod.simple_audio
  song_list = SA and build_song_list() or {}
  path_lookup = {}
  for _, item in ipairs(song_list) do
    path_lookup[item.file_path] = item._path
  end
  DiscoAquilaRadio.initialised = true
end

DiscoAquilaRadio.get_music = function()
  return song_list or {}
end

DiscoAquilaRadio.play_sample = function(self, song_name, volume)
  local path = path_lookup[song_name] or song_name
  return play(path, {
    volume      = volume,
    duration    = 20,
    on_finished = function() mod.playingSample = nil end,
  })
end

DiscoAquilaRadio.stop_playing = function(self, id)
  SA.stop_file(id)
end

DiscoAquilaRadio.play_random = function(self, unit)
  if #song_list == 0 then
    mod:echo("Cannot read the audio directory")
    return
  end

  if #playlist == 0 then
    playlist = table_clone(song_list)
  end

  local station = table_remove(playlist, random_range(random, 1, #playlist))
  local song = station.file_path
  local play_path = station._path

  if mod:get("da_print_song") then
    mod:echo(song)
  end

  if mod:get("da_play_once") and mod.song then return end
  local settings = mod:get("da_song_settings") or {}
  local song_settings = settings[song] or { volume = 80 }
  local opts = {
    volume      = song_settings.volume or 80,
    duration    = 20,
    on_finished = function() mod.song = nil end,
  }
  if not mod:get("da_remove_filter") then
    opts.filter = "0.5:0.9:50|60|40:0.4|0.32|0.3:0.25|0.4|0.3:2|2.3|1.3"
  end
  if mod:get("da_apply_master_volume") then
    opts.volume = mod:get("da_master_volume") or 80
  end
  play(play_path, opts, unit)
  return song
end

return DiscoAquilaRadio
