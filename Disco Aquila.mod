return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`Disco Aquila` encountered an error loading the Darktide Mod Framework.")

		new_mod("Disco Aquila", {
			mod_script       = "Disco Aquila/scripts/mods/Disco Aquila/Disco Aquila",
			mod_data         = "Disco Aquila/scripts/mods/Disco Aquila/Disco Aquila_data",
			mod_localization = "Disco Aquila/scripts/mods/Disco Aquila/Disco Aquila_localization",
		})
	end,
	packages = {},
  load_after = {
    "DarktideLocalServer",
    "Audio",
  },
  require = {
    "DarktideLocalServer",
    "Audio",
  },
  version = "1.3.3"
}
