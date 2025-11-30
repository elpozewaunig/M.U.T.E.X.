extends Label
var current_point = 0
var point_string = "Points: 0"
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	ScoreManager.score_updated.connect(increment_point)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	text = point_string

func increment_point(current_score):
	current_point = current_point + 1
	point_string = "Points: " + str(current_point)
	
	
