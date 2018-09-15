extends Node

# HTTPClient demo
# This simple class can do HTTP requests, it will not block but it needs to be polled

func getJson(host,url,port):
	logger.info("Trying to connect to: "+host+":"+str(port)+url)
	var err = 0
	var http = HTTPClient.new() # Create the Client

	err = http.connect_to_host(host,port) # Connect to host/port
	if not err == OK:
		return JSON.parse('{"Error":"Could not connect to Host"}')
	
	# Wait until resolved and connected
	while http.get_status() == HTTPClient.STATUS_CONNECTING or http.get_status() == HTTPClient.STATUS_RESOLVING:
		http.poll()
		logger.info("Connecting..")
		OS.delay_msec(500)
	
	if http.get_status() != HTTPClient.STATUS_CONNECTED:
		return JSON.parse('{"Error":"Could not connect to Host"}')
	
	# Some headers
	var headers = [
		"User-Agent: Pirulo/1.0 (Godot)",
		"Accept: */*"
	]
	
	err = http.request(HTTPClient.METHOD_GET, url, headers) # Request a page from the site (this one was chunked..)
	if err != OK:
		return JSON.parse('{"Error":"HTTP Request flawed"}')
	
	while http.get_status() == HTTPClient.STATUS_REQUESTING:
		# Keep polling until the request is going on
		http.poll()
		logger.info("Requesting..")
		OS.delay_msec(500)
	
	if not http.get_status() == HTTPClient.STATUS_BODY and not http.get_status() == HTTPClient.STATUS_CONNECTED:
		return JSON.parse('{"Error":"HTTP Request failed"}')
	
	logger.info("response? " + str(http.has_response())) # Site might not have a response.
	
	if http.has_response():
		# If there is a response..
		
		headers = http.get_response_headers_as_dictionary() # Get response headers
		logger.info("code: " + str(http.get_response_code())) # Show response code
		logger.info("**headers:\\n" + str(headers)) # Show headers
		
		# Getting the HTTP Body
		
		var rl = float(0)
		if http.is_response_chunked():
			# Does it use chunks?
			logger.info("Response is Chunked!")
		else:
			# Or just plain Content-Length
			var bl = http.get_response_body_length()
			logger.info("Response Length: " + str(bl))
			rl = bl
			
		
		# This method works for both anyway
		var rll = float(0)
		var rb = PoolByteArray() # Array that will hold the data
		
		while http.get_status() == HTTPClient.STATUS_BODY:
			# While there is body left to be read
			http.poll()
			#logger.info("getting a chunk")
			var chunk = http.read_response_body_chunk() # Get a chunk
			if chunk.size() == 0:
				# Got nothing, wait for buffers to fill a bit
				OS.delay_usec(1000)
			else:
				rll += chunk.size()
				#logger.info(str(round((rll/rl)*100)) + "% finished")
				rb = rb + chunk # Append to read buffer
		
		# Done!
		
		logger.info("bytes got: " + str(rb.size()))
		var text = rb.get_string_from_ascii()
		
		var json = JSON.parse(text)
		if json.error == OK:  # If parse OK
			return json.result
		else:  # If parse has errors
			print("Error: ", json.error)