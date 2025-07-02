local mod = get_mod("Disco Aquila")

mod.on_setting_changed = function(setting_id) 
  if setting_id == "da_open_setup" then
    mod:set("da_open_setup", false, false)  
    mod.setup:open()
  end
end

return {
	name = "Disco Aquila",
	description = mod:localize("mod_description"),
	is_togglable = true,
  options = {
		widgets = {
      {
        setting_id = "da_open_setup",
        type = "checkbox",
        default_value = false,      
      },      
    }
  }
}