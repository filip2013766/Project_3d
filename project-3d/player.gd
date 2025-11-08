extends RigidBody3D

# ----------- CAMERA + MOVEMENT SETTINGS -----------
var mouse_sensitivity := 0.0015
var twist_input := 0.0
var pitch_input := 0.0
var is_first_person := true

var move_speed := 1200.0
var sprint_multiplier := 1.8
var jump_force := 13.0
var grounded := false
var gravity_multiplier := 1.4

# Head bob
var head_bob_amount := 0.05
var head_bob_speed := 8.0
var bob_timer := 0.0

# ----------- REFERENCES -----------
@onready var twist_pivot := $TwistPivot
@onready var pitch_pivot := $TwistPivot/PitchPivot
@onready var camera_fp := $TwistPivot/PitchPivot/CameraFP
@onready var camera_tp := $TwistPivot/PitchPivot/CameraTP
@onready var ray_down := $RayDown


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	camera_fp.current = true
	camera_tp.current = false


func _process(delta: float) -> void:
	var input := Vector3.ZERO
	input.x = Input.get_axis("move_left", "move_right")
	input.z = Input.get_axis("move_foward", "move_back")

	# Sprint
	var speed := move_speed
	if Input.is_action_pressed("sprint"):
		speed *= sprint_multiplier

	# Apply movement force
	apply_central_force(twist_pivot.basis * input * speed * delta)

	# Jump
	grounded = ray_down.is_colliding()
	if Input.is_action_just_pressed("jump") and grounded:
		apply_impulse(Vector3.UP * jump_force)

	# Gravity / lagano padanje
	if not grounded:
		apply_central_force(Vector3.DOWN * gravity_multiplier * 100.0)

	# Mouse unlock
	if Input.is_action_just_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	# Camera rotation
	twist_pivot.rotate_y(twist_input)
	pitch_pivot.rotate_x(pitch_input)
	pitch_pivot.rotation.x = clamp(
		pitch_pivot.rotation.x,
		deg_to_rad(-30),
		deg_to_rad(30)
	)
	twist_input = 0.0
	pitch_input = 0.0

	# Switch view
	if Input.is_action_just_pressed("switch_view"):
		_toggle_camera_view()

	# Head bob
	_update_head_bob(delta, input)


# ----------- MOUSE INPUT -----------
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			twist_input -= event.relative.x * mouse_sensitivity
			pitch_input -= event.relative.y * mouse_sensitivity


# ----------- CAMERA SWITCH -----------
func _toggle_camera_view() -> void:
	is_first_person = !is_first_person
	camera_fp.current = is_first_person
	camera_tp.current = !is_first_person


# ----------- HEAD BOB / CAMERA FEEL -----------
func _update_head_bob(delta: float, input: Vector3) -> void:
	if input.length() > 0 and grounded:
		bob_timer += delta * head_bob_speed
		var bob_offset := Vector3(0, sin(bob_timer) * head_bob_amount, 0)
		
		# Ispravno u Godot 4
		var new_transform = pitch_pivot.transform
		new_transform.origin = bob_offset
		pitch_pivot.transform = new_transform
	else:
		# Reset
		var reset_transform = pitch_pivot.transform
		reset_transform.origin = Vector3.ZERO
		pitch_pivot.transform = reset_transform
		bob_timer = 0.0
