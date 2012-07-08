default:
	mkdir -p bin
	dmd src/client.d src/net.d src/messages.d -ofbin/client -odbin/
	dmd src/server.d src/net.d src/messages.d -ofbin/server -odbin/
