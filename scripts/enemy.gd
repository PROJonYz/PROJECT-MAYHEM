extends CharacterBody3D
class_name MayhemEnemy

const GRAVITY := 24.0

var boss := false
var health := 30.0
var movement_speed := 3.0
var attack_damage := 8.0
var xp_reward := 1
var gold_reward := 2

var _attack_timer := 0.0

func _ready() -> void:
    var radius := 1.15 if boss else 0.45
    var height := 3.0 if boss else 1.8
    var collision_shape := CapsuleShape3D.new()
    collision_shape.radius = radius
    collision_shape.height = height
    var collision := CollisionShape3D.new()
    collision.shape = collision_shape
    collision.position.y = height * 0.5
    add_child(collision)
    var visible_mesh := MeshInstance3D.new()
    var capsule := CapsuleMesh.new()
    capsule.radius = radius
    capsule.height = height
    visible_mesh.mesh = capsule
    visible_mesh.position.y = height * 0.5
    var material := StandardMaterial3D.new()
    material.albedo_color = Color(0.65, 0.3, 0.95) if boss else Color(0.95, 0.25, 0.3)
    visible_mesh.material_override = material
    add_child(visible_mesh)

func tick(delta: float, target: MayhemPlayer) -> void:
    _attack_timer = maxf(0.0, _attack_timer - delta)
    var toward := target.global_position - global_position
    toward.y = 0.0
    var distance := toward.length()
    if target.health > 0.0 and distance > (2.5 if boss else 1.4):
        var direction := toward.normalized()
        velocity.x = direction.x * movement_speed
        velocity.z = direction.z * movement_speed
    else:
        velocity.x = 0.0
        velocity.z = 0.0
    if not is_on_floor():
        velocity.y -= GRAVITY * delta
    else:
        velocity.y = -0.5
    move_and_slide()
    if target.health > 0.0 and distance <= (2.5 if boss else 1.4) and _attack_timer <= 0.0:
        target.take_damage(attack_damage)
        _attack_timer = 1.4 if boss else 1.0

func take_damage(amount: float) -> bool:
    health -= amount
    return health <= 0.0
