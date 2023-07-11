class_name BounceBody2D
extends CharacterBody2D

@export var mass: float = 2.0
@export var bounce_coefficient: float = 0.9


func _collide(collision: KinematicCollision2D) -> void:
	if not collision.get_collider() is BounceBody2D:
		# Off a wall, say
		bounce(velocity.bounce(collision.get_normal()) * bounce_coefficient)
		return
	# Solution from here: https://www.youtube.com/watch?v=1L2g4ZqmFLQ
	var obj := collision.get_collider() as BounceBody2D
	var m_1: float = mass
	var m_2: float = obj.mass
	var u_1: Vector2 = velocity
	var u_2: Vector2 = obj.velocity
	var u_rel := u_1 - u_2
	var n := collision.get_normal().normalized()
	var e: float = bounce_coefficient * obj.bounce_coefficient
	var denom := (1 / m_1) + (1 / m_2)
	var impulse_length := -((1 + e) * u_rel.dot(n)) / denom
	var impulse := n * impulse_length
	var v_1 := u_1 + impulse / m_1
	var v_2 := u_2 - impulse / m_2
	bounce(v_1)
	obj.bounce(v_2)


func bounce(new_velocity: Vector2) -> void:
	velocity = new_velocity
