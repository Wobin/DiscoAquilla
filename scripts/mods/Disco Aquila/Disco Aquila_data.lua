local mod = get_mod("Disco Aquila")

local TrackOptions = mod:io_dofile("Disco Aquila/scripts/mods/Disco Aquila/modules/TrackOptions")

mod.track_options = TrackOptions

local tracks = TrackOptions.list_tracks()

TrackOptions.tracks = tracks
TrackOptions.migrate(tracks)

local widgets = {
	{
		setting_id = "da_play_once",
		type = "checkbox",
		tooltip = "da_play_desc",
		default_value = false,
	},
	{
		setting_id = "da_mute_drone",
		type = "checkbox",
		default_value = false,
	},
	{
		setting_id = "da_suppress_game_music",
		type = "checkbox",
		tooltip = "da_suppress_game_music_desc",
		default_value = false,
	},
	{
		setting_id = "da_stealth_mode",
		type = "checkbox",
		default_value = false,
	},
	{
		setting_id = "da_remove_filter",
		type = "checkbox",
		default_value = false,
	},
	{
		setting_id = "da_print_song",
		type = "checkbox",
		default_value = false,
	},
	{
		setting_id = "da_apply_master_volume",
		type = "checkbox",
		default_value = false,
		sub_widgets = {
			{
				setting_id = "da_master_volume",
				type = "numeric",
				default_value = 80,
				range = { 1, 100 },
				decimals_number = 0,
			},
		},
	},
}

if #tracks > 0 then
	widgets[#widgets + 1] = TrackOptions.build_widgets(tracks)
	widgets[#widgets + 1] = {
		setting_id = "da_preview_track",
		type = "button",
		title = "da_preview_track",
		button_text = "da_preview_track_button",
		button_trigger = "pressed",
		function_name = "preview_selected_track",
	}
else
	widgets[#widgets + 1] = {
		setting_id = "da_no_tracks",
		type = "checkbox",
		title = "da_no_tracks",
		default_value = false,
		require_restart = true,
	}
end

return {
	name = "Disco Aquila",
	description = mod:localize("mod_description"),
	is_togglable = true,
	options = {
		widgets = widgets,
	},
}
