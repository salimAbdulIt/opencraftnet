--стакает в реакторе стержни
--названия компонентов для отладки
--reactor_chamber - когда подключен адаптер с любой стороне реактора(может взаимодествовать со всеми слотами реактора)
--(всего в реактора 54 слота)
--chest - ванильный сундук
--diamond - алмазный сундук
---------------------------
--методы компонентов находятся в скринах

--ЗАГРУЗКА БАЗОВЫХ БИБЛИОТЕК
local computer = require("computer")
local component = require("component")
local term = require("term")
local event = require("event")
--ПРИСВОЕНИЕ ПЕРЕМЕННЫХ КОМПОНЕНТАМ КОМПА
local gpu = component.gpu
--ПЕРЕМЕННЫЕ
local reactor --= component.reactor_chamber (присваивается в безопастном режиме, перед началом работы)
local chest --= component.chest (присваивается в безопастном режиме, перед началом работы)
local redstone --= component.redstone (присваивается в безопастном режиме, перед началом работы)
local sensor --=component.openperipheral_sensor (присваивается в безопастном режиме, при нажатии на кнопку включения сенсора)
local sensor_status = false --статус сенсора, в зависимости от нажатой кнопки, всегда выключен в начале работы(для избежания ошибки, если компонент не подлючен к компу)
local sensor_err = true --ошибка, когда сенсор не найден
local sensor_text_x, sensor_text_y = 110,30 --начальные координаты отображение ников игроков на мониторе
local reactor_core = "" --стержень реатора
local heat_vent = "" --теплоотвод
local reactor_string_config = "" --отображается сверху справа на панеле инфорации "УРАН" или "МОХ"
local status_y_coords = 40 --сдвиг надписи "статус:online/offline" отосительно у координаты
local max_uranium_dmg = 9990 --максимальный дамаг стержня, при котором необходимо его забрать из реактора
local slot_name --проверочная переменная в главном цикле
local parant1, parant2, parant3, parant4 = "parant1", "parant2", "parant3", "parant4"
local chaild1, chaild2, chaild3, chaild4 = "chaild1", "chaild2", "chaild3", "chaild4"
local is_true = true --переменная для бесконечного цикла, отключается касанием мышки по кнопке ВЫХОД
local y_deb_draw = 45 --высота рамки окна дебага(весь тест так же будет подстраиваться под эту высоту)
local logs_level = 0
local first_scroll = true
local start_slot_x_coords, start_slot_y_coords = 4,3 --начальные координаты таблицы слотов(сдвиги по осям х, у)
--СОЗДАНИЕ НЕОБХОДИМЫХ ТАБЛИЦ
local white_list_players = {"thedark1232", "The_Dark1232", "Durex77"} --таблица игроков, которые могут нажимать на кнопки
local heat_vent_slots = {1,3,5,7,9,11,13,15,17,19,21,23,25,27,29,31,33,35,37,39,41,43,45,47,49,51,53} --номера слотов теплоотводов
local uranium_slots = {2,4,6,8,10,12,14,16,18,20,22,24,26,28,30,32,34,36,38,40,42,44,46,48,50,52,54} --номера слотов урановых стержней
local coords_slot_text = {} --таблица координат слотов текста(создается в функции draw_reactor_slots)
local table_logs = {}
local colors_text = {["setWhite"] = function() gpu.setForeground(0xFFFFFF) end,
					 ["setGreen"] = function() gpu.setForeground(0x00FF00) end,
					 ["setRed"] = function() gpu.setForeground(0xFF0000) end,
					 ["setBlack"] = function() gpu.setForeground(0x000000) end,
					 ["setPurple"] = function() gpu.setForeground(0x9900FF) end,
					 ["setYellow"] = function() gpu.setForeground(0xFFCC00) end}
local colors_background = {["setWhite"] = function() gpu.setBackground(0xFFFFFF) end,
					 ["setGreen"] = function() gpu.setBackground(0x00FF00) end,
					 ["setRed"] = function() gpu.setBackground(0xFF0000) end,
					 ["setBlack"] = function() gpu.setBackground(0x000000) end,
					 ["setPurple"] = function() gpu.setBackground(0x9900FF) end,
					 ["setYellow"] = function() gpu.setBackground(0xFFCC00) end}					 
--имена компонентов component.reactor_chamber.getStackInSlot(slot:number).name
	--одиночный стержень урана: reactorUraniumSimple
	--одиночный стержень МОХ: reactorMOXSimple
	--разогнанный теплоотвод: reactorVentGold
	--улучшенный теплоотвод: reactorVentDiamond
--ФУНКЦИИ ПРИСВОЕНИЯ КОМПОНЕНТОВ ПЕРЕМЕННЫМ
--реактор
function check_reactor_chamber() reactor = component.reactor_chamber end
--ванильный сундук в 1 блок
function check_chest() chest = component.chest end
--плата ред стоуна
function check_redstone() redstone = component.redstone end
--сесор из периферии
function check_sensor() sensor = component.openperipheral_sensor end
--ФУНКЦИИ
--рисование контура главного окна. Символы рисования = ▀ █ ▄
function draw_main_screen(color_name_background, color_name_foreground)
	if color_name_background == nil or color_name_foreground == nil then colors_text:setRed(); term.clear(); deb_enter_print("один из аргументов функции draw_main_screen равен nil"); colors_text:setWhite(); os.exit() end
	local color_f = "set" ..color_name_foreground
	local color_b = "set" ..color_name_background
	if colors_text[color_f] == nil then colors_text:setRed(); deb_enter_print("цвет для рамки: " ..color_f.. " отсутствует в таблице цветов"); colors_text:setWhite(); os.exit() end
	if colors_background[color_b] == nil then colors_text:setRed(); deb_enter_print("цвет для заднего фона: " ..color_b.. " отсутствует в таблице цветов"); colors_text:setWhite(); os.exit() end
	colors_text[color_f]()
	colors_background[color_b]()
	local x_screen, y_screen, y_len_down = 2,2,46
    gpu.set(x_screen,y_screen, "█▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀█")
	for i = 1,y_len_down do 
		gpu.set(x_screen,y_screen+i,"█ 	                                                                             																																						  █")
	end
    gpu.set(x_screen,y_screen + y_len_down + 1,"█▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄█")
	print_deb_message("рисование основной рамки")
	draw_debug_window(color_b, color_f, x_screen) --нарисовать окно дебага
	colors_text:setWhite()
	colors_background:setBlack()	
end
--функция расположения слотов ядерного реактора на мониторе с 6 реакторными камерами(всего 54 слота, всего слотов по горизонтальной оси в ряду: 9, всего слотов по вертиральной оси в одной колонке: 6)
function draw_reactor_slots(start_x_coords, start_y_coords)
	print_deb_message("рисование слотов реактора")
	local max_x_length, max_y_lenght
	local it_is_heat_sink = true
	local sycle = 0 --присвоение номеров слотов таблице слотов реактора
	max_x_length = start_x_coords + 11 * 8
	max_y_lenght = start_y_coords + 6 * 5
	local step_right = 11 --шаг сдвига слотов реактора вправо
	local sterp_down = 6 --шаг сдвига слотов реактора вниз
	for g = start_y_coords, max_y_lenght, sterp_down do
		for i = start_x_coords, max_x_length, step_right do
			sycle = sycle + 1
			coords_slot_text[sycle] = {x = i, y = g}
			draw_one_slot(i, g, it_is_heat_sink)
			if it_is_heat_sink then it_is_heat_sink = false else it_is_heat_sink = true end
		end
	end
end
--запись параметров в слоты(дамаг, присутствие компонентов и т.д
--аргументы(номер_слота, пустой_ли_слот, [не обязательный параметр дамага])
function write_slots_params(slot_number, is_empty, dmg)
	local x_pos,y_pos = 6, 2 --смещение координат текста
	if dmg ~= nil then
		if #dmg ~= 0 then
			for i = 1,4 - #dmg do dmg = dmg .. " " end
		end
	end
	if is_empty then
		colors_text:setRed()
		gpu.set(coords_slot_text[slot_number].x + x_pos, coords_slot_text[slot_number].y + y_pos, "----")
		gpu.set(coords_slot_text[slot_number].x + x_pos - 3, coords_slot_text[slot_number].y + y_pos + 2, "EMPTY")
		colors_text:setWhite()
	else
		gpu.set(coords_slot_text[slot_number].x + x_pos, coords_slot_text[slot_number].y + y_pos, dmg)
		gpu.set(coords_slot_text[slot_number].x + x_pos - 3, coords_slot_text[slot_number].y + y_pos + 2, "     ")
	end
end
--рисование 1 слота реактора(аргументы: начальная позиция рисования по х,у, последний аргумент с булевых значением, если true, значит это теплоотвод)
function draw_one_slot(start_x, start_y, it_is_heat_sink)
	local end_slot_y_coords = 5
	--таблица теплоотводов
	local table_heat_sink = {"т/отвод", "dmg: "}
	--таблица стержней реактора
	local table_uranium_core = {"стержень", "dmg: "}
	gpu.set(start_x, start_y, "█▀▀▀▀▀▀▀▀▀▀█")
	for down = 1, end_slot_y_coords - 1 do
		gpu.set(start_x, start_y + down, "█          █")
	end
	gpu.set(start_x, start_y + end_slot_y_coords, "█▄▄▄▄▄▄▄▄▄▄█")
	if it_is_heat_sink then
		for k,v in ipairs(table_heat_sink) do
			gpu.set(start_x + 2, start_y + k, v)
		end
	else
		for k,v in ipairs(table_uranium_core) do
			gpu.set(start_x + 2, start_y + k, v)
		end
	end
end
--перерисовка рамки 1 слота реактора другим цветом(аргументы: номер слота, цвет_рамки)
function draw_one_slot_frame(slot_number, color_frame)
	local end_slot_y_coords = 5
	local slot_number_str = tostring(slot_number)
	if #slot_number_str < 2 then slot_number_str = "0" ..slot_number_str end
	colors_text[color_frame]()
	local x = coords_slot_text[slot_number].x
	local y = coords_slot_text[slot_number].y
	gpu.set(x, y, "█▀слот: " ..slot_number_str.. "▀█")
	for down = 1, end_slot_y_coords - 1 do
		gpu.set(x, y + down, "█  ОШИБКА  █")
	end
	gpu.set(x, y + end_slot_y_coords, "█▄▄▄▄▄▄▄▄▄▄█")
	colors_text:setWhite()
end
--нарисовать окно дебага(аргументы: ключи таблицы colors_text, пример: "setYellow", последний аргумент, смещение по координате х)
function draw_debug_window(color_name_background, color_name_foreground, x_coord)
	print_deb_message("рисование окна дебага")
	local y_coord = y_deb_draw --на сколько опустить рамку вниз от верха экрана
	colors_text[color_name_foreground]()
	colors_background[color_name_background]()
	gpu.set(x_coord + 1, y_coord, "▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀ ОКНО ОТЛАДКИ ▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀█")
	for i = 48,y_coord + 1,-1 do gpu.set(x_coord + 1,i,"                                                                                                         █") end
	gpu.set(x_coord + 106, 49, "█")
end
--выводит print() дебага с последующем подтверждением кнопкой enter
function deb_enter_print(what_text)
	if what_text == nil then what_text = "имеет значение nil" end
	print(what_text)
	print("жми ентер для продолжения")
	local lol_enter = io.read()
end
--функция для дебага, ожидание 10 секунд с выводом времени на экран = все через функцию print()
function deb_print(print_text)
	print(print_text)
	print("ОСТАЛОСЬ ВРЕМЕНИ:")
	for i = 10, 1, -1 do
		print(i)
		os.sleep(1)
	end
end
--печатает в окно отладки сообщение из аргумента, второй и третий аргументы не обязательны, они нужны для фукнции скрола сообщений дебага
--если требуется нажатие enter пользователем, 2 аргумент должен быть true
function print_deb_message(message_name, need_push_enter, is_scroll)
	if not is_scroll then table_logs[#table_logs + 1] = message_name end
	local log1, log2, log3
	local table_line = {[1] = {}, [2] = {}, [3] = {}}
	for i = 1,3 do
		for g = 1,101 do
			table_line[i][#table_line[i] + 1] = gpu.get(3 + g, y_deb_draw + i)
		end
	end
	log1 = table.concat(table_line[1])
	log2 = table.concat(table_line[2])
	log3 = table.concat(table_line[3])
	if table_line[1][1] == " " then
		gpu.set(4, y_deb_draw + 1, message_name)
	elseif table_line[2][1] == " " then
		gpu.set(4, y_deb_draw + 2, message_name)
	elseif table_line[3][1] == " " then
		gpu.set(4, y_deb_draw + 3, message_name)
	else
		clear_debug_window(1,3)
		gpu.set(4, y_deb_draw + 1, log2)
		gpu.set(4, y_deb_draw + 2, log3)
		gpu.set(4, y_deb_draw + 3, message_name)
	end
	if need_push_enter then
		colors_text:setRed()
		gpu.set(4, y_deb_draw - 1, "ЖМИ ЕНТЕР")
		colors_text:setWhite()
		local ent = io.read()
		gpu.set(4, y_deb_draw - 1, "         ")
	end
	table_line = nil
end
--очистка окна дебага(аргументы с какой по какую линию чистить) = всего линий 3
function clear_debug_window(first_w, next_w)
	for i = first_w,next_w do gpu.set(4,y_deb_draw + i,"                                                                                                        ") end
end
--функция обрабатывает касание по экрану игроком(аргумент1: touch, аргумент2: адрес, аргумент3: координата_х, аргумент4: координата_у, аргумент5: хз че, аргумент6: ник. кто нажал на кнопку
function touch_event_listener(arg1, arg2, arg3, arg4, arg5, arg6)
	local access = false --доступ к кнопкам, после нажатия(список игроков, которые могут нажимать на кнопки записаны в таблице white_list_players)
	print_deb_message("аргумент по х " ..arg3.. "   аргумент по y = " ..arg4)
	for _,v in ipairs(white_list_players) do
		if arg6 == v then access = true end
	end
	if arg1 == "touch" and access then
		if arg3 > 148 and arg3 < 158 and arg4 > 45 and arg4 < 49 then --кнопка exit
			is_true = false
			return
		elseif arg3 > 137 and arg3 < 148 and arg4 > 3 and arg4 < 7 then --кнопка включения реактора
			draw_online()
			return
		elseif arg3 > 147 and arg3 < 158 and arg4 > 3 and arg4 < 7 then --кнопка выключения реактора
			draw_offline()
			return
		elseif arg3 > 137 and arg3 < 148 and arg4 > 7 and arg4 < 11 then --кнопка включения сенсора
			set_sensor_status(true)
			draw_sensor_frame(true)
			done_load,_ = pcall(check_sensor)
			if not done_load then computer.beep(1000,0.1); computer.beep(1000, 0.1); computer.beep(1000, 0.1); colors_text:setRed(); gpu.set(110, 31, "СЕНСОР НЕ НАЙДЕН"); gpu.set(110, 32, "подключи сенсор к адаптеру"); colors_text:setWhite(); return end
			sensor_err = false
			return
		elseif arg3 > 147 and arg3 < 158 and arg4 > 7 and arg4 < 11 then --кнопка выключения сенсора
			set_sensor_status(false)
			draw_sensor_frame(false)
			sensor_err = true
			clear_sensor_window()
			return
		end
	end
end
--чекнуть игроков рядом с сенсором и записать их на экран
function check_players_near()
	--максимальная длина поля отображения имени игрока (26 символов)
	local players_count = #sensor.getPlayers()
	local max_y_coords = 18
	local player_name
	local space_count
	for i = 1, players_count do
		player_name = sensor.getPlayers()[i].name
		space_count = 26 - 6 - #player_name
		for spaces = 1,space_count do player_name = player_name .. " " end --вставить поле имени игрока символы пробела
		gpu.set(sensor_text_x, sensor_text_y + i, "[" ..i.. "] = " ..player_name)
	end
	for g = players_count + 1, max_y_coords do gpu.set(sensor_text_x, sensor_text_y + g, "                          ") end
end 
--рисование кнопок на экране
function draw_buttons()
	--аргументы(начало по х, начало по у, ширина, длина, текст_кнопки, цвет_кнопки, цвет_текста, цвет_рамки)
	print_deb_message("рисование кнопок")
	gpu.set(140,3,"вкл/выкл реактор:")
	gpu.set(140,7,"вкл/выкл сенсора:")
	draw_button(138,4,10,3,"on", "setGreen", "setBlack", "setPurple") --кнопка включения реактора
	draw_button(148,4,10,3,"off", "setRed", "setWhite", "setPurple")  --кнопка выключаения реактора
	draw_button(138,8,10,3,"on", "setGreen", "setBlack", "setPurple") --кнопка включения сенсора
	draw_button(148,8,10,3,"off", "setRed", "setWhite", "setPurple")  --кнопка выключаения сенсора
	draw_button(148,46,10,3,"exit", "setRed", "setWhite", "setPurple") --кнопка выхода из программы
end
--функция рисует кнопки - width(ширина) height(длина)
function draw_button(start_x, start_y, width, height, button_text, color_button, color_text, color_frame)
local height_text, left_text
	height_text = math.floor(height / 2) --расчет высоты текста в кнопке
	left_text = math.floor(width / 2) --выравнивание текста кнопки по левому краю
	colors_text[color_text]()
	colors_background[color_button]()
	gpu.fill(start_x, start_y, width, height, ' ')
	left_text = math.floor(left_text - #button_text / 2)
	if left_text <= 0 then left_text = 1 end
	gpu.set(start_x + left_text, start_y + height_text, button_text)
	colors_text[color_frame]()
	--зарисовка вертикальных рамок кнопки
	for up_down_frame = start_x + 1, start_x + width - 2 do
		gpu.set(up_down_frame, start_y, "▀") 
		gpu.set(up_down_frame, start_y + height - 1, "▄")
	end
	--зарисовка горизонтальных рамок кнопки
	for left_right_frame = start_y, start_y + height - 1 do
		gpu.set(start_x, left_right_frame, "█")
		gpu.set(start_x + width - 1, left_right_frame, "█")
	end
	colors_text:setWhite()
	colors_background:setBlack()
end
--функция включается при скроле мышкой
-- scroll(screenAddress: string, x: number, y: number, direction: number, playerName: string)
function scroll_function(_,screenAgress, x_pos, y_pos, direction, playerName)
	if direction < 0 then direction = 1 else direction = -1 end
	if x_pos > 3 and x_pos < 108 and y_pos > 45 and y_pos < 49 then
		if first_scroll then
			logs_level = #table_logs
			first_scroll = false
		end
		logs_level = math.floor(logs_level + direction)
		if logs_level < 3 then logs_level = 3 end
		if logs_level > #table_logs then logs_level = #table_logs end
		print_deb_message(table_logs[logs_level - 2], false, true)
		print_deb_message(table_logs[logs_level - 1], false, true)
		print_deb_message(table_logs[logs_level], false, true)
	end
end
--затолкать стержни из сундука в пустой слот реактора
function get_new_uranium_core()
	local slot_chest_params
	for i = 1,27 do
		slot_chest_params = chest.getStackInSlot(i)
		if slot_chest_params ~= nil then
			if slot_chest_params.name == reactor_core and slot_chest_params.dmg <= max_uranium_dmg then
				chest.pushItem("DOWN", i, 64)
				chest.pushItem("DOWN", i, 64)
			end
		end
	end
end
--сравнение номер слота, если в этом слоте должен находится реактор, попытаться вытолкать его из сундука(аргумент: слот для сравнения)
function try_push_uranium_core_from_chest(slot_comparison)
	for _,v in ipairs(uranium_slots) do
		if slot_comparison == v then
			get_new_uranium_core()
			return false
		end
	end
	return true --если возвращает true, значит в этом слоте должен быть теплоотвод
end
--сравнивает номер слота, в котором должен находится теплоотвеод, если его там нет, функция зацикливается
function check_status_heat_vent(slot_comparison)
	draw_offline()
	colors_text:setRed()
	print_deb_message("КРИТИЧЕСКАЯ ОШИБКА:")
	print_deb_message("ОТСУСТВУЕТ ТЕПЛООТВОД В СЛОТЕ: " ..slot_comparison)
	colors_text:setWhite()
	::again::
	while reactor.getStackInSlot(slot_comparison) == nil do
		computer.beep(1000,1)
		draw_one_slot_frame(slot_comparison, "setRed")
		os.sleep(1)
		draw_one_slot_frame(slot_comparison, "setYellow")
	end
	if reactor.getStackInSlot(slot_comparison).name ~= heat_vent then computer.beep(1000,1); goto again end
	local x = coords_slot_text[slot_comparison].x
	local y = coords_slot_text[slot_comparison].y
	draw_one_slot(x,y,true)
	draw_online()
end
--нарисовать "СТАТУС"
function draw_status()
	print_deb_message("рисование надписи \"СТАТУС\"")
	local x,y = 10, status_y_coords
    gpu.set(x,y,  "▄▄▄▄▄")
    gpu.set(x,y+1,"█▄▄▄▄")
    gpu.set(x,y+2,"▄▄▄▄█")
	gpu.set(x+6,y,  "▄▄▄▄▄")
    gpu.set(x+6,y+1,"  █")
    gpu.set(x+6,y+2,"  █")
	gpu.set(x+12,y,  "▄▄▄▄▄")
    gpu.set(x+12,y+1,"█▄▄▄█")
    gpu.set(x+12,y+2,"█   █")
	gpu.set(x+18,y,  "▄▄▄▄▄")
    gpu.set(x+18,y+1,"  █")
    gpu.set(x+18,y+2,"  █")
	gpu.set(x+24,y,  "▄   ▄")
    gpu.set(x+24,y+1,"█   █")
    gpu.set(x+24,y+2,"▀▄▄▄▀")
	gpu.set(x + 30,y,  "▄▄▄▄▄")
    gpu.set(x + 30,y+1,"█▄▄▄▄")
    gpu.set(x + 30,y+2,"▄▄▄▄█")
	gpu.set(x+36,y,  " ")
    gpu.set(x+36,y+1,"▀")
    gpu.set(x+36,y+2,"▀")
end
--нарисовать "ONLINE"
function draw_online()
	redstone.setOutput(2,15) --подать сингал ред стоуна на реактор
	local x,y = 48, status_y_coords
	colors_text:setGreen()
	gpu.set(x,y,  "▄▄▄▄▄")
    gpu.set(x,y+1,"█   █")
    gpu.set(x,y+2,"█▄▄▄█")
	gpu.set(x+6,y,  "▄▄  ▄")
    gpu.set(x+6,y+1,"█ █ █")
    gpu.set(x+6,y+2,"█  ▀█")
	gpu.set(x+12,y,  "▄    ")
    gpu.set(x+12,y+1,"█   ")
    gpu.set(x+12,y+2,"█▄▄▄")
	gpu.set(x+17,y,  "▄▄▄")
    gpu.set(x+17,y+1," █")
    gpu.set(x+17,y+2,"▄█▄ ")
	gpu.set(x+21,y,  "▄▄  ▄")
    gpu.set(x+21,y+1,"█ █ █")
    gpu.set(x+21,y+2,"█  ▀█")
	gpu.set(x+27,y,  "▄▄▄▄▄       ")
    gpu.set(x+27,y+1,"█▄▄▄        ")
    gpu.set(x+27,y+2,"█▄▄▄▄       ")
	colors_text:setWhite()
end
--нарисовать "OFFLINE"
function draw_offline()
	redstone.setOutput(2,0) --отключить сигнал ред стоуна на реактор
	local x,y = 48, status_y_coords
	colors_text:setRed()
	gpu.set(x,y,  "▄▄▄▄▄")
    gpu.set(x,y+1,"█   █")
    gpu.set(x,y+2,"█▄▄▄█")
	gpu.set(x+6,y,  "▄▄▄▄▄ ")
    gpu.set(x+6,y+1,"█▄▄   ")
    gpu.set(x+6,y+2,"█     ")
	gpu.set(x+12,y,  "▄▄▄▄▄ ")
    gpu.set(x+12,y+1,"█▄▄   ")
    gpu.set(x+12,y+2,"█     ")
	gpu.set(x+18,y,  "▄    ")
    gpu.set(x+18,y+1,"█   ")
    gpu.set(x+18,y+2,"█▄▄▄")
	gpu.set(x+23,y,  "▄▄▄")
    gpu.set(x+23,y+1," █  ")
    gpu.set(x+23,y+2,"▄█▄")
	gpu.set(x+27,y,  "▄▄  ▄")
    gpu.set(x+27,y+1,"█ █ █")
    gpu.set(x+27,y+2,"█  ▀█")
	gpu.set(x+34,y,  "▄▄▄▄▄")
    gpu.set(x+34,y+1,"█▄▄▄")
    gpu.set(x+34,y+2,"█▄▄▄▄")
	colors_text:setWhite()
end
--просвоение статуса сенсору(аргумент: true = включен, false = выключен)
function set_sensor_status(is_on)
	if is_on then colors_text:setGreen(); sensor_status = true; gpu.set(121, 4, "Вкл ") else colors_text:setRed(); sensor_status = false; gpu.set(121, 4, "Выкл") end
	colors_text:setWhite()
end
--нирисовать(убрать) рамку сенсора(если аргумент false, закрашивает рамку черным цветом(чтобы очистить окно от рамки))
function draw_sensor_frame(is_on)
	if is_on then colors_text:setYellow() else colors_text:setBlack() end
	local x_position, y_position = 108, 30
	
	gpu.set(x_position, y_position, "█▀ ИГРОКИ РЯДОМ С РЕАТОРОМ ▀█")
	for i = 1,18 do gpu.set(x_position,y_position + i,"█                           █") end
	gpu.set(x_position, y_position + 19, "█▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄█")
	if not is_on then
		colors_text:setYellow()
		for g = 18,15,-1 do gpu.set(x_position, y_position + g, "█") end
		gpu.set(x_position, y_position + 19, "█▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄")
	end
	colors_text:setWhite()
end
--ИВЕНТЫ
event.listen("touch", touch_event_listener)
event.listen("scroll", scroll_function)
--НАЧАЛО ПРОЦЕДУРЫ
do
	--проверки наличия компонентов для корретной работы программы
	term.clear()
	print("ПЕРВОНАЧАЛЬНЫЕ ПРОВЕРКИ НАЛИЧИЯ ВСЕХ КОМПОНЕНТОВ")
	done_load,_ = pcall(check_reactor_chamber)
	if not done_load then computer.beep(1000,0.1); computer.beep(1000, 0.1); computer.beep(1000, 0.1); colors_text:setRed(); print("компонент \"реактор\" не найден"); print("подключи адаптер к реактору"); print("программа завершена"); colors_text:setWhite(); event.ignore("touch", touch_event_listener); event.ignore("scroll", scroll_function); os.exit() end
	done_load,_ = pcall(check_chest)
	if not done_load then computer.beep(1000,0.1); computer.beep(1000, 0.1); computer.beep(1000, 0.1); colors_text:setRed(); print("компонент \"ванильный сундук\" не найден"); print("подключи адаптер к сундуку"); print("программа завершена"); colors_text:setWhite(); event.ignore("touch", touch_event_listener); event.ignore("scroll", scroll_function); os.exit() end
	done_load,_ = pcall(check_redstone)
	if not done_load then computer.beep(1000,0.1); computer.beep(1000, 0.1); computer.beep(1000, 0.1); colors_text:setRed(); print("компонент \"плата ред стоуна\" не найден"); print("подключи плату в компе"); print("программа завершена"); colors_text:setWhite(); event.ignore("touch", touch_event_listener); event.ignore("scroll", scroll_function); os.exit() end
	colors_text:setGreen(); print("все компоненты найдены")
	--назначение переменных, в зависимости от типа реатора(ОБЫЧНЫЙ ИЛИ МОХ)
	if reactor.getStackInSlot(1) == nil then
		computer.beep(1000,0.1); computer.beep(1000, 0.1); computer.beep(1000, 0.1); colors_text:setRed(); print("не могу определить тип реактора"); print("проверь конфигурацию теплоотводов"); print("программа завершена"); colors_text:setWhite(); event.ignore("touch", touch_event_listener); event.ignore("scroll", scroll_function); os.exit()
	elseif reactor.getStackInSlot(1).name == "reactorVentGold" then
		reactor_core = "reactorUraniumSimple"
		heat_vent = "reactorVentGold"
		reactor_string_config = "УРАН"
	elseif reactor.getStackInSlot(1).name == "reactorVentDiamond" then
		reactor_core = "reactorMOXSimple"
		heat_vent = "reactorVentDiamond"
		reactor_string_config = "МОХ"
	end
	term.clear()
	--нарисовать стартовый экран
	print_deb_message("ПОДГОТОВКА ПРОГРАММЫ")
	draw_main_screen("Black","Yellow") --нарисовать рамку экрана(цвет_заднего_фона, цвет_самой_рамки): цвета писать с большой буквы
	draw_buttons()
	draw_reactor_slots(start_slot_x_coords, start_slot_y_coords) --глобальные переменные в аргументах
	draw_status()
	redstone.setOutput(2,0) --предварительное выключение сигнала ред стоуна реактору(на всякий случай)
	draw_offline()
	gpu.set(105,3,"реактор сконфигурирован:")
	gpu.set(105,4,"статус сенсора:")
	set_sensor_status(sensor_status) --false
	colors_text:setGreen(); gpu.set(130,3, reactor_string_config); colors_text:setWhite()
	print_deb_message("----------------------")
	print_deb_message("программа готова к работе")
	--ГЛАВНЫЙ ЦИКЛ
	while is_true do --is_true отключается в фунции touch_event_listener через нажатие кнопки exit
		for i = 1,54 do
			slot_params = reactor.getStackInSlot(i)
			if slot_params == nil then
				write_slots_params(i, true)
				if try_push_uranium_core_from_chest(i) then check_status_heat_vent(i) end--попробвать вытолкать стержень из сундука(если совпадет слот с таблицей слотов стержней)
			elseif slot_params.name == heat_vent then
				write_slots_params(i, false, tostring(slot_params.dmg))
			elseif slot_params.name == reactor_core then
				write_slots_params(i, false, tostring(slot_params.dmg))
				if slot_params.dmg > max_uranium_dmg then reactor.pushItem("UP",i,64); get_new_uranium_core() end --если dmg стержня больше (2), вытолкать его в верхний сундук и затолкать новые
			end
		end
		if sensor_status and sensor_err == false then pcall(check_players_near) end	--отобрать игроков на мониторе
		os.sleep(1)
	end
	term.clear()
	redstone.setOutput(2,0) --выключение сигнала редстоуна при выходе из программы
	--не забыть записывать игнор эвентов в pcall функции первоначальных проверок компонентов
	event.ignore("touch", touch_event_listener)
	event.ignore("scroll", scroll_function)
end