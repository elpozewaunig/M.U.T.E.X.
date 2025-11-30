extends Node

const SAVE_FILE_PATH = "user://highscores.json"
const MAX_HIGHSCORES = 10 # Keep only top 10

# Current Session Score
var current_score = 0
var current_team_name = "Unnamed Team"

# Signal to update UI
signal score_updated(new_score)
signal game_over()

func _ready():
	current_score = 0
	if not FileAccess.file_exists(SAVE_FILE_PATH):
		save_highscores([]) 

func add_score(amount: int = 1):
	if not multiplayer.is_server():
		return
		
	current_score += amount
	score_updated.emit(current_score)
	print("tets")
	
	# Sync score to clients (RPC)
	rpc("sync_score", current_score)
	
func signal_game_over():
	game_over.emit()

@rpc("authority", "call_remote")
func sync_score(new_val):
	current_score = new_val
	score_updated.emit(current_score)

func reset_score():
	current_score = 0
	score_updated.emit(0)
	if multiplayer.is_server():
		rpc("sync_score", 0)

# --- SAVE SYSTEM (JSON) ---
func save_current_run():
	# 1. Load existing scores
	var highscores = load_highscores()
	
	# 2. Add current run
	var new_entry = {
		"TeamName": current_team_name,
		"score": current_score
	}
	highscores.append(new_entry)
	
	# 3. Sort (Highest score first)
	highscores.sort_custom(func(a, b): return a.score > b.score)
	
	# 4. Limit to Top 10
	if highscores.size() > MAX_HIGHSCORES:
		highscores.resize(MAX_HIGHSCORES)
		
	# 5. Save back to file
	save_highscores(highscores)

func load_highscores() -> Array:
	if not FileAccess.file_exists(SAVE_FILE_PATH):
		return []
		
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
	var content = file.get_as_text()
	
	var json = JSON.new()
	var error = json.parse(content)
	
	if error == OK:
		var data = json.get_data()
		if data is Array:
			return data
	
	return []

func save_highscores(data: Array):
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	var json_string = JSON.stringify(data, "\t") # \t makes it pretty print
	file.store_string(json_string)
	file.close()
	print("Highscores saved to: ", ProjectSettings.globalize_path(SAVE_FILE_PATH))
