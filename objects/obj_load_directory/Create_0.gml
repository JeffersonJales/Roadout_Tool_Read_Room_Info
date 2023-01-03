/// @description 

global.roadout_gamefile_yyp = get_open_filename("*.yyp", "");

if(global.roadout_gamefile_yyp == "") { game_end(); exit }

global.roadout_filepath			= filename_path(global.roadout_gamefile_yyp);
global.roadout_gamedir			= filename_dir(global.roadout_gamefile_yyp);
global.roadout_buffer_yyp		= buffer_load(global.roadout_gamefile_yyp);
global.roadout_strunct_yyp	= buffer_read(global.roadout_buffer_yyp, buffer_string);
global.roadout_strunct_yyp	= json_parse(global.roadout_strunct_yyp);

global.roadout_box_amount_total = 0;
global.roadout_box_amount_per_dungeon = {};


global.special_char = "\\";
global.room_counter = 0;
global.room_amount = array_length(global.roadout_strunct_yyp.RoomOrderNodes)
alarm[0] = 5;

get_dungeon_key = function(room_name){
	var _rm_name = room_name;
	room_name = string_replace(room_name, "RoomStage_", "");
	var first_letter = string_char_at(room_name, 1);
	try{
		var is_number = real(first_letter);
	}
	catch(err){
		if(first_letter == "L") {
			room_name = string_replace(room_name, "L_", "");
		}
		
		else if (first_letter == "F"){
			try {
				var is_number = real(string_char_at(room_name, 3));
				room_name = string_replace(room_name, "F_", "");
			}
			catch(err_2){
				room_name = string_delete(room_name, 1, 9);
			}
		}
		else 
			throw err;
	}
	
	room_name = string_copy(room_name, 1, string_pos("_", room_name) - 1);
	
	var _key = "Dungeon_" + room_name;
	
	if(!variable_struct_exists(global.roadout_box_amount_per_dungeon, _key)){
		global.roadout_box_amount_per_dungeon[$ _key] = { 
			Dungeon_Leader : "AI",
			Boxes : {
				Box_AI : 0, 
				Box_Bio : 0, 
				Box_Cyber : 0, 
				Box_Diesel : 0, 
			},
			Enemies : {
				AI : {},
				Bio : {},
				Cyber : {},
				Diesel : {},
			},
			Rooms : {
				TotalRooms : 0,
				RoomWithEnemyAI : 0, RoomWithEnemyBio : 0, RoomWithEnemyCyber : 0, RoomWithEnemyDiesel : 0,
			},
			EnemiesByRoom : {},
		};	 

	}
	return _key;	
}

check_is_box_layer = function(layer_name){
	switch(layer_name){
		case "Box_AI":				
		case "Box_Bio":				
		case "Box_Cyber":			
		case "Box_Diesel":		
			return true;
		
		default: 
			return false;
	}
	return false;
}

banned_room = function(rm_name){
	if(string_pos("RoomStage_", rm_name) < 0) return true;
	
	switch(rm_name){
		case "RoomStage_Model": 
		case "RoomStage_worldmap_marduk_camp": 
		case "RoomStage_mainevent_10_6x1":
		case "RoomStage_mainevent_10_2x2":
		case "RoomStage_mainevent_25_cellar":
		case "RoomStage_mainevent_36_7x2":
		case "RoomStage_mainevent_25_9x8":
		case "RoomStage_mainevent_58_2x9":
		case "RoomStage_mainevent_64_2x0":
		case "RoomStage_mainevent_36_0x4":
		
		case "RoomStage_10_6x1_mainevent":
		case "RoomStage_10_2x2_mainevent":
		case "RoomStage_25_mainevent_cellar":
		case "RoomStage_F_25_mainevent_bio_entrance":
		case "RoomStage_worldmap_voltran_camp":
		case "RoomStage_worldmap_encounter":
		case "RoomStage_worldmap_merchant":
		case "RoomStage_36_7x2_mainevent":
		case "RoomStage_58_2x9_mainevent":
		case "RoomStage_L_41_4x2626":
		case "RoomStage_L_41_4x2627":
		case "RoomStage_F_x_1x0":
		case "RoomStage_x_0x1	":
		case "RoomStage_x_0x2":
		case "RoomStage_x_1x1":
		case "RoomStage_x_1x2":
		case "RoomStage_x_1x3":
		case "RoomStage_x_2x1":
		case "RoomStage_x_2x2":
		case "RoomStage_x_2x3":
		case "RoomStage_L_x_2x4":
			return true
	}
	
	return false;
}

do_stuff = function(){
	alarm[0] = 2;
	
	if(global.room_counter >= global.room_amount) { 
		var _str = json_stringify(global.roadout_box_amount_per_dungeon);
		var _buffer = buffer_create(string_byte_length(_str) + 1, buffer_fixed, 1);
		buffer_write(_buffer, buffer_string, _str);
		buffer_save(_buffer, "DUNGEON_INFO.json");
		buffer_delete(_buffer);
		
		execute_shell_simple(game_save_id)
		
		game_end();
		return;
	}

	var _room_node, buffer_room, string_room, struct_room, path;
	_room_node = global.roadout_strunct_yyp.RoomOrderNodes[global.room_counter].roomId;
	path = global.roadout_filepath + _room_node.path;
	path = string_replace_all(path, "/", global.special_char);
	
	buffer_room = buffer_load(path);
	string_room = buffer_read(buffer_room, buffer_string);
	struct_room = json_parse(string_room);

	if(string_pos("Box_AI", string_room) > 0 && !banned_room(struct_room.name)){
		show_debug_message("Loading Room: " + struct_room.name)
		var dg_key = get_dungeon_key(struct_room.name);
		
		global.roadout_box_amount_per_dungeon[$ dg_key][$ "Rooms"][$ "TotalRooms"]++;
		
		var f = 0; 
		repeat(array_length(struct_room.layers)){
			var _layer = struct_room.layers[f].name;
			if(_layer == "AllDungeonGangLayers"){ /// PICK ALL DUNGEON GANG LAYERS 
				
				global.roadout_box_amount_per_dungeon[$ dg_key][$ "EnemiesByRoom"][$ struct_room.name] = {};
			
				var g = 0; repeat(array_length(struct_room.layers[f].layers)){ 
					_layer = struct_room.layers[f].layers[g].name;
					if(_layer == "Box_Layer"){
						var h = 0; repeat(array_length(struct_room.layers[f].layers[g].layers)){
							var _layer_box = struct_room.layers[f].layers[g].layers[h];
							global.roadout_box_amount_per_dungeon[$ dg_key][$ "Boxes"][$ _layer_box.name] += array_length(_layer_box.instances);
							h++;
						}
					}
					
					if(_layer == "Enemy_Layer"){
						
						if(string_pos("F", struct_room.name) > 0){
							global.roadout_box_amount_per_dungeon[$ dg_key][$ "Dungeon_Leader"] = string_replace(struct_room.layers[f].layers[g].layers[0].name, "Enemy_","");
						}
						
						var h = 0; repeat(array_length(struct_room.layers[f].layers[g].layers)){
							var _layer_enemy = struct_room.layers[f].layers[g].layers[h];
							var _len = array_length(_layer_enemy.instances);
							
							if(_len > 0){
								
								var _roomWith = "";
								var _enemieGang = "";
								
								switch(_layer_enemy.name){
									case "Enemy_AI": _roomWith = "RoomWithEnemyAI"; _enemieGang = "AI"; break;
									case "Enemy_Bio": _roomWith = "RoomWithEnemyBio"; _enemieGang = "Bio"; break; 
									case "Enemy_Cyber": _roomWith = "RoomWithEnemyCyber"; _enemieGang = "Cyber"; break; 
									case "Enemy_Diesel": _roomWith = "RoomWithEnemyDiesel"; _enemieGang = "Diesel"; break; 
								}
								
								
								global.roadout_box_amount_per_dungeon[$ dg_key][$ "EnemiesByRoom"][$ struct_room.name][$ _enemieGang] = {};

								global.roadout_box_amount_per_dungeon[$ dg_key][$ "Rooms"][$ _roomWith]++;
								
								
								for(var j = 0; j < _len; j++){
									var _enemy_id = _layer_enemy.instances[j].objectId.name;
									if(_enemy_id == "obj_wave_system_divisor") continue
									
									if(variable_struct_exists(global.roadout_box_amount_per_dungeon[$ dg_key][$ "Enemies"][$ _enemieGang], _enemy_id)){
										global.roadout_box_amount_per_dungeon[$ dg_key][$ "Enemies"][$ _enemieGang][$ _enemy_id]++;
									}
									else{
										global.roadout_box_amount_per_dungeon[$ dg_key][$ "Enemies"][$ _enemieGang][$ _enemy_id] = 1;
									}
									
									if(variable_struct_exists(global.roadout_box_amount_per_dungeon[$ dg_key][$ "EnemiesByRoom"][$ struct_room.name][$ _enemieGang], _enemy_id)){
										global.roadout_box_amount_per_dungeon[$ dg_key][$ "EnemiesByRoom"][$ struct_room.name][$ _enemieGang][$ _enemy_id]++;
									}
									else{
										global.roadout_box_amount_per_dungeon[$ dg_key][$ "EnemiesByRoom"][$ struct_room.name][$ _enemieGang][$ _enemy_id] = 1;
									}
									
									
								}
							}
							
							
							h++;
						}
					}
					
					g++;
				}
			}
			
			f++;
		}
	}
	
	
	buffer_delete(buffer_room);
	global.room_counter++;
}
