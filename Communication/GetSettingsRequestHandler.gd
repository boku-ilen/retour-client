extends AbstractRequestHandler
class_name GetSettingsRequestHandler

#
# answers to GET_SETTINGS requests which indicate a connection initialization
# of the/a LabTable which should be registered in the system
#


export(NodePath) var labtable


# set the protocol keyword
func _init():
	protocol_keyword = "GET_SETTINGS"


func handle_request(request: Dictionary) -> Dictionary:
	
	# register the LabTable 
	if labtable:
		if labtable.has_method("register_labtable_connection"):
			labtable.register_labtable_connection()  # FIXME: method parameters?
		else:
			logger.warning("could not register LabTable - ProgrammingError!")
			
	# answer the lab table settings
	var answer = { "success": true }
	for key in request:
		answer[key] = Settings.get_setting("labtable", key)
	
	return answer
