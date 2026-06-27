local mod = get_mod("Disco Aquila")

--local mt = get_mod("modding_tools")

local DiscoAquilaRadio = class("DiscoAquilaRadio")
local backend
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

DiscoAquilaRadio.init = function(self, retried)
  if not Managers.backend:authenticated() and (retried or 0) > 0 then
    Promise.delay(10):next(function() self:init((retried or 0) - 1) end)
    return
  end

  backend = mod.audio_backend
  song_list = backend and backend.list() or {}
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
  return backend.play(path, {
    volume      = volume,
    duration    = 20,
    on_finished = function() mod.playingSample = nil end,
  })
end

DiscoAquilaRadio.stop_playing = function(self, id)
  backend.stop(id)
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
    volume      = song_settings.volume,
    duration    = 20,
    on_finished = function() mod.song = nil end,
  }
  if not mod:get("da_remove_filter") then
    opts.filter = "0.5:0.9:50|60|40:0.4|0.32|0.3:0.25|0.4|0.3:2|2.3|1.3"
  end
  if mod:get("da_apply_master_volume") then
    opts.volume = mod:get("da_master_volume")
  end
  backend.play(play_path, opts, unit)
  return song
end

return DiscoAquilaRadio
