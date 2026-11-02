extends CharacterBody3D
class_name MayhemPlayer

signal fired(origin: Vector3, direction: Vector3, damage_amount: float, pellet_count: int)

const BASE_SPEED := 8.0
const GRAVITY := 24.0

var health := 100.0
var max_health := 100.0
var weapon_damage := 15.0
var attack_interval := 0.3
var pellets := 1
var lifesteal := 0.0
var chain_lightning := 0.0
var bonus_speed := 0.0
var level := 1
var xp := 0
var xp_to_level := 5
var gold := 0
var controls_enabled := true

var _attack_timer := 0.0
var _hurt_timer := 0.0
var _camera_pivot: Node3D
var _camera: Camera3D
var _body_mesh: MeshInstance3D

func _ready() -> void:
    name = "Player"
    var shape := CapsuleShape3D.new()
    shape.radius = 0.45
    shape.height = 1.8
    var collision := CollisionShape3D.new()
    collision.shape = shape
    collision.position.y = 0.9
    add_child(collision)

    _body_mesh = MeshInstance3D.new()
    var capsule := CapsuleMesh.new()
    capsule.radius = 0.45
    capsule.height = 1.8
    _body_mesh.mesh = capsule
    _body_mesh.position.y = 0.9
    var material := StandardMaterial3D.new()
    material.albedo_color = Color(0.25, 0.72, 1.0)
    _body_mesh.material_override = material
    add_child(_body_mesh)

    _camera_pivot = Node3D.new()
    _camera_pivot.position = Vector3(0.0, 1.6, 0.0)
    _camera_pivot.rotation_degrees.x = -12.0
    add_child(_camera_pivot)
    var arm := SpringArm3D.new()
    arm.spring_length = 5.0
    arm.add_excluded_object(get_rid())
    _camera_pivot.add_child(arm)
    _camera = Camera3D.new()
    _camera.fov = 75.0
    arm.add_child(_camera)
    _camera.current = true
    Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event: InputEvent) -> void:
    if not controls_enabled:
        return
    if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
        if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
            Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
        else:
            Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
        get_viewport().set_input_as_handled()
    elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        if Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
            Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
            get_viewport().set_input_as_handled()
    elif event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
        _camera_pivot.rotation.y -= event.relative.x * 0.003
        _camera_pivot.rotation.x = clampf(_camera_pivot.rotation.x - event.relative.y * 0.003, -0.9, 0.35)

func _physics_process(delta: float) -> void:
    _attack_timer = maxf(0.0, _attack_timer - delta)
    _hurt_timer = maxf(0.0, _hurt_timer - delta)
    var movement := Vector2.ZERO
    if controls_enabled and health > 0.0:
        movement.x = float(Input.is_key_pressed(KEY_D)) - float(Input.is_key_pressed(KEY_A))
        movement.y = float(Input.is_key_pressed(KEY_S)) - float(Input.is_key_pressed(KEY_W))
    movement = movement.normalized()
    var direction := _camera_pivot.global_basis * Vector3(movement.x, 0.0, movement.y)
    direction.y = 0.0
    direction = direction.normalized()
    velocity.x = direction.x * (BASE_SPEED + bonus_speed)
    velocity.z = direction.z * (BASE_SPEED + bonus_speed)
    if not is_on_floor():
        velocity.y -= GRAVITY * delta
    else:
        velocity.y = -0.5
    move_and_slide()
    if direction.length_squared() > 0.01:
        _body_mesh.rotation.y = lerp_angle(_body_mesh.rotation.y, atan2(direction.x, direction.z), minf(1.0, delta * 12.0))
    if controls_enabled and health > 0.0 and _attack_timer <= 0.0:
        var wants_fire := Input.is_key_pressed(KEY_SPACE)
        wants_fire = wants_fire or (Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT))
        if wants_fire:
            _attack_timer = attack_interval
            fired.emit(_camera.global_position, -_camera.global_basis.z, weapon_damage, pellets)

func take_damage(amount: float) -> void:
    if _hurt_timer > 0.0 or health <= 0.0:
        return
    health = maxf(0.0, health - amount)
    _hurt_timer = 0.45

func gain_xp(amount: int) -> bool:
    xp += amount
    if xp < xp_to_level:
        return false
    xp -= xp_to_level
    level += 1
    xp_to_level = int(ceil(float(xp_to_level) * 1.4)) + 2
    return true
