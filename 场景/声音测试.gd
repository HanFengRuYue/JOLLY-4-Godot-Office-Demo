extends Control

# 预加载资源
@onready var circle_texture = preload("res://贴图/声音测试/圆圈贴图.png")
@onready var label_L = $L
@onready var label_R = $R
@onready var audio_player = $"测试音效"  # 使用场景中已有的测试音效节点
@onready var bus_layout = preload("res://场景/声音测试.tres")  # 预加载音频总线布局
@onready var complete_button = $"完成按钮"  # 获取完成按钮引用

# 圆圈参数
var circle_containers = []  # 存储当前所有圆圈的容器
var is_animating = false
var current_position = "L"  # 当前应该在哪个位置显示圆圈
var circles_to_create = 0   # 剩余需要创建的圆圈数量
var circle_creation_timer = 0.0  # 创建圆圈的计时器

# 动画参数
const START_SCALE = 0.6
const MAX_SCALE = 6.0
const ANIMATION_DURATION = 3.0  # 动画持续时间（秒）
const CIRCLE_CREATION_INTERVAL = 0.4  # 圆圈创建间隔（秒）
const CIRCLES_PER_SIDE = 3  # 每边创建的圆圈数量

# 音频参数
const LEFT_PAN = -1.0  # 完全左声道
const RIGHT_PAN = 1.0  # 完全右声道

# 用于存储音频效果的引用
var panner_effect = null
var effect_index = -1
var master_bus_index = -1

func _ready():
	# 检查玩家是否已经完成过声音测试
	if SaveSystem.has_completed_sound_test():
		# 如果已完成，延迟切换到警告场景，避免节点操作冲突
		print("玩家已完成声音测试，准备跳转到警告场景")
		call_deferred("change_to_warning_scene")
		return
	
	print("首次进入声音测试场景")
	
	# 等待一帧以确保UI已经正确布局
	await get_tree().process_frame
	
	# 设置音频效果
	setup_audio_effects()
	
	# 初始化标签显示状态
	update_labels_visibility()
	
	# 在游戏开始时生成第一组圆圈
	start_circle_creation(label_L)
	
	# 连接完成按钮的点击信号
	complete_button.pressed.connect(_on_complete_button_pressed)

# 延迟切换到警告场景的方法
func change_to_warning_scene():
	get_tree().change_scene_to_file("res://场景/警告.tscn")

func setup_audio_effects():
	# 获取Master总线索引
	master_bus_index = AudioServer.get_bus_index("Master")
	
	# 查找已有的Panner效果
	for i in range(AudioServer.get_bus_effect_count(master_bus_index)):
		var effect = AudioServer.get_bus_effect(master_bus_index, i)
		if effect is AudioEffectPanner:
			panner_effect = effect
			effect_index = i
			break
	
	# 如果没有找到Panner效果，则添加一个
	if panner_effect == null:
		panner_effect = AudioEffectPanner.new()
		effect_index = AudioServer.get_bus_effect_count(master_bus_index)
		AudioServer.add_bus_effect(master_bus_index, panner_effect)
	
	# 启用效果
	AudioServer.set_bus_effect_enabled(master_bus_index, effect_index, true)

func _process(delta):
	# 处理圆圈创建
	if circles_to_create > 0:
		circle_creation_timer += delta
		if circle_creation_timer >= CIRCLE_CREATION_INTERVAL:
			circle_creation_timer = 0.0
			create_circle_at_label(label_L if current_position == "L" else label_R, false)  # 传入false表示这不是第一个圆圈
			circles_to_create -= 1
	
	# 处理圆圈动画
	var circles_completed = []
	
	for i in range(circle_containers.size()):
		var container = circle_containers[i]
		var circle = container.get_child(0) if container.get_child_count() > 0 else null
		
		if circle != null:
			# 更新动画时间
			container.set_meta("animation_time", container.get_meta("animation_time") + delta)
			var progress = container.get_meta("animation_time") / ANIMATION_DURATION
			
			if progress <= 1.0:
				# 计算当前缩放和透明度
				var current_scale = lerp(START_SCALE, MAX_SCALE, progress)
				var current_alpha = lerp(1.0, 0.0, progress)
				
				# 应用缩放和透明度
				circle.scale = Vector2(current_scale, current_scale)
				circle.modulate.a = current_alpha
			else:
				# 动画完成，标记为清理
				circles_completed.append(container)
	
	# 清理完成的圆圈
	for container in circles_completed:
		circle_containers.erase(container)
		container.queue_free()
	
	# 如果所有圆圈都完成了，且没有新的圆圈要创建，切换到另一边
	if circle_containers.is_empty() and circles_to_create == 0 and is_animating:
		is_animating = false
		
		# 切换到另一个标签位置
		if current_position == "L":
			current_position = "R"
		else:
			current_position = "L"
			
		# 更新标签可见性
		update_labels_visibility()
		
		# 开始创建新一组圆圈
		start_circle_creation(label_L if current_position == "L" else label_R)

func update_labels_visibility():
	# 基于当前位置更新标签可见性
	label_L.visible = (current_position == "L")
	label_R.visible = (current_position == "R")

func start_circle_creation(label_node):
	circles_to_create = CIRCLES_PER_SIDE - 1  # 减1是因为我们马上就要创建第一个圆圈
	circle_creation_timer = 0.0
	is_animating = true
	create_circle_at_label(label_node, true)  # 传入true表示这是第一个圆圈

func create_circle_at_label(label_node, is_first_circle = false):
	# 创建一个新的容器来承载圆圈
	var container = Control.new()
	add_child(container)
	
	# 创建一个新的TextureRect节点作为圆圈
	var circle = TextureRect.new()
	circle.texture = circle_texture
	
	# 设置圆圈的初始属性
	circle.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	circle.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	circle.pivot_offset = Vector2(50, 50)  # 设置旋转/缩放的中心点
	circle.custom_minimum_size = Vector2(100, 100)
	circle.scale = Vector2(START_SCALE, START_SCALE)  # 初始缩放
	
	# 获取标签的中心位置
	var label_rect = label_node.get_global_rect()
	var label_center = Vector2(
		label_rect.position.x + label_rect.size.x / 2,
		label_rect.position.y + label_rect.size.y / 2
	)
	
	# 设置容器位置，并添加圆圈
	container.global_position = label_center - Vector2(50, 50)  # 考虑圆圈大小的一半进行偏移
	container.add_child(circle)
	
	# 使用元数据存储动画时间
	container.set_meta("animation_time", 0.0)
	
	# 将容器添加到列表
	circle_containers.append(container)
	
	# 只有在是第一个圆圈时才播放音效
	if is_first_circle:
		play_sound_effect()

func play_sound_effect():
	# 确保音频播放器和Panner效果存在
	if audio_player and panner_effect and effect_index >= 0:
		# 根据当前位置设置Panner效果的平衡
		if current_position == "L":
			# 左声道播放
			panner_effect.pan = LEFT_PAN  # 设置为左声道
		else:
			# 右声道播放
			panner_effect.pan = RIGHT_PAN  # 设置为右声道
		
		# 确保使用Master总线（带有我们的Panner效果）
		audio_player.bus = "Master"
			
		# 播放音效
		audio_player.play()

# 完成按钮点击处理函数
func _on_complete_button_pressed():
	# 记录玩家已完成声音测试
	SaveSystem.set_sound_test_completed(true)
	
	# 切换到警告场景
	get_tree().change_scene_to_file("res://场景/警告.tscn") 
