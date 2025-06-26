-- Title: Disco Aquila
-- Author: Wobin
-- Date: 27/06/2025
-- Version: 1.0.3

local mod = get_mod("Disco Aquila")
local Audio = get_mod("Audio")

local PortableRandom = require("scripts/foundation/utilities/portable_random")
local managers = Managers
local managers_event = managers.event
local managers_state = managers.state 
local os = os
local os_clock = os.clock

mod.version = "1.0.2"

mod:io_dofile("Disco Aquila/scripts/mods/Disco Aquila/Utils")

local findlocalvalue = mod.Utils.findlocalvalue

local flashlight_unit_large = "content/weapons/player/attachments/flashlights/flashlight_01/flashlight_01"

local unit = Unit
local unit_alive = unit.alive

mod.drones = {}


mod.on_all_mods_loaded = function()  
  mod:info(mod.version)
  if not Audio then
    mod:echo("The Audio plugin mod is required for this mod to function")
    return
  end
  local game_mode = Managers.state.game_mode and Managers.state.game_mode:game_mode_name()
  if game_mode and game_mode == "shooting_range" or game_mode == "coop_complete_objective" then			
      mod:init()
  end 
end

mod.on_settings_changed = function()
  
end

mod.on_unload = function(exit_game)
    mod:deinit()
end

mod.on_game_state_changed = function(status, sub_state_name)
  if status == "enter" and sub_state_name == "GameplayStateRun" then
		local game_mode = managers_state and managers_state.game_mode:game_mode_name()    
		if game_mode == "shooting_range" or game_mode == "coop_complete_objective" then			
      mod:init()
		end
	end
end

local random
local flashlight = mod:io_dofile("Disco Aquila/scripts/mods/Disco Aquila/modules/flashlight")
local radio = mod:io_dofile("Disco Aquila/scripts/mods/Disco Aquila/modules/radio")

mod.init = function(self)
    self.package_manager = managers.package
    self.package_manager:load("content/weapons/player/attachments/flashlights/flashlight_01/flashlight_01", "DiscoAqulia")          
    random = PortableRandom:new(os_clock())
    self.radio = radio:new()
    
    self.initialized = true       
end


mod.spawn_flashlight = function(self, lightFixture, drone_unit)
    table.insert(lightFixture, flashlight:new(self._world, drone_unit, random:random_range(0, 1000)))
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
end

local delta = 0
local cleanupdelta = 0
local cleanup_interval = 10

mod.update = function(dt, t)       
  if table.is_empty(mod.drones) or not mod.update_interval then return end
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
    mod.song = nil
    cleanupdelta = 0
  else
    cleanupdelta = cleanupdelta + dt
  end
end

--mod:io_dofile("Disco Aquila/scripts/mods/Disco Aquila/Debug")
--local extract_locals = mod.Debug.extract_locals

local trip_audio = function(sound_name, unit_id, targetUnit)
  if sound_name:match("play_buff_drone_buff_loop") then
    local drone = findlocalvalue({{"self", "Table", 9}})    
    mod._world = drone._world    
    local socket = mod.drones[drone.unit] or {lights = {}}
    if table.is_empty(socket.lights) then     
      mod.drones[drone.unit] = socket                
      mod:spawn_flashlight(socket.lights, drone.unit)        
      mod:spawn_flashlight(socket.lights, drone.unit)        
      mod:spawn_flashlight(socket.lights, drone.unit)        
      mod:spawn_flashlight(socket.lights, drone.unit)        
      mod:spawn_flashlight(socket.lights, drone.unit)        
    end
    mod.song = radio:play_random(drone.unit)
    if not mod.song then return end
    local settings = mod:get("da_song_settings") or {}
    local song_setting = settings[mod.song] or {bpm = 100}
    mod.update_interval = 60 / (song_setting.bpm or 100)
  end
end

mod:hook_safe(WwiseWorld, "trigger_resource_event", function(_wwise_world, wwise_event_name, unit_or_position_or_id)        
    if wwise_event_name:match("buff_drone") then            
			trip_audio(wwise_event_name, unit_or_position_or_id, Application.flow_callback_context_unit())
      return
		end
end)

mod:command("da", "stuff", function(action)
    mod.radio:play_random()
end)