extends HSplitContainer


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	$PlantPanel/PlantDetails/DetailList/GroupButton.connect("pressed", self, "_add_current_plant_to_current_group")


func _add_current_plant_to_current_group():
	var current_plant = $PlantPanel/PlantDetails.current_plant
	var current_group = $HSplitContainer/GroupPanel/GroupDetails.current_group
	
	current_group.add_plant(current_plant)
	
	$HSplitContainer/GroupPanel/GroupDetails/GroupAttributes/Attributes/GroupPlantList.update_plants()
