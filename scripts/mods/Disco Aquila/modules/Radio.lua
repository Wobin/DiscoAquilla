local mod = get_mod("Disco Aquila")
local Audio = get_mod("Audio")
--local mt = get_mod("modding_tools")

local DiscoAquilaRadio = class("DiscoAquilaRadio")
local audio_file_handler

DiscoAquilaRadio.init = function(self)
  audio_file_handler = Audio.new_files_handler()
end

DiscoAquilaRadio.get_music = function()
  return audio_file_handler:list()
end

DiscoAquilaRadio.play_random = function(unit)    
  local station = audio_file_handler:random(nil, true)
  local song = station.file_path
  
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