extends Control

# 定义动画完成的信号
signal animation_completed

# 获取标签节点
@onready var title_label = $"警告标题"
@onready var content_label = $"警告内容"
@onready var prompt_label = $"按键提示"

# 动画状态
enum AnimState {FADING_IN, WAITING, FADING_OUT, DONE}
var current_state = AnimState.FADING_IN
var current_step = 0
var is_key_pressed = false

# 淡入淡出参数
const FADE_DURATION = 0.3  # 淡入淡出的持续时间
const STEP_DELAY = 0.1  # 每个步骤之间的延迟
var elapsed_time = 0.0

# 在初始化时隐藏所有标签
func _ready():
	title_label.modulate.a = 0.0
	content_label.modulate.a = 0.0
	prompt_label.modulate.a = 0.0
	
	# 修改按键提示文本
	prompt_label.text = "按下任意键继续"

# 处理帧更新
func _process(delta):
	match current_state:
		AnimState.FADING_IN:
			process_fade_in(delta)
		AnimState.WAITING:
			process_waiting()
		AnimState.FADING_OUT:
			process_fade_out(delta)
		AnimState.DONE:
			pass

# 处理输入事件
func _input(event):
	# 检测是否按下任意键或点击鼠标
	if current_state == AnimState.WAITING and not is_key_pressed:
		# 检测键盘按键
		if event is InputEventKey and event.pressed:
			trigger_fade_out()
			
		# 检测鼠标点击（左键、右键、中键）
		elif event is InputEventMouseButton and event.pressed:
			trigger_fade_out()

# 触发淡出动画
func trigger_fade_out():
	is_key_pressed = true
	current_state = AnimState.FADING_OUT
	current_step = 0
	elapsed_time = 0.0

# 处理淡入动画
func process_fade_in(delta):
	elapsed_time += delta
	
	match current_step:
		0:  # 淡入警告标题
			var alpha = min(1.0, elapsed_time / FADE_DURATION)
			title_label.modulate.a = alpha
			
			if alpha >= 1.0:
				current_step = 1
				elapsed_time = 0.0
		
		1:  # 延迟后淡入警告内容
			if elapsed_time >= STEP_DELAY:
				var fade_time = elapsed_time - STEP_DELAY
				var alpha = min(1.0, fade_time / FADE_DURATION)
				content_label.modulate.a = alpha
				
				if alpha >= 1.0:
					current_step = 2
					elapsed_time = 0.0
		
		2:  # 延迟后淡入按键提示
			if elapsed_time >= STEP_DELAY:
				var fade_time = elapsed_time - STEP_DELAY
				var alpha = min(1.0, fade_time / FADE_DURATION)
				prompt_label.modulate.a = alpha
				
				if alpha >= 1.0:
					current_state = AnimState.WAITING
					elapsed_time = 0.0

# 处理等待状态
func process_waiting():
	# 等待用户按下按键或点击鼠标
	pass

# 处理淡出动画
func process_fade_out(delta):
	elapsed_time += delta
	
	match current_step:
		0:  # 淡出按键提示
			var alpha = max(0.0, 1.0 - elapsed_time / FADE_DURATION)
			prompt_label.modulate.a = alpha
			
			if alpha <= 0.0:
				current_step = 1
				elapsed_time = 0.0
		
		1:  # 延迟后淡出警告内容
			if elapsed_time >= STEP_DELAY:
				var fade_time = elapsed_time - STEP_DELAY
				var alpha = max(0.0, 1.0 - fade_time / FADE_DURATION)
				content_label.modulate.a = alpha
				
				if alpha <= 0.0:
					current_step = 2
					elapsed_time = 0.0
		
		2:  # 延迟后淡出警告标题
			if elapsed_time >= STEP_DELAY:
				var fade_time = elapsed_time - STEP_DELAY
				var alpha = max(0.0, 1.0 - fade_time / FADE_DURATION)
				title_label.modulate.a = alpha
				
				if alpha <= 0.0:
					current_state = AnimState.DONE
					elapsed_time = 0.0
					
					# 发出动画完成信号
					animation_completed.emit() 
