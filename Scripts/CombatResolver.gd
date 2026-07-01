class_name CombatResolver
extends RefCounted


static func create_player_ship() -> Dictionary:
	return {
		"name": "Star Miner",
		"max_hull": 10000,
		"hull": 10000,
		"armor": 260,
		"shields": 220,
		"weapon_name": "Mining Laser Battery",
		"weapon_damage": 780,
		"damage_variance": 0.18,
	}


static func create_enemy_ship(enemy_name: String, is_surprise: bool = false) -> Dictionary:
	if is_surprise:
		return {
			"name": enemy_name,
			"max_hull": 1500,
			"hull": 1500,
			"armor": 180,
			"shields": 180,
			"weapon_name": "Ambush Lance",
			"weapon_damage": 1100,
			"damage_variance": 0.2,
		}
	
	return {
		"name": enemy_name,
		"max_hull": 1000,
		"hull": 1000,
		"armor": 170,
		"shields": 190,
		"weapon_name": "Raider Cannon",
		"weapon_damage": 920,
		"damage_variance": 0.2,
	}


static func resolve_round(attacker: Dictionary, defender: Dictionary) -> Dictionary:
	var raw_damage := roll_weapon_damage(attacker)
	var mitigation: int = int(defender["armor"]) + int(defender["shields"])
	var final_damage: int = maxi(raw_damage - mitigation, 0)
	defender["hull"] = maxi(int(defender["hull"]) - final_damage, 0)
	
	return {
		"attacker": attacker["name"],
		"defender": defender["name"],
		"weapon": attacker["weapon_name"],
		"raw_damage": raw_damage,
		"mitigation": mitigation,
		"final_damage": final_damage,
		"defender_hull": defender["hull"],
	}


static func roll_weapon_damage(combatant: Dictionary) -> int:
	var base_damage: int = int(combatant["weapon_damage"])
	var variance: float = float(combatant["damage_variance"])
	var multiplier := randf_range(1.0 - variance, 1.0 + variance)
	return maxi(roundi(float(base_damage) * multiplier), 0)


static func get_hull_text(combatant: Dictionary) -> String:
	return "%s Hull: %d / %d" % [
		combatant["name"],
		int(combatant["hull"]),
		int(combatant["max_hull"]),
	]
