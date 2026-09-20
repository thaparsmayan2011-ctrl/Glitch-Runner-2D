extends Node2D

const OBSTACLESCENE=preload("res://obstacle.tscn")

func _ready():
	process_mode= Node.PROCESS_MODE_ALWAYS
	$SpawnTimer.timeout.connect(_Spawn_timeout)
	
	
	select_character("boy")
	$CanvasLayer/StartPanel/selectcharbtn.pressed.connect(open_char_select)
	
	$CanvasLayer/Charselectpanel/Leftarrow.pressed.connect(cycle_character.bind(-1))
	$CanvasLayer/Charselectpanel/Rightarrow.pressed.connect(cycle_character.bind(1))
	$CanvasLayer/Charselectpanel/Confirm.pressed.connect(close_char_select)
	$CanvasLayer/Charselectpanel.visible = false
	
	get_tree().paused =true
	$CanvasLayer/StartPanel.visible=true
	$CanvasLayer/GameOverPanel.visible =false
	$CanvasLayer/GlitchLabel.text = "GLITCH: READY"
	load_high_score()
	if skip_start_screen:
		skip_start_screen = false
		select_character(persisted_character)
		start_game()
		
func start_game():
	if game_start:
		return
		
	game_start=true
	glitch_available= true
	glitch_active = false
	glitch_time= 0
	glitch_cooldown= 0
	$CanvasLayer/GlitchLabel.text ="GLITCH: READY"
	$player.set_character(selected_character)
	$CanvasLayer/StartPanel.visible=false
	get_tree().paused=false
	$SpawnTimer.start()
	$MusicPlayer.play()
	score = 0
	timeS= 0
	milestone= 100
	score_time = 0
static var	skip_start_screen= false
static var persisted_character ="boy"
var score=0
var timeS= 0.0
var gameover_state= false
var game_start = false

var selected_character= "boy"
var characterlist = ["boy", "girl", "rocket"]
var characterindex =0

var high_score=0
var glitch_active=false
var glitch_time=0
var glitch_duration=2
var glitch_available= true
var glitch_cooldown=0
var glitch_cooldown_max = 4
var milestone = 100
var difficulty_stage =1
var obstacle_speed=300
var gravity_flip_active = false
var gravity_flip_time=0
var gravity_flip_duration = 8
var gravity_flip_next = 250
var user_paused =false
var surge_active=false
var surge_timer = 0
var surge_duration= 3
var surge_cooldown= 12
var surge_next= 12
var speed_multiplier = 1
var glitch_speed_multiplier = 1
var score_time =0
var streak = 0
var sfx_muted = false
var musicmute= false

var gravity_flip_pending = false
var surge_pending = false

func _process(delta):
	if gameover_state or not game_start or user_paused:
		return
	if glitch_active:
		glitch_time -= delta
		if glitch_time <=0:
			glitch_time = 0
			glitch_active = false
			print("Glitch Ended")
			 	
		
	if glitch_cooldown >0:
		glitch_cooldown -=delta
		if glitch_cooldown <=0:
			glitch_cooldown = 0
			glitch_available = true
	if glitch_available:
		$CanvasLayer/GlitchLabel.text = "GLITCH: READY"
	else: 
		$CanvasLayer/GlitchLabel.text = "GLITCH COOLDOWN: " + str(snapped(glitch_cooldown, 0.1))
	$player.set_glitch_visual(glitch_active)
	$player.set_gravity_visual(gravity_flip_active)
			
	timeS += delta
	glitch_speed_multiplier = 1.5 if glitch_active else 1
	score_time += delta* glitch_speed_multiplier
	score=int(score_time*10)
	difficulty_stage= min(5, 1+ int(score/250))
	update_bg_tint()
	obstacle_speed = min(550, 300 + timeS* 4)
	if score> high_score:
		high_score=score
	if score>= milestone:
		print("MILESTONE REACHED: ", milestone)
		flash_milestone()
		milestone += 100
	
	if gravity_flip_active:
		gravity_flip_time -= delta
		if gravity_flip_time <=0:
			gravity_flip_time = 0
			gravity_flip_active= false
			$Ceiling.visible = false
			$Ceiling2.visible = false
			$Ceiling/CollisionShape2D.disabled = true
			$Ceiling2/CollisionShape2D.disabled = true
			$player.velocity.y = 0
	if score >= gravity_flip_next and not gravity_flip_active and not gravity_flip_pending:
		gravity_flip_pending = true
		$CanvasLayer/EventLabel.text= "WARNING: GRAVITY FLIP PENDING"
		$CanvasLayer/EventLabel.modulate = Color(1,1,1)
		await get_tree().create_timer(1).timeout
		gravity_flip_pending = false
		start_gravity_flip()
		gravity_flip_next += 250
		
	if surge_active:
		surge_timer -= delta
		if surge_timer <= 0:
			surge_timer =0
			surge_active = false
			speed_multiplier = 1
	if not surge_active and timeS >= surge_next and not surge_pending:
		surge_pending = true
		$CanvasLayer/EventLabel.text = "WARNING: SPEED SURGE INCOMING"
		$CanvasLayer/EventLabel.modulate = Color(1,1,1)
		await get_tree().create_timer(1).timeout
		surge_pending = false
		start_surge()
		surge_next = timeS + surge_cooldown
		
	if not gravity_flip_active and not surge_active and not gravity_flip_pending and not surge_pending:
		$CanvasLayer/EventLabel.text = ""
		
		
		
				
		
		
	$CanvasLayer/ScoreLabel.text= "Distance: " + str(score)+"\nBest: " + str(high_score)
	
func _Spawn_timeout():
	if gameover_state or not game_start:
		return
		
	var Obstacle= OBSTACLESCENE.instantiate()
	if gravity_flip_active:
		Obstacle.position = Vector2(1300, 150)
	else:	
		Obstacle.position = Vector2(1300, 550)
	Obstacle.ceiling_mode = gravity_flip_active
	Obstacle.height= randi_range(45, 85)
	Obstacle.base_scrollv = obstacle_speed * speed_multiplier * glitch_speed_multiplier
	if difficulty_stage >= 2 and glitch_available and randf() < 0.25:
		Obstacle.corrupted = true
	if difficulty_stage >=5:
		Obstacle.base_scrollv += 5
			
			
		
		
		
	add_child(Obstacle)
	if difficulty_stage >=4 and randf() < 0.2:
		var Obstacle2 = OBSTACLESCENE.instantiate()
		Obstacle2.position = Obstacle.position + Vector2(180, 0)
		Obstacle2.height = randi_range(45, 85)
		Obstacle2.base_scrollv = Obstacle.base_scrollv
		Obstacle2.ceiling_mode = Obstacle.ceiling_mode
		add_child(Obstacle2)
		
		
	var new_wait = max(0.65, 1.5 - timeS*0.025) + randf_range(-0.2, 0.3)
	$SpawnTimer.wait_time = new_wait
	
	
	
	
	
func flash_milestone():
	$CanvasLayer/ScoreLabel.modulate = Color(1, 1, 0)
	await get_tree().create_timer(0.3).timeout
	$CanvasLayer/ScoreLabel.modulate = Color(1, 1, 1)
	
func game_over():
	if gameover_state:
		return
		
	gameover_state=true
	$player.velocity = Vector2.ZERO
	$player.shake_camera()
	print("GAME OVER FUNCTION WORKING")
	$SpawnTimer.stop()
	play_gameover_sfx()
	
	
	$CanvasLayer/GameOverPanel.visible=true
	print("GAME OVER PANEL SET VISIBLE")
	$CanvasLayer/StartPanel.visible=false
	
	$CanvasLayer/GameOverPanel/FinalScore.text= "Score: " +str(score) + "\nBest: " + str(high_score) + "\nGlitch: " + ("READY" if glitch_available else str(snapped(glitch_cooldown, 0.1))) 
	save_high_score()
	get_tree().paused = true
	
func _unhandled_input(event):
	if not game_start and not $CanvasLayer/Charselectpanel.visible and event.is_action_pressed("ui_accept"):
		start_game()
		
	if $CanvasLayer/Charselectpanel.visible:
		if 	event.is_action_pressed("ui_left"):
			cycle_character(-1)
		if event.is_action_pressed("ui_right"):
			cycle_character(1)
		if event.is_action_pressed("ui_accept"):
			close_char_select()		
				
	if game_start and not gameover_state and event.is_action_pressed("glitch") and glitch_available:
		start_glitch()
		
			
	if (gameover_state or user_paused) and event.is_action_pressed("restart"):
		skip_start_screen = false
		get_tree().paused = false
		get_tree().reload_current_scene()
	if gameover_state and event.is_action_pressed("ui_accept"):
		skip_start_screen = true
		persisted_character = selected_character
		get_tree().paused =false
		get_tree().reload_current_scene()
	
	if game_start and not gameover_state and event.is_action_pressed("ui_cancel"):
		toggle_pause()
	
	if event.is_action_pressed("Mute"):
		toggle_sfx_mute()
		
	if event.is_action_pressed("mutemusic"):
		toggle_music_mute()
	
		
		
		
		
		
		
	
	
func start_glitch():
	if not game_start:
		return
	if gameover_state:
		return
		
	if not glitch_available:
		return
	glitch_active = true
	glitch_time=glitch_duration
	play_glitch_beep()
	glitch_available = false
	glitch_cooldown= glitch_cooldown_max
	print("Glitch Activated")
	
	
func add_bonus(amount):
	if gameover_state:
		return
	score += amount	

func play_glitch_beep():
	var gen = AudioStreamGenerator.new()
	gen.mix_rate = 22050
	gen.buffer_length = 0.1
	$GlitchSFX.stream=gen
	$GlitchSFX.play()
	var playback = $GlitchSFX.get_stream_playback()
	for i in range(600):
		var v = sin(i*0.9)*0.3
		playback.push_frame(Vector2(v, v))
		
	
func start_gravity_flip():
	gravity_flip_active= true
	gravity_flip_time = gravity_flip_duration
	$CanvasLayer/EventLabel.text = "GRAVITY FLIPPED!"
	$CanvasLayer/EventLabel.modulate = Color(0.4, 0.6, 1)
	$Ceiling.visible = true
	$Ceiling2.visible = true
	$Ceiling/CollisionShape2D.disabled = false
	$Ceiling2/CollisionShape2D.disabled = false
	$player.velocity.y = -600



func start_surge():
	surge_active = true
	surge_timer = surge_duration
	speed_multiplier = 1.6
	$CanvasLayer/EventLabel.text = "SPEED SURGE!"
	$CanvasLayer/EventLabel.modulate = Color(1, 0.3, 0.3)
	
func toggle_pause():
	user_paused = not user_paused
	get_tree().paused= user_paused
	$CanvasLayer/PausePanel.visible = user_paused
	


func load_high_score():
	if FileAccess.file_exists("user://highscore.save"):
		var file= FileAccess.open("user://highscore.save", FileAccess.READ) 
		high_score = file.get_32()
		file.close()
		
func save_high_score():
	var file= FileAccess.open("user://highscore.save", FileAccess.WRITE)
	file.store_32(high_score)
	file.close()


func obstacle_cleared(used_glitch):
	if gameover_state:
		return
	if used_glitch:
		streak=0
	else:
		streak +=1
	var bonus = 5 + min(streak* 2, 25)
	score +=bonus		
	$CanvasLayer/StreakLabel.text = "Streak: " + str(streak) if streak > 0 else ""
	
func play_jump_sfx():
	var gen = AudioStreamGenerator.new()
	gen.mix_rate= 22050
	gen.buffer_length = 0.1
	$JumpSFX.stream = gen
	$JumpSFX.play()
	var playback = $JumpSFX.get_stream_playback()
	for i in range(300):
		var v = sin(i*1.4)*0.25
		playback.push_frame(Vector2(v, v))
		
func play_gameover_sfx():
	var gen = AudioStreamGenerator.new()
	gen.mix_rate = 22050
	gen.buffer_length = 0.3
	$GameOverSFX.stream = gen
	$GameOverSFX.play()
	var playback = $GameOverSFX.get_stream_playback()
	for i in range(2000):
		var freq= 1 - float(i)/2000
		var v =sin(i*freq* 0.5)*0.3
		playback.push_frame(Vector2(v, v))
		
func update_bg_tint():
	var stage_colors = [Color(0.12, 0.12, 0.15),
	 Color(0.20, 0.12, 0.22), Color(0.30, 0.10, 0.20), Color(0.40, 0.08, 0.10), Color(0.55, 0.05, 0.05)]
	$BGTint.color = stage_colors[difficulty_stage - 1]
	

func toggle_sfx_mute():
	sfx_muted = not sfx_muted
	var vol = -80 if sfx_muted else 0
	$GlitchSFX.volume_db= vol
	$JumpSFX.volume_db = vol
	$GameOverSFX.volume_db = vol
	
	
func toggle_music_mute():
	musicmute =not musicmute
	$MusicPlayer.volume_db = -80 if musicmute else 0
	
func select_character(character_name):
	selected_character = character_name
	characterindex =characterlist.find(character_name)
	var textures= {
		"boy": preload("res://sprites/boynormal.png"),
		"girl": preload("res://sprites/girlnormal.png"),
		"rocket": preload("res://sprites/rocketmain.png")
	}
	var names= {"boy": "Scott", "girl": "Cynthia", "rocket": "Rocket"}
	
	$CanvasLayer/Charselectpanel/charpreview.texture = textures[character_name]	
	$CanvasLayer/Charselectpanel/charnameLabel.text =names[character_name]
	 
func open_char_select():
	$CanvasLayer/StartPanel.visible = false
	$CanvasLayer/Charselectpanel.visible = true
	$CanvasLayer/Sfxlabel.visible =false
	$CanvasLayer/MusicLabel.visible =false
	
func close_char_select():
	$CanvasLayer/Charselectpanel.visible =false
	$CanvasLayer/StartPanel.visible = true
	$CanvasLayer/Sfxlabel.visible=true
	$CanvasLayer/MusicLabel.visible =true
	
func cycle_character(direction):
	characterindex =(characterindex+ direction) % characterlist.size()
	if characterindex< 0:
		characterindex+= characterlist.size()
	select_character(characterlist[characterindex])		
