local mod = get_mod("Disco Aquila")
local Audio = get_mod("Audio")
local DLS = get_mod("DarktideLocalServer")
--local mt = get_mod("modding_tools")

local DiscoAquilaRadio = class("DiscoAquilaRadio")
local audio_file_handler
local os = os
local os_clock = os.clock
local playlist = {}
local random = PortableRandom:new(os_clock())
local random_range = random.random_range
local table = table
local table_clone = table.clone
local table_remove = table.remove

DiscoAquilaRadio.init = function(self)  
  Managers.backend:authenticate():next(function()
    audio_file_handler = Audio.new_files_handler({"caramelldansen.opus"})
  end)
end

DiscoAquilaRadio.get_music = function()
  return audio_file_handler and audio_file_handler:list() or {}
end

DiscoAquilaRadio.play_sample = function(self, song_name, volume)  
  return Audio.play_file(song_name, {audio_type = "sfx", volume = volume, duration = 20, track_status = function() mod.playingSample = nil end})
end

DiscoAquilaRadio.stop_playing = function(self, id)
  Audio.stop_file(id)
end

DiscoAquilaRadio.play_random = function(unit)    
  if not audio_file_handler._lookup_table then
    mod:echo("Cannot read the audio directory")
    return
  end
  
  if #playlist == 0 then
    playlist = table_clone(audio_file_handler:list())
  end
  
  
  local station = table_remove(playlist, random_range(random, 1, #playlist))  
  local song = station.file_path  
  
  mod:echo(song)
  
  if mod:get("da_play_once") and mod.song then return end  
  local settings = mod:get("da_song_settings") or {}
  local song_settings = settings[song] or {volume = 80}  
  local ffplay_args = {audio_type = "sfx", duration=20, volume=song_settings.volume}
  if not mod:get("da_remove_filter") then
    ffplay_args.chorus= "0.5:0.9:50|60|40:0.4|0.32|0.3:0.25|0.4|0.3:2|2.3|1.3"
  end
  local playid = Audio.play_file(song ,ffplay_args, unit)  
  return song
end

return DiscoAquilaRadio