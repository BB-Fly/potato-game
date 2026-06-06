class_name PlayableUiFactory
extends RefCounted


static func make_label(text: String, font_size: int, color: Color, alignment: HorizontalAlignment) -> Label:
	var label = Label.new()
	label.text = text
	label.horizontal_alignment = alignment
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	return label


static func make_pixel_button(text: String, pos: Vector2, size: Vector2) -> Button:
	var button = Button.new()
	button.text = text
	button.position = pos
	button.size = size
	button.add_theme_font_size_override("font_size", 22)
	button.add_theme_stylebox_override("normal", style_box(Color(0.12, 0.08, 0.04, 0.92), Color(0.9, 0.62, 0.24, 0.9), 2, 6))
	button.add_theme_stylebox_override("hover", style_box(Color(0.22, 0.13, 0.05, 0.98), Color(1.0, 0.8, 0.34, 1.0), 3, 6))
	button.add_theme_stylebox_override("pressed", style_box(Color(0.32, 0.18, 0.05, 1.0), Color(1.0, 0.88, 0.42, 1.0), 3, 6))
	return button


static func make_bar(position: Vector2, size: Vector2, fill_color: Color) -> ProgressBar:
	var bar = ProgressBar.new()
	bar.position = position
	bar.size = size
	bar.min_value = 0.0
	bar.max_value = 1.0
	bar.value = 1.0
	bar.show_percentage = false
	bar.add_theme_stylebox_override("background", style_box(Color(0.09, 0.06, 0.05, 0.9), Color(0.28, 0.2, 0.14, 0.9), 1, 4))
	bar.add_theme_stylebox_override("fill", style_box(fill_color, fill_color, 0, 4))
	return bar


static func make_sprite(texture_path: String, sprite_size: Vector2) -> TextureRect:
	var sprite = TextureRect.new()
	sprite.size = sprite_size
	sprite.pivot_offset = sprite_size * 0.5
	sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	sprite.texture = load_texture(texture_path)
	return sprite


static func make_sprite_from_texture(texture: Texture2D, sprite_size: Vector2) -> TextureRect:
	var sprite = TextureRect.new()
	sprite.size = sprite_size
	sprite.pivot_offset = sprite_size * 0.5
	sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	sprite.texture = texture
	return sprite


static func update_sprite_position(sprite: Control, world_pos: Vector2) -> void:
	if sprite == null or not is_instance_valid(sprite):
		return
	sprite.position = world_pos - sprite.size * 0.5


static func style_box(fill: Color, border: Color, border_width: int, corner_radius: int) -> StyleBoxFlat:
	var box = StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(border_width)
	box.set_corner_radius_all(corner_radius)
	box.content_margin_left = 14
	box.content_margin_right = 14
	box.content_margin_top = 12
	box.content_margin_bottom = 12
	return box


static func load_texture(path: String) -> Texture2D:
	if path.is_empty():
		return null
	var texture = load(path)
	if texture is Texture2D:
		return texture
	return null


static func load_frame_texture(frame_ref) -> Texture2D:
	if typeof(frame_ref) != TYPE_DICTIONARY:
		return load_texture(String(frame_ref))
	var path = String(frame_ref.get("path", ""))
	var columns = int(frame_ref.get("columns", 1))
	var rows = int(frame_ref.get("rows", 1))
	var frame_index = int(frame_ref.get("frame_index", 0))
	return load_atlas_texture(path, columns, rows, frame_index)


static func load_atlas_texture(path: String, columns: int, rows: int, frame_index: int) -> Texture2D:
	var sheet = load_texture(path)
	if sheet == null or columns <= 0 or rows <= 0:
		return sheet
	var frame_count = columns * rows
	var clamped_index = int(clamp(frame_index, 0, frame_count - 1))
	var frame_width = float(sheet.get_width()) / float(columns)
	var frame_height = float(sheet.get_height()) / float(rows)
	var column = clamped_index % columns
	var row = int(floor(float(clamped_index) / float(columns)))
	var atlas = AtlasTexture.new()
	atlas.atlas = sheet
	atlas.region = Rect2(
		Vector2(float(column) * frame_width, float(row) * frame_height),
		Vector2(frame_width, frame_height)
	)
	return atlas
