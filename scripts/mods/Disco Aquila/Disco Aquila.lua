-- Title: Disco Aquila
-- Author: Wobin
-- Date: 12/07/2025
-- Version: 1.3.9

local mod = get_mod("Disco Aquila")
local Audio = get_mod("Audio")
local DLS = get_mod("DarktideLocalServer")
--local mt = get_mod("modding_tools")

local PortableRandom = require("scripts/foundation/utilities/portable_random")
local managers = Managers
local managers_event = managers.event
local managers_state = managers.state 
local os = os
local os_clock = os.clock
local pairs = pairs
local table = table
local table_insert = table.insert
local table_is_empty = table.is_empty

mod.version = "1.3.9"

mod:io_dofile("Disco Aquila/scripts/mods/Disco Aquila/Utils")

local findlocalvalue = mod.Utils.findlocalvalue

local flashlight_unit_large = "content/weapons/player/attachments/flashlights/flashlight_01/flashlight_01"

local unit = Unit
local unit_alive = unit.alive
local valid_zones = { 
                      survival = true,
                      shooting_range = true,
                      coop_complete_objective = true
                    }
mod.drones = {}

mod.on_all_mods_loaded = function()  
  mod:info(mod.version)
 if not Audio or not DLS then
    mod:echo("The Darktide Local Server and Audio plugin mods are required for Disco Aquila to function")
    return
  end  
end

mod.on_game_state_changed = function(status, state_name)
  if not mod.initialized and status == "enter" and state_name == "StateGameplay" then
    mod:init()
  end
end

mod.on_unload = function(exit_game)
    mod:deinit()
end

local random = PortableRandom:new(os_clock())
local random_range = random.random_range
local flashlight = mod:io_dofile("Disco Aquila/scripts/mods/Disco Aquila/modules/flashlight")
local radio = mod:io_dofile("Disco Aquila/scripts/mods/Disco Aquila/modules/radio")
local setup = mod:io_dofile("Disco Aquila/scripts/mods/Disco Aquila/modules/settingsui")

mod.init = function(self)
    self.package_manager = managers.package
    self.package_manager:load("content/weapons/player/attachments/flashlights/flashlight_01/flashlight_01", "DiscoAqulia")              
    self.radio = radio:new()
    self.setup = setup:new()
    self.initialized = true       
end

mod.spawn_flashlight = function(self, lightFixture, drone_unit, colour)
    table_insert(lightFixture, flashlight:new(self._world, drone_unit, random_range(random, 0, 1000), colour))
    for _,light in pairs(lightFixture) do            
      light:spawn_flashlight()   
      light:random_rotate()
    end
end

mod.deinit = function(self)
  if not self.drones then return end
  for _, socket in pairs(self.drones) do
    for _, light in pairs(socket.lights) do 
      light:despawn()
    end
  end
  self.drones = {}
  if mod.setup then 
    mod.setup:close()
  end
end

local delta = 0
local cleanupdelta = 0
local cleanup_interval = 10

mod.update = function(dt, t)       
  if not mod.initialized then return end
  
  mod.setup:update()  
  
  if mod:get("da_stealth_mode") or table_is_empty(mod.drones) or not mod.update_interval then return end
  if delta > mod.update_interval then
    for drone_unit, socket in pairs(mod.drones) do
      if unit_alive(drone_unit) then 
        for _, light in pairs(socket.lights) do
          light:random_rotate()
        end
      else
        cleanupdelta = 100
      end
    end
		delta = 0
	else
		delta = delta + dt
	end  
  if cleanupdelta > cleanup_interval then    
    local trash = {}    
    for drone_unit, drone in pairs(mod.drones) do
      if not unit_alive(drone_unit) then 
        trash[drone_unit] = true 
        for _, light in pairs(drone.lights) do
          light:despawn()
        end
      end
    end  
    for rubbish,_ in pairs(trash) do
      mod.drones[rubbish] = nil     
    end    
    cleanupdelta = 0
  else
    cleanupdelta = cleanupdelta + dt
  end
end

--mod:io_dofile("Disco Aquila/scripts/mods/Disco Aquila/Debug")
--local extract_locals = mod.Debug.extract_locals

local trip_audio = function(sound_name)
  if false or sound_name:match("play_buff_drone_buff_loop") then
    local drone = findlocalvalue({{"self", "Table", 7}})    
    mod._world = drone._world    
    
    local socket = mod.drones[drone.unit] or {lights = {}}
    local song = radio:play_random(drone._unit)
    
    if not song then return end
    
    local settings = mod:get("da_song_settings") or {}
    local song_settings = settings[song] or {}
    mod.settings = song_settings
    if table_is_empty(socket.lights) then     
      mod.drones[drone._unit] = socket           
      if not mod:get("da_stealth_mode") then
        
        if not song_settings.random_rainbow then          
          mod:spawn_flashlight(socket.lights, drone._unit, song_settings.colour_one)
          mod:spawn_flashlight(socket.lights, drone._unit, song_settings.colour_two)
          mod:spawn_flashlight(socket.lights, drone._unit, song_settings.colour_one)
          mod:spawn_flashlight(socket.lights, drone._unit, song_settings.colour_two)
        else          
          mod:spawn_flashlight(socket.lights, drone._unit)        
          mod:spawn_flashlight(socket.lights, drone._unit)        
          mod:spawn_flashlight(socket.lights, drone._unit)        
          mod:spawn_flashlight(socket.lights, drone._unit)        
          mod:spawn_flashlight(socket.lights, drone._unit)        
        end
      end
    end
    mod.song = song    
    mod.update_interval = 60 / (song_settings.bpm or 100) 
  end
end

Audio.hook_sound("buff_drone", function(_, sound_name, delta, unit_or_position_or_id)
    if not mod.initialized then return end
    trip_audio(sound_name)
    return not mod:get("da_mute_drone")
end)

mod:command("da", mod:localize("da_open_setup"), function ()
	mod.setup:open()
end)