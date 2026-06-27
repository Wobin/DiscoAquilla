local mod = get_mod("Disco Aquila")

local AudioBackend = {}

local AUDIO_DIR = "mods/Disco Aquila/audio/"
local EXTENSIONS = { "opus", "mp3", "ogg", "wav", "flac", "m4a", "aac", "mp4", "webm", "mkv", "mov", "flv" }
local FOLLOW_INTERVAL = 0.1

local Unit = Unit
local unit_alive = Unit.alive
local ipairs = ipairs
local pcall = pcall

local function basename(path)
  return path:match("[^/\\]+$") or path
end

-- SimpleAudio --------------------------------------------------------------

local function sa_list(SA)
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

local function sa_play(SA, path, opts, unit)
  local settings = {
    audio_type  = "sfx",
    volume      = opts.volume,
    duration    = opts.duration,
    on_finished = opts.on_finished,
  }
  if opts.filter then
    settings.filters = "chorus=" .. opts.filter
  end
  if unit and SA.set_position then
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

-- Audio plugin (DarktideLocalServer) ---------------------------------------

local function audio_list(Audio)
  local handler = Audio.new_files_handler({ "caramelldansen.opus" })
  local items = {}
  if handler and handler.list then
    for _, station in ipairs(handler:list()) do
      items[#items + 1] = { file_path = basename(station.file_path), _path = station.file_path }
    end
  end
  return items
end

local function audio_play(Audio, path, opts, unit)
  local args = {
    audio_type   = "sfx",
    duration     = opts.duration,
    volume       = opts.volume,
    track_status = opts.on_finished,
  }
  if opts.filter then
    args.chorus = opts.filter
  end
  return Audio.play_file(path, args, unit)
end

-- Selection ----------------------------------------------------------------

AudioBackend.select = function(SA, Audio, DLS)
  if SA then
    return {
      name       = "simpleaudio",
      list       = function() return sa_list(SA) end,
      play       = function(path, opts, unit) return sa_play(SA, path, opts, unit) end,
      stop       = function(id) return SA.stop_file(id) end,
      hook_sound = function(pattern, cb) return SA.hook_sound(pattern, cb) end,
    }
  elseif Audio and DLS then
    return {
      name       = "audio",
      list       = function() return audio_list(Audio) end,
      play       = function(path, opts, unit) return audio_play(Audio, path, opts, unit) end,
      stop       = function(id) return Audio.stop_file(id) end,
      hook_sound = function(pattern, cb) return Audio.hook_sound(pattern, cb) end,
    }
  end
  return nil
end

return AudioBackend
