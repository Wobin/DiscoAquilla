local mod = get_mod("Disco Aquila")


mod.on_setting_changed = function(setting_id)
--  if mod:get("da_song_name") == "Select Audio" then return end
  
  local settings = mod:get("da_song_settings") or {}
  
  if setting_id == "da_song_name" then
    local song = mod:get("da_song_name")
    
    if song == "Select Audio" then
      mod:set("da_song_volume", 0, false)
      mod:set("da_song_bpm", 80, false)      
      return
    end
    
    local settings = mod:get("da_song_settings") or {}
    local song_settings = settings[song] or {}
    local song_volume = song_settings["volume"] or 80
    local song_bpm = song_settings["bpm"] or 100
    mod:set("da_song_volume", song_volume, false)
    mod:set("da_song_bpm", song_bpm, false)
  end
  if setting_id == "da_song_volume" then
    local song = mod:get("da_song_name") 
    local song_settings = settings[song] or {}
    song_settings.volume = mod:get("da_song_volume")
    settings[song] = song_settings
    mod:set("da_song_settings", settings, false)
  end
  if setting_id == "da_song_bpm" then
    local song = mod:get("da_song_name") 
    local song_settings = settings[song] or {}
    song_settings.bpm = mod:get("da_song_bpm")
    settings[song] = song_settings
    mod:set("da_song_settings", settings, false)
  end
end


return {
	name = "Disco Aquila",
	description = mod:localize("mod_description"),
	is_togglable = true,
  options = {
		widgets = {
      {
        setting_id = "da_play_once",
        tooltip = "da_play_desc",
        type = "checkbox",
        default_value = false,
        },
      {
      setting_id = "da_song_name",
      type = "dropdown",
      default_value = "Select Audio",
      options = {
        {text = "SelectAudio", value = "Select Audio"},
        {text = "Brasso", value = "Brasso.opus"},
        {text = "Caramelldansen", value = "Caramelldansen.opus"},
        {text = "FettyWapJBL", value = "Fetty Wap JBL.opus"},
        {text = "RAMRANCH", value = "RAM RANCH.opus"},
        {text = "SeriousSam", value = "SeriousSam.opus"},
        {text = "SoundOfDaPolice", value = "SoundOfDaPolice.opus"},
        -- Add any new music here. Place the sound file in the audio folder and name another entry in here        
        -- {text = "SongNameNoSpaces", value = "Song Name.opus"},
        --
        -- All music will play 20 seconds, so crop accordingly
        -- and make sure to add an entry into the localization for the SongNameNoSpaces
        
        }
      },
      	{
				setting_id = "da_song_volume",
				type = "numeric",
				default_value = 80,    
        range = {0, 100},
        decimals_number = 0
			},
      	{
				setting_id = "da_song_bpm",
				type = "numeric",
				default_value = 100,    
        range = {80, 300},
        decimals_number = 0
			},
      
    }
  }
}
