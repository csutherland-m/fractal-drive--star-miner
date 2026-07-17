class_name DamageRules
extends RefCounted


## Shared flat-armor rule. Armor is applied after shields and a successful hit
## always inflicts at least minimum_damage so armor cannot create invulnerability.
static func calculate_armored_damage(
	raw_damage: float,
	armor: int,
	minimum_damage: int = 1
) -> int:
	if raw_damage <= 0.0:
		return 0
	return maxi(ceili(raw_damage) - maxi(armor, 0), maxi(minimum_damage, 0))
