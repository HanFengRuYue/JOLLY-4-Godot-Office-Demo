extends Node

# 存档文件路径
const SAVE_FILE_PATH = "user://Jolly4Demo_save.dat"

# 游戏数据
var game_data = {
	"has_completed_sound_test": false,  # 玩家是否完成过声音测试
}

# 在游戏启动时初始化存档系统
func _ready():
	load_game()  # 尝试加载现有存档

# 保存游戏数据
func save_game() -> void:
	var save_file = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	if save_file == null:
		printerr("无法创建存档文件！错误代码: ", FileAccess.get_open_error())
		return
	
	# 将游戏数据转换为JSON字符串
	var json_string = JSON.stringify(game_data)
	
	# 将JSON字符串写入文件
	save_file.store_string(json_string)
	
	# 关闭文件
	save_file = null
	
	print("游戏数据已保存")

# 加载游戏数据
func load_game() -> void:
	# 检查存档文件是否存在
	if not FileAccess.file_exists(SAVE_FILE_PATH):
		print("没有找到存档文件，使用默认数据")
		return
	
	# 打开存档文件
	var save_file = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
	if save_file == null:
		printerr("无法打开存档文件！错误代码: ", FileAccess.get_open_error())
		return
	
	# 读取JSON字符串
	var json_string = save_file.get_as_text()
	
	# 关闭文件
	save_file = null
	
	# 解析JSON字符串
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	if parse_result == OK:
		var parsed_data = json.data
		if typeof(parsed_data) == TYPE_DICTIONARY:
			# 更新游戏数据
			for key in parsed_data:
				if game_data.has(key):
					game_data[key] = parsed_data[key]
			print("游戏数据已加载")
		else:
			printerr("解析的数据不是字典类型")
	else:
		printerr("解析JSON时出错: ", json.get_error_message(), " at line ", json.get_error_line())

# 设置声音测试完成状态
func set_sound_test_completed(completed: bool) -> void:
	game_data["has_completed_sound_test"] = completed
	save_game()  # 立即保存变更

# 检查玩家是否完成过声音测试
func has_completed_sound_test() -> bool:
	return game_data["has_completed_sound_test"]

# 重置所有游戏数据（用于测试或重新开始游戏）
func reset_game_data() -> void:
	game_data = {
		"has_completed_sound_test": false,
	}
	save_game()
	print("游戏数据已重置") 
