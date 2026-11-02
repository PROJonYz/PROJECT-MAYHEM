extends Node3D

const UPGRADE_POOL: Array[String] = [
    "Power Shot", "Rapid Fire", "Multishot", "Vampirism",
    "Fleet Footed", "Extra Health", "Chain Lightning"
]

var player: MayhemPlayer
var enemies: Array[MayhemEnemy] = []
var rng := RandomNumberGenerator.new()
var elapsed := 0.0
var spawn_timer := 0.0
var boss_spawned := false
var choosing_upgrade := false
var run_finished := false

var hud: Label
var upgrade_panel: PanelContainer
var upgrade_title: Label
var upgrade_buttons: Array[Button] = []

func _ready() -> void:
    rng.randomize()
    _build_arena()
    player = MayhemPlayer.new()
    add_child(player)
    player.global_position = Vector3(0.0, 0.15, 0.0)
    player.fired.connect(_handle_shot)
    _build_ui()

func _build_arena() -> void:
    var world := WorldEnvironment.new()
    var environment := Environment.new()
    environment.background_mode = Environment.BG_COLOR
    environment.background_color = Color(0.07, 0.1, 0.16)
    environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    environment.ambient_light_color = Color(0.7, 0.78, 1.0)
    environment.ambient_light_energy = 0.7
    world.environment = environment
    add_child(world)
    var sunlight := DirectionalLight3D.new()
    sunlight.rotation_degrees = Vector3(-50.0, -30.0, 0.0)
    sunlight.light_energy = 1.3
    add_child(sunlight)

    var floor := StaticBody3D.new()
    floor.name = "ArenaFloor"
    add_child(floor)
    var floor_shape := BoxShape3D.new()
    floor_shape.size = Vector3(100.0, 0.4, 100.0)
    var collision := CollisionShape3D.new()
    collision.shape = floor_shape
    collision.position.y = -0.2
    floor.add_child(collision)
    var mesh := MeshInstance3D.new()
    var box := BoxMesh.new()
    box.size = floor_shape.size
    mesh.mesh = box
    mesh.position.y = -0.2
    var material := StandardMaterial3D.new()
    material.albedo_color = Color(0.18, 0.24, 0.22)
    mesh.material_override = material
    floor.add_child(mesh)
    for i in range(18):
        var decoration := MeshInstance3D.new()
        var column := CylinderMesh.new()
        column.top_radius = rng.randf_range(0.3, 0.9)
        column.bottom_radius = column.top_radius
        column.height = rng.randf_range(1.5, 4.0)
        decoration.mesh = column
        decoration.position = Vector3(rng.randf_range(-44.0, 44.0), column.height * 0.5, rng.randf_range(-44.0, 44.0))
        var rock_material := StandardMaterial3D.new()
        rock_material.albedo_color = Color(0.28, 0.33, 0.36)
        decoration.material_override = rock_material
        add_child(decoration)

func _build_ui() -> void:
    var layer := CanvasLayer.new()
    add_child(layer)
    hud = Label.new()
    hud.position = Vector2(18.0, 18.0)
    hud.add_theme_font_size_override("font_size", 20)
    layer.add_child(hud)
    var help := Label.new()
    help.text = "WASD move  |  Mouse look  |  Left click / Space shoot  |  Esc mouse  |  R restart"
    help.position = Vector2(18.0, 80.0)
    layer.add_child(help)
    var crosshair := Label.new()
    crosshair.text = "+"
    crosshair.add_theme_font_size_override("font_size", 27)
    layer.add_child(crosshair)
    crosshair.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
    crosshair.position = Vector2(-7.0, -17.0)

    var center := CenterContainer.new()
    layer.add_child(center)
    center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    center.mouse_filter = Control.MOUSE_FILTER_IGNORE
    upgrade_panel = PanelContainer.new()
    upgrade_panel.custom_minimum_size = Vector2(370.0, 260.0)
    center.add_child(upgrade_panel)
    var stack := VBoxContainer.new()
    upgrade_panel.add_child(stack)
    upgrade_title = Label.new()
    upgrade_title.text = "CHOOSE AN UPGRADE"
    upgrade_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    upgrade_title.add_theme_font_size_override("font_size", 23)
    stack.add_child(upgrade_title)
    for i in range(3):
        var option := Button.new()
        option.custom_minimum_size = Vector2(340.0, 58.0)
        option.pressed.connect(_choose_upgrade.bind(i))
        stack.add_child(option)
        upgrade_buttons.append(option)
    upgrade_panel.visible = false

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_R:
        get_tree().reload_current_scene()

func _physics_process(delta: float) -> void:
    if choosing_upgrade or run_finished:
        return
    elapsed += delta
    spawn_timer -= delta
    if spawn_timer <= 0.0 and enemies.size() < 45:
        _spawn_enemy(false)
        spawn_timer = maxf(0.4, 1.6 - elapsed * 0.012)
    if elapsed >= 75.0 and not boss_spawned:
        boss_spawned = true
        _spawn_enemy(true)
    for enemy in enemies.duplicate():
        if is_instance_valid(enemy):
            enemy.tick(delta, player)
    if player.health <= 0.0:
        _finish_run(false)

func _process(_delta: float) -> void:
    if player == null:
        return
    hud.text = "PROJECT MAYHEM  |  HP %d/%d  |  LVL %d  |  XP %d/%d  |  GOLD %d\nTIME %02d:%02d  |  ENEMIES %d  |  DMG %.1f  |  SHOTS %d" % [
        int(player.health), int(player.max_health), player.level,
        player.xp, player.xp_to_level, player.gold,
        int(elapsed / 60.0), int(elapsed) % 60, enemies.size(),
        player.weapon_damage, player.pellets
    ]

func _spawn_enemy(is_boss: bool) -> void:
    var enemy := MayhemEnemy.new()
    enemy.boss = is_boss
    if is_boss:
        enemy.health = 350.0
        enemy.movement_speed = 2.7
        enemy.attack_damage = 18.0
        enemy.xp_reward = 25
        enemy.gold_reward = 50
    else:
        enemy.health = 25.0 + elapsed * 0.35
        enemy.movement_speed = 3.0 + minf(2.5, elapsed * 0.012)
        enemy.gold_reward = rng.randi_range(1, 3)
    add_child(enemy)
    var angle := rng.randf_range(0.0, TAU)
    var distance := rng.randf_range(18.0, 25.0)
    enemy.global_position = player.global_position + Vector3(cos(angle) * distance, 0.15, sin(angle) * distance)
    enemies.append(enemy)

func _handle_shot(origin: Vector3, direction: Vector3, damage_amount: float, pellet_count: int) -> void:
    if choosing_upgrade or run_finished:
        return
    var spread_center := float(pellet_count - 1) * 0.5
    for i in range(pellet_count):
        var shot_direction := direction.rotated(Vector3.UP, (float(i) - spread_center) * 0.09)
        var query := PhysicsRayQueryParameters3D.create(origin, origin + shot_direction * 85.0)
        query.exclude = [player.get_rid()]
        var result := get_world_3d().direct_space_state.intersect_ray(query)
        if result.is_empty():
            continue
        var target = result.get("collider")
        if target is MayhemEnemy:
            _damage_enemy(target as MayhemEnemy, damage_amount, true)

func _damage_enemy(enemy: MayhemEnemy, amount: float, can_chain: bool) -> void:
    if not is_instance_valid(enemy) or not enemies.has(enemy):
        return
    if player.lifesteal > 0.0:
        player.health = minf(player.max_health, player.health + amount * player.lifesteal)
    var killed := enemy.take_damage(amount)
    if can_chain and player.chain_lightning > 0.0:
        for other in enemies.duplicate():
            if other != enemy and is_instance_valid(other) and other.global_position.distance_to(enemy.global_position) < 5.0:
                _damage_enemy(other, amount * player.chain_lightning, false)
                break
    if not killed:
        return
    var is_boss := enemy.boss
    var awarded_xp := enemy.xp_reward
    player.gold += enemy.gold_reward
    enemies.erase(enemy)
    enemy.queue_free()
    if is_boss:
        _finish_run(true)
    elif player.gain_xp(awarded_xp) and not choosing_upgrade and not run_finished:
        _offer_upgrades()

func _offer_upgrades() -> void:
    choosing_upgrade = true
    player.controls_enabled = false
    Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
    var choices: Array[String] = UPGRADE_POOL.duplicate()
    choices.shuffle()
    for i in range(3):
        upgrade_buttons[i].visible = true
        upgrade_buttons[i].text = choices[i]
        upgrade_buttons[i].set_meta("choice", choices[i])
    upgrade_title.text = "CHOOSE AN UPGRADE"
    upgrade_panel.visible = true

func _choose_upgrade(index: int) -> void:
    var choice: String = upgrade_buttons[index].get_meta("choice")
    match choice:
        "Power Shot":
            player.weapon_damage *= 1.25
        "Rapid Fire":
            player.attack_interval = maxf(0.08, player.attack_interval * 0.82)
        "Multishot":
            player.pellets += 1
        "Vampirism":
            player.lifesteal += 0.025
        "Fleet Footed":
            player.bonus_speed += 1.2
        "Extra Health":
            player.max_health += 30.0
            player.health += 30.0
        "Chain Lightning":
            player.chain_lightning += 0.25
    choosing_upgrade = false
    upgrade_panel.visible = false
    player.controls_enabled = true
    Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _finish_run(won: bool) -> void:
    if run_finished:
        return
    run_finished = true
    player.controls_enabled = false
    Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
    upgrade_title.text = "BOSS DEFEATED! Press R to restart" if won else "RUN FAILED! Press R to restart"
    for button in upgrade_buttons:
        button.visible = false
    upgrade_panel.visible = true
    _save_progress(won)

func _save_progress(won: bool) -> void:
    var path := "user://progress.json"
    var previous_gold := 0
    if FileAccess.file_exists(path):
        var old_data = JSON.parse_string(FileAccess.get_file_as_string(path))
        if old_data is Dictionary:
            previous_gold = int(old_data.get("total_gold", 0))
    var file := FileAccess.open(path, FileAccess.WRITE)
    if file != null:
        file.store_string(JSON.stringify({
            "total_gold": previous_gold + player.gold,
            "last_run_won": won,
            "last_run_level": player.level
        }))
