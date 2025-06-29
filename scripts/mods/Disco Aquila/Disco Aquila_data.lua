local mod = get_mod("Disco Aquila")

local song_settings = {
        {text = "SelectAudio", value = "Select Audio"},
        {text = "Brasso", value = "Brasso.opus"},
        {text = "Caramelldansen", value = "caramelldansen.opus"},
        {text = "FettyWapJBL", value = "Fetty Wap JBL.opus"},
        {text = "RAMRANCH", value = "RAM RANCH.opus"},
        {text = "SeriousSam", value = "SeriousSam.opus"},
        {text = "Kirby", value = "Kirby dream land.opus"},
        {text = "DisposalUnitImperiumMix", value = "Disposal Unit Imperium Mix.opus"},
        {text = "LightoftheImperium", value = "Light of the Imperium.opus"},
        {text = "GangnamStyle", value = "Gangnam Style.opus"},
        -- Add any new music here. Place the sound file in the audio folder and name another entry in here        
        -- {text = "SongNameNoSpaces", value = "Song Name.opus"},
        --
        -- All music will play 20 seconds, so crop accordingly
        -- The filename on the right is case sensitive, so make sure it's exactly the same
        -- and make sure to add an entry into the localization for the SongNameNoSpaces
        
        }

local table = table
local ipairs = ipairs
local table_insert = table.insert
local table_sort = table.sort

local color_options = {}
for i, color_name in ipairs(Color.list) do
    table_insert(
        color_options,
        {
            text = color_name,
            value = color_name
        }
    )
end
table_sort(color_options, function(a, b) return a.text < b.text end
)

local function get_color_options()
    return table.clone(color_options)
end

local set_setting = {
  da_song_volume = function(settings) settings.volume = mod:get("da_song_volume") return settings end,
  da_song_bpm = function(settings) settings.bpm = mod:get("da_song_bpm") return settings end,
  da_random_lights = function(settings) settings.random_lights = mod:get("da_random_lights") return settings end,
  da_light_one = function(settings) settings.light_one = mod:get("da_light_one") return settings end,
  da_light_two = function(settings) settings.light_two = mod:get("da_light_two") return settings end,
}

mod.on_setting_changed = function(setting_id)
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
    local random_lights = song_settings["random_lights"] == nil and true or song_settings["random_lights"] 
    local light_one = song_settings["light_one"] or "White"
    local light_two = song_settings["light_two"] or "White"
    mod:set("da_song_volume", song_volume, false)
    mod:set("da_song_bpm", song_bpm, false)
    mod:set("da_random_lights", random_lights, false)
    mod:set("da_light_one", light_one, false)
    mod:set("da_light_two", light_two, false)
    return
  end
  
  local song = mod:get("da_song_name")     
  settings[song] = set_setting[setting_id] and set_setting[setting_id](settings[song] or {} )
  mod:set("da_song_settings", settings, false)
  
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
        setting_id = "da_mute_drone",
        type = "checkbox",
        default_value = false
      },
      {
        setting_id = "da_stealth_mode",
        type = "checkbox",
        default_value = false
      },      
      {
      setting_id = "da_song_name",
      type = "dropdown",
      tooltip = "da_song_desc",
      default_value = "Select Audio",
      options = song_settings
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
      {
        setting_id = "da_random_lights",
        type = "checkbox",
        default_value = true,
        tooltip = "da_random_light_desc"
        },
      {
        setting_id = "da_light_one",
        type = "dropdown",
        default_value = "white",
        options = get_color_options()
      },
      {
        setting_id = "da_light_two",
        type = "dropdown",
        default_value = "white",
        options = get_color_options()
      },
      
    }
  }
}
