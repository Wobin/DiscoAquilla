local mod = get_mod("Disco Aquila")
local PortableRandom = require("scripts/foundation/utilities/portable_random")
--local mt = get_mod("modding_tools")

-- Local Refs
local unit = Unit
local math = math
local pairs = pairs
local world = World
local class = class
local CLASS = CLASS
local light = Light
local vector3 = Vector3
local managers = Managers
local quaternion = Quaternion
local unit_light = unit.light
local unit_alive = unit.alive
local vector3_box = Vector3Box
local vector3_zero = vector3.zero
local vector3_unbox = vector3_box.unbox
local vector3_up = vector3.up
local unit_world_position = unit.world_position
local world_link_unit = world.link_unit
local light_set_enabled = light.set_enabled
local world_unlink_unit = world.unlink_unit
local world_destroy_unit = world.destroy_unit
local quaternion_rotate = quaternion.rotate
local world_spawn_unit_ex = world.spawn_unit_ex
local math_degrees_to_radians = math.degrees_to_radians
local light_set_intensity = light.set_intensity
local light_set_falloff_end = light.set_falloff_end
local light_set_ies_profile = light.set_ies_profile
local light_set_color_filter = light.set_color_filter
local unit_set_local_position = unit.set_local_position
local unit_set_local_rotation = unit.set_local_rotation
local light_set_casts_shadows = light.set_casts_shadows
local light_set_falloff_start = light.set_falloff_start
local light_set_spot_reflector = light.set_spot_reflector
local light_set_spot_angle_end = light.set_spot_angle_end
local light_set_spot_angle_start = light.set_spot_angle_start
local light_color_with_intensity = light.color_with_intensity
local unit_set_vector3_for_materials = unit.set_vector3_for_materials
local light_set_volumetric_intensity = light.set_volumetric_intensity
local light_set_correlated_color_temperature = light.set_correlated_color_temperature


-- Data

local flashlight_profile = {       
        unit = "content/weapons/player/attachments/flashlights/flashlight_01/flashlight_01",
        ies_profile = "content/environment/ies_profiles/narrow/flashlight_custom_03",
        color_temperature = 6200,
        spot_reflector = true,
        intensity= 32,
        spot_angle_start = 1/180 * math.pi,
        spot_angle_end = 80/180 * math.pi,
        falloff_start = 0,
        falloff_end = 40,
        volumetric_intensity = 1,
        offset = vector3_box(vector3(.075, 0, 0)),
  }

local DiscoAquilaFlashlight = class("DiscoAquilaFlashlight")

DiscoAquilaFlashlight.target_position = function(self)
    return self.unit and unit_world_position(self.unit, 1)
end

DiscoAquilaFlashlight.flashlight_unit_alive = function(self)
    return self.flashlight_unit and unit_alive(self.flashlight_unit)
end

DiscoAquilaFlashlight.spawn_flashlight = function(self)
  if self.initialised and not self:flashlight_unit_alive() then    
    if not self.unit then 
      mod:echo("unit not found") 
      return 
    end    
    local player_position = Unit.world_position(self.unit, 1)
    local flashlight_unit = self.flashlight_template.unit    
    if not player_position then return end    
    self.flashlight_unit = world_spawn_unit_ex(self._world, flashlight_unit, nil, player_position, Quaternion(Vector3.up(), math.degrees_to_radians(1)))
    --world_link_unit(self._world, self.flashlight_unit, 1, self.unit, 1)
    -- Offset
    local offset = self.flashlight_template.offset and vector3_unbox(self.flashlight_template.offset) or vector3_zero()
    unit_set_local_position(self.flashlight_unit, 1, player_position)
    -- Light
    self.light = unit_light(self.flashlight_unit, 1)    
    self:set_light()    
  end
end

DiscoAquilaFlashlight.despawn = function(self)
    if self:flashlight_unit_alive() then        
      --  world_unlink_unit(self._world, self.flashlight_unit)        
        world_destroy_unit(self._world, self.flashlight_unit)
        self.flashlight_unit = nil
    end
end

DiscoAquilaFlashlight.set_color = function(self, r, g, b)
    if self.light and self.flashlight_unit then
        light_set_color_filter(self.light, vector3(r or 0, g or 1, b or 0))
        local color = light_color_with_intensity(self.light) or vector3_zero()
        unit_set_vector3_for_materials(self.flashlight_unit, "light_color", color)
    end
end

DiscoAquilaFlashlight.rotate = function(self)    
  if self.light and self.flashlight_unit then
      unit_set_local_rotation(self.flashlight_unit, 1, Quaternion(-vector3_up(), math_degrees_to_radians(self.rotation)))
  end
end

DiscoAquilaFlashlight.set_light = function(self)
    if self.light then
        light_set_enabled(self.light, true)
        light_set_casts_shadows(self.light, self.flashlight_shadows)
        light_set_ies_profile(self.light, self.flashlight_template.ies_profile)
        light_set_correlated_color_temperature(self.light, self.flashlight_template.color_temperature)
        light_set_spot_reflector(self.light, self.flashlight_template.spot_reflector)
        light_set_intensity(self.light, self.flashlight_template.intensity)
        light_set_spot_angle_start(self.light, self.flashlight_template.spot_angle_start)
        light_set_spot_angle_end(self.light, self.flashlight_template.spot_angle_end)
        light_set_falloff_start(self.light, self.flashlight_template.falloff_start)
        light_set_falloff_end(self.light, self.flashlight_template.falloff_end)
        light_set_volumetric_intensity(self.light, volumetric_intensity or self.flashlight_template.volumetric_intensity)
        self:set_color(self.r, self.g, self.b)
    end
end

local random 

DiscoAquilaFlashlight.random_rotate = function(self)
  self.rotation = random:random_range(0, 360)
  if not self.colour then
    self.r = random:random_range(0, 1)
    self.g = random:random_range(0, 1)
    self.b = random:random_range(0, 1)
  end
  self:set_color(self.r, self.g, self.b)
  self:rotate()  
end

local Color = Color

DiscoAquilaFlashlight.init = function(self, world, unit, seed, colour)
  self.flashlight_template = flashlight_profile
  self._world = world
  self.unit = unit
  self.seed = seed
  self.colour = colour
  self.light = nil
  if colour then     
    self.r = colour.r
    self.g = colour.g
    self.b = colour.b
  end
  random = PortableRandom:new(seed)  
  self.initialised = true  
end

return DiscoAquilaFlashlight
