## Builds the forest tile set and the two Zone scenes from the plans below.
##
##   godot --headless --path . -s tools/build_zones.gd
##
## It writes assets/forest_tileset.tres, scenes/zones/forest_clearing.tscn and
## scenes/zones/deep_woods.tscn. Those are ordinary Godot resources: open and
## edit them in the editor. Running this again OVERWRITES them, so once a Zone
## has been edited by hand, change it in the editor, not here.
extends SceneTree

const TILE := 16
const COLUMNS := 12
const TILESET_PATH := "res://assets/forest_tileset.tres"
const ZONE_SCRIPT := "res://scripts/zones/zone.gd"
const ENTRANCE_SCRIPT := "res://scripts/zones/entrance.gd"

# Tile set sources.
const GROUND_SOURCE := 0
const TREE_SOURCE := 1

# Row 0 of the forest sheet.
const GRASS_A := Vector2i(0, 0)
const GRASS_B := Vector2i(1, 0)
const FLOWERS := Vector2i(2, 0)
const BRIDGE := Vector2i(3, 0)
const BUSH := Vector2i(4, 0)
const ROCK := Vector2i(5, 0)

# Terrains, and the sheet row each one's 47 tiles start at.
const GRASS := 0
const PATH := 1
const WATER := 2
const THICKET := 3
const TERRAIN_NAMES := ["grass", "path", "water", "thicket"]
const TERRAIN_COLORS := [Color("6cc24a"), Color("dcb070"), Color("4e94e8"), Color("1e6a3a")]
const FIRST_ROW := { PATH: 1, WATER: 5, THICKET: 9 }

# Plan letters: . grass, p path, w water, b bridge, t thicket.
const TERRAIN_OF := { "p": PATH, "w": WATER, "t": THICKET }

# Neighbour bits, matching art/tools/forest.lua: a set bit means that
# neighbour is the same ground. Each entry is [bit, offset, Godot neighbour].
const NEIGHBOURS := [
	[1, Vector2i(0, -1), TileSet.CELL_NEIGHBOR_TOP_SIDE],
	[2, Vector2i(1, 0), TileSet.CELL_NEIGHBOR_RIGHT_SIDE],
	[4, Vector2i(0, 1), TileSet.CELL_NEIGHBOR_BOTTOM_SIDE],
	[8, Vector2i(-1, 0), TileSet.CELL_NEIGHBOR_LEFT_SIDE],
	[16, Vector2i(1, -1), TileSet.CELL_NEIGHBOR_TOP_RIGHT_CORNER],
	[32, Vector2i(1, 1), TileSet.CELL_NEIGHBOR_BOTTOM_RIGHT_CORNER],
	[64, Vector2i(-1, 1), TileSet.CELL_NEIGHBOR_BOTTOM_LEFT_CORNER],
	[128, Vector2i(-1, -1), TileSet.CELL_NEIGHBOR_TOP_LEFT_CORNER],
]

var _masks: Array[int] = []


func _initialize() -> void:
	for mask in 256:
		if _canonical(mask) == mask:
			_masks.append(mask)
	assert(_masks.size() == 47)

	var tile_set := _build_tile_set()
	_check(ResourceSaver.save(tile_set, TILESET_PATH), TILESET_PATH)
	tile_set.take_over_path(TILESET_PATH)

	_build_zone(_forest_clearing(), tile_set)
	_build_zone(_deep_woods(), tile_set)
	quit()


# ---------------------------------------------------------------- the plans

## Forest Clearing: open grass west of a river, a path running east over a
## bridge and out through the trees to the Deep Woods.
func _forest_clearing() -> Dictionary:
	var grid := _new_grid(Vector2i(40, 30))
	_border(grid, 2)
	for block in [Rect2i(0, 0, 9, 5), Rect2i(33, 0, 7, 6), Rect2i(0, 24, 7, 6), Rect2i(31, 25, 9, 5), Rect2i(16, 0, 6, 4), Rect2i(14, 26, 8, 4)]:
		_fill(grid, block, "t")
	for y in 30:
		var centre := 27
		if y >= 8 and y <= 12:
			centre = 26
		elif y >= 18 and y <= 23:
			centre = 28
		_fill(grid, Rect2i(centre - 1, y, 3, 1), "w")
	_fill(grid, Rect2i(4, 14, 36, 2), "p")
	_fill(grid, Rect2i(12, 8, 2, 6), "p")
	_fill(grid, Rect2i(26, 14, 3, 2), "b")
	return {
		"name": "ForestClearing",
		"path": "res://scenes/zones/forest_clearing.tscn",
		"grid": grid,
		"start": Vector2i(6, 15),
		"trees": [Vector2i(10, 9), Vector2i(17, 7), Vector2i(21, 11), Vector2i(8, 20), Vector2i(15, 21), Vector2i(21, 19), Vector2i(32, 9), Vector2i(35, 19), Vector2i(31, 22), Vector2i(23, 24), Vector2i(5, 9), Vector2i(36, 11)],
		"rocks": [Vector2i(18, 13), Vector2i(9, 17), Vector2i(31, 12), Vector2i(23, 21)],
		"bushes": [Vector2i(15, 11), Vector2i(11, 22), Vector2i(33, 17), Vector2i(20, 17), Vector2i(31, 7)],
		"puffhops": [Vector2i(17, 10), Vector2i(18, 22), Vector2i(34, 11)],
		"entrances": [{
			"name": "East",
			"rect": Rect2(40 * TILE - 6, 14 * TILE, 6, 2 * TILE),
			"arrival_offset": Vector2(-22, 0),
			"to_zone": "res://scenes/zones/deep_woods.tscn",
			"to_entrance": "West",
		}],
	}


## Deep Woods: a path winding between blocks of thicket to a glade with a pond.
func _deep_woods() -> Dictionary:
	var grid := _new_grid(Vector2i(40, 30))
	_border(grid, 2)
	for block in [Rect2i(2, 2, 8, 10), Rect2i(16, 9, 12, 10), Rect2i(2, 18, 8, 10), Rect2i(34, 8, 4, 13), Rect2i(16, 0, 10, 3), Rect2i(34, 24, 6, 6)]:
		_fill(grid, block, "t")
	_fill(grid, Rect2i(0, 14, 14, 2), "p")
	_fill(grid, Rect2i(12, 5, 2, 11), "p")
	_fill(grid, Rect2i(12, 5, 20, 2), "p")
	_fill(grid, Rect2i(30, 5, 2, 19), "p")
	_fill(grid, Rect2i(20, 22, 12, 2), "p")
	_fill(grid, Rect2i(14, 24, 4, 3), "w")
	_fill(grid, Rect2i(15, 23, 2, 1), "w")
	return {
		"name": "DeepWoods",
		"path": "res://scenes/zones/deep_woods.tscn",
		"grid": grid,
		"trees": [Vector2i(11, 3), Vector2i(15, 3), Vector2i(28, 3), Vector2i(33, 3), Vector2i(33, 23), Vector2i(29, 26), Vector2i(11, 19), Vector2i(12, 26), Vector2i(25, 20), Vector2i(10, 12), Vector2i(15, 13), Vector2i(29, 15), Vector2i(21, 26), Vector2i(26, 26), Vector2i(33, 6), Vector2i(19, 20)],
		"rocks": [Vector2i(15, 8), Vector2i(28, 8), Vector2i(33, 14), Vector2i(19, 25)],
		"bushes": [Vector2i(11, 8), Vector2i(14, 18), Vector2i(28, 21), Vector2i(32, 20), Vector2i(23, 27), Vector2i(10, 16)],
		"puffhops": [Vector2i(15, 10), Vector2i(22, 7), Vector2i(32, 10), Vector2i(32, 18), Vector2i(24, 21), Vector2i(13, 21)],
		"entrances": [{
			"name": "West",
			"rect": Rect2(0, 14 * TILE, 6, 2 * TILE),
			"arrival_offset": Vector2(22, 0),
			"to_zone": "res://scenes/zones/forest_clearing.tscn",
			"to_entrance": "East",
		}],
	}


# ------------------------------------------------------------ plan helpers

func _new_grid(size: Vector2i) -> Array:
	var grid := []
	for y in size.y:
		var row := []
		row.resize(size.x)
		row.fill(".")
		grid.append(row)
	return grid


func _fill(grid: Array, rect: Rect2i, letter: String) -> void:
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			if y >= 0 and y < grid.size() and x >= 0 and x < grid[0].size():
				grid[y][x] = letter


## A band of thicket `thickness` tiles deep around the whole Zone.
func _border(grid: Array, thickness: int) -> void:
	var w: int = grid[0].size()
	var h: int = grid.size()
	_fill(grid, Rect2i(0, 0, w, thickness), "t")
	_fill(grid, Rect2i(0, h - thickness, w, thickness), "t")
	_fill(grid, Rect2i(0, 0, thickness, h), "t")
	_fill(grid, Rect2i(w - thickness, 0, thickness, h), "t")


func _letter(grid: Array, cell: Vector2i) -> String:
	if cell.y < 0 or cell.y >= grid.size() or cell.x < 0 or cell.x >= grid[0].size():
		return ""
	return grid[cell.y][cell.x]


# ---------------------------------------------------------------- tile set

func _build_tile_set() -> TileSet:
	var tile_set := TileSet.new()
	tile_set.tile_size = Vector2i(TILE, TILE)
	tile_set.add_physics_layer()
	tile_set.set_physics_layer_collision_layer(0, 1)
	tile_set.set_physics_layer_collision_mask(0, 0)
	tile_set.add_terrain_set()
	tile_set.set_terrain_set_mode(0, TileSet.TERRAIN_MODE_MATCH_CORNERS_AND_SIDES)
	for terrain in TERRAIN_NAMES.size():
		tile_set.add_terrain(0)
		tile_set.set_terrain_name(0, terrain, TERRAIN_NAMES[terrain])
		tile_set.set_terrain_color(0, terrain, TERRAIN_COLORS[terrain])

	var ground := TileSetAtlasSource.new()
	ground.texture = load("res://assets/forest_tiles.png")
	ground.texture_region_size = Vector2i(TILE, TILE)
	tile_set.add_source(ground, GROUND_SOURCE)
	for coords in [GRASS_A, GRASS_B, FLOWERS, BRIDGE, BUSH, ROCK]:
		ground.create_tile(coords)
	for coords in [GRASS_A, GRASS_B]:
		var data := ground.get_tile_data(coords, 0)
		data.terrain_set = 0
		data.terrain = GRASS
		for neighbour in NEIGHBOURS:
			data.set_terrain_peering_bit(neighbour[2], GRASS)
	ground.get_tile_data(GRASS_B, 0).probability = 0.3
	for coords in [BUSH, ROCK]:
		_make_solid(ground.get_tile_data(coords, 0), Rect2(-6, 0, 12, 7))
		ground.get_tile_data(coords, 0).y_sort_origin = 6

	for terrain in [PATH, WATER, THICKET]:
		for index in _masks.size():
			var coords := _blob_coords(terrain, index)
			ground.create_tile(coords)
			var data := ground.get_tile_data(coords, 0)
			data.terrain_set = 0
			data.terrain = terrain
			for neighbour in NEIGHBOURS:
				var same: bool = (_masks[index] & int(neighbour[0])) != 0
				data.set_terrain_peering_bit(neighbour[2], terrain if same else GRASS)
			if terrain != PATH:
				_make_solid(data, Rect2(-8, -8, 16, 16))

	# One tree, far bigger than a cell: it stands with the base of its trunk at
	# the bottom of its cell and is sorted by that point.
	var trees := TileSetAtlasSource.new()
	trees.texture = load("res://assets/tree.png")
	trees.texture_region_size = Vector2i(48, 64)
	tile_set.add_source(trees, TREE_SOURCE)
	trees.create_tile(Vector2i.ZERO)
	var tree := trees.get_tile_data(Vector2i.ZERO, 0)
	tree.texture_origin = Vector2i(0, 22)
	tree.y_sort_origin = 7
	_make_solid(tree, Rect2(-5, 1, 10, 7))
	return tile_set


func _make_solid(data: TileData, box: Rect2) -> void:
	data.add_collision_polygon(0)
	data.set_collision_polygon_points(0, 0, PackedVector2Array([
		box.position, Vector2(box.end.x, box.position.y), box.end, Vector2(box.position.x, box.end.y),
	]))


func _blob_coords(terrain: int, index: int) -> Vector2i:
	@warning_ignore("integer_division")
	return Vector2i(index % COLUMNS, FIRST_ROW[terrain] + index / COLUMNS)


## Drop corner bits that cannot matter: a corner counts only when both sides
## next to it are the same ground.
func _canonical(mask: int) -> int:
	var result := mask & 15
	if mask & 16 and mask & 1 and mask & 2:
		result |= 16
	if mask & 32 and mask & 4 and mask & 2:
		result |= 32
	if mask & 64 and mask & 4 and mask & 8:
		result |= 64
	if mask & 128 and mask & 1 and mask & 8:
		result |= 128
	return result


# ------------------------------------------------------------------- zones

func _build_zone(plan: Dictionary, tile_set: TileSet) -> void:
	var grid: Array = plan.grid
	var size := Vector2i(grid[0].size(), grid.size())

	var root := Node2D.new()
	root.name = plan.name
	root.set_script(load(ZONE_SCRIPT))
	root.set("size_in_tiles", size)

	var ground := _add(root, root, TileMapLayer.new(), "Ground") as TileMapLayer
	ground.tile_set = tile_set
	var decor := _add(root, root, TileMapLayer.new(), "Decor") as TileMapLayer
	decor.tile_set = tile_set
	var things := _add(root, root, Node2D.new(), "Things") as Node2D
	things.y_sort_enabled = true
	var props := _add(root, things, TileMapLayer.new(), "Props") as TileMapLayer
	props.tile_set = tile_set
	props.y_sort_enabled = true

	for y in size.y:
		for x in size.x:
			var cell := Vector2i(x, y)
			var letter := _letter(grid, cell)
			if letter == ".":
				ground.set_cell(cell, GROUND_SOURCE, GRASS_B if (x * 5 + y * 3) % 4 == 0 else GRASS_A)
				if (x * 7 + y * 11) % 19 == 0:
					decor.set_cell(cell, GROUND_SOURCE, FLOWERS)
			elif letter == "b":
				ground.set_cell(cell, GROUND_SOURCE, BRIDGE)
			else:
				var terrain: int = TERRAIN_OF[letter]
				ground.set_cell(cell, GROUND_SOURCE, _blob_coords(terrain, _masks.find(_mask_at(grid, cell))))
			# Trees crowd the thicket.
			if letter == "t" and (x + 2 * y) % 5 == 0:
				props.set_cell(cell, TREE_SOURCE, Vector2i.ZERO)

	for kind in [["trees", TREE_SOURCE, Vector2i.ZERO], ["rocks", GROUND_SOURCE, ROCK], ["bushes", GROUND_SOURCE, BUSH]]:
		for cell: Vector2i in plan[kind[0]]:
			assert(_letter(grid, cell) == ".", "%s: %s at %s is not on grass" % [plan.name, kind[0], cell])
			props.set_cell(cell, kind[1], kind[2])

	var starts := _add(root, root, Node2D.new(), "PuffhopStarts")
	for cell: Vector2i in plan.puffhops:
		assert(_letter(grid, cell) == ".", "%s: Puffhop at %s is not on grass" % [plan.name, cell])
		var marker := _add(root, starts, Marker2D.new(), "Puffhop") as Marker2D
		marker.position = _feet_in(cell)

	var entrances := _add(root, root, Node2D.new(), "Entrances")
	for spec: Dictionary in plan.entrances:
		var rect: Rect2 = spec.rect
		var entrance := _add(root, entrances, Area2D.new(), spec.name) as Area2D
		entrance.set_script(load(ENTRANCE_SCRIPT))
		entrance.position = rect.get_center()
		entrance.set("to_zone", spec.to_zone)
		entrance.set("to_entrance", spec.to_entrance)
		entrance.set("arrival_offset", spec.arrival_offset)
		var shape := _add(root, entrance, CollisionShape2D.new(), "Shape") as CollisionShape2D
		var box := RectangleShape2D.new()
		box.size = rect.size
		shape.shape = box

	if plan.has("start"):
		var start := _add(root, root, Marker2D.new(), "Start") as Marker2D
		start.position = _feet_in(plan.start)

	var packed := PackedScene.new()
	_check(packed.pack(root), plan.path)
	_check(ResourceSaver.save(packed, plan.path), plan.path)
	print("built ", plan.path)
	root.free()


## Which of a cell's eight neighbours are the same ground. Beyond the edge of
## the Zone counts as the same, and a bridge joins both path and water.
func _mask_at(grid: Array, cell: Vector2i) -> int:
	var own := _letter(grid, cell)
	var mask := 0
	for neighbour in NEIGHBOURS:
		var other := _letter(grid, cell + neighbour[1])
		if other == "" or other == own or (other == "b" and own in ["p", "w"]):
			mask |= neighbour[0]
	return _canonical(mask)


## Where something standing in `cell` has its feet.
func _feet_in(cell: Vector2i) -> Vector2:
	return Vector2(cell.x * TILE + 8, cell.y * TILE + 10)


func _add(root: Node, parent: Node, node: Node, node_name: String) -> Node:
	node.name = node_name
	parent.add_child(node, true)
	node.owner = root
	return node


func _check(error: int, what: String) -> void:
	if error != OK:
		push_error("could not write %s (error %s)" % [what, error])
		quit(1)
