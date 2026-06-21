extends RefCounted
class_name GameTheme


static func create_button_theme() -> Theme:
	var game_theme := Theme.new()
	
	var normal_style := create_button_style(
		Color("#A9D7E8"), # pale blue button face
		Color("#687E8F"), # bluish grey outline
		Color("#24313B")  # dark shadow
	)
	
	var hover_style := create_button_style(
		Color("#BDEBFA"), # lighter pale blue
		Color("#7F96A8"),
		Color("#24313B")
	)
	
	var pressed_style := create_button_style(
		Color("#7EAFC4"), # darker pressed blue
		Color("#4E6678"),
		Color("#101820")
	)
	
	var disabled_style := create_button_style(
		Color("#566B75"),
		Color("#3E4F5A"),
		Color("#101820")
	)
	
	game_theme.set_stylebox("normal", "Button", normal_style)
	game_theme.set_stylebox("hover", "Button", hover_style)
	game_theme.set_stylebox("pressed", "Button", pressed_style)
	game_theme.set_stylebox("disabled", "Button", disabled_style)
	
	game_theme.set_color("font_color", "Button", Color("#102A3A"))
	game_theme.set_color("font_hover_color", "Button", Color("#071821"))
	game_theme.set_color("font_pressed_color", "Button", Color("#EAF8FF"))
	game_theme.set_color("font_disabled_color", "Button", Color("#5E6D73"))
	game_theme.set_color("font_focus_color", "Button", Color("#102A3A"))
	
	game_theme.set_color("font_outline_color", "Button", Color("#DDF7FF"))
	game_theme.set_constant("outline_size", "Button", 1)
	
	game_theme.set_font_size("font_size", "Button", 22)
	
	return game_theme


static func create_button_style(
	background_color: Color,
	border_color: Color,
	shadow_color: Color
) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	
	style.bg_color = background_color
	
	style.border_color = border_color
	style.set_border_width_all(3)
	
	style.set_corner_radius_all(6)
	
	style.shadow_color = shadow_color
	style.shadow_size = 4
	style.shadow_offset = Vector2(3, 3)
	
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	
	return style
