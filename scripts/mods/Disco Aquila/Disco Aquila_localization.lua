local mod = get_mod("Disco Aquila")
local InputUtils = require("scripts/managers/input/input_utils")

local localizations = {
	mod_description = {
		en = "Disco Aquila will bring music and light to the darkness of Tertium",
	},
  da_play_once = {
    en = "Play only one song at a time",    
  },
  da_play_desc = {
    en = "Will only play one song no matter how many drones are active"
    },
  da_song_name = {
    en = "Individual Song Settings"
  },
  da_song_desc = {
    en = "Selecting a song here will adjust the below sliders to the individual settings for that song"
    },
  da_song_volume = {
    en = "Volume"
  },
  da_song_bpm = {
    en = "BPM"
  },
  SelectAudio = {
    en = "Select Audio"
  },
  da_random_lights = {
    en = "Random Rainbow Lighting"
  },
  da_random_light_desc = {
    en = "turning this on will ignore the below colour choice"
    },
  da_light_one = {
    en = "Colour of Light One"
  },
  da_light_two = {
    en = "Colour of Light Two"
  },
  da_mute_drone = {
    en = "Mute the propaganda"
  },
  da_stealth_mode = {
    en = "Run with no lights"
    },
  Brasso = {
    en = "Brasso"
  },
  Caramelldansen = {
    en = "Caramelldansen"
  },
  FettyWapJBL = {
    en = "Fetty WAP JBL Speaker"
  },
  RAMRANCH = {
    en = "RAM RANCH"
  },
  SeriousSam = {
    en = "Serious Sam"
  },
  SoundOfDaPolice = {
    en = "Sound Of Da Police"
  },
}
local string = string
local string_split = string.split
local string_sub = string.sub
local string_format = string.format
local string_trim = string.trim
local string_upper = string.upper
local ipairs = ipairs
local inputUtils = InputUtils
local inputUtils_apply_color_to_input_text = inputUtils.apply_color_to_input_text

local function readable(text)
    local readable_string = ""
    local tokens = string_split(text, "_")
    for i, token in ipairs(tokens) do
        local first_letter = string_sub(token, 1, 1)
        token = string_format("%s%s", string_upper(first_letter), string_sub(token, 2))
        readable_string = string_trim(string_format("%s %s", readable_string, token))
    end

    return readable_string
end

local color_names = Color.list
for i, color_name in ipairs(color_names) do
    local color_values = Color[color_name](255, true)
    local text = inputUtils_apply_color_to_input_text(readable(color_name), color_values)
    localizations[color_name] = {
        en = text
    }
end

return localizations