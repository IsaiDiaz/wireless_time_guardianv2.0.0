package main

import (
	"encoding/json"
	"log"
	"net"
	"net/http"
	"sync"
	"time"

	"github.com/gorilla/websocket"
)

type Device struct {
	UUID     string
	Present  bool
	LastSeen time.Time
}

var devices = make(map[string]*Device)
var mu sync.Mutex

var upgrader = websocket.Upgrader{
	CheckOrigin: func(r *http.Request) bool {
		return true
	},
}

var connections = make(map[*websocket.Conn]bool)

func handleConnections(w http.ResponseWriter, r *http.Request) {
	ws, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		log.Fatal(err)
	}
	defer ws.Close()

	mu.Lock()
	connections[ws] = true
	mu.Unlock()

	defer func() {
		mu.Lock()
		delete(connections, ws)
		mu.Unlock()
	}()

	for {
		_, message, err := ws.ReadMessage()
		if err != nil {
			log.Println("Error reading message:", err)
			break
		}

		var data map[string]string
		if err := json.Unmarshal(message, &data); err != nil {
			log.Println("Error unmarshaling message:", err)
			continue
		}

		uuid, ok := data["content"]
		if !ok {
			log.Println("Invalid message format")
			continue
		}

		mu.Lock()
		devices[uuid] = &Device{
			UUID:     uuid,
			Present:  true,
			LastSeen: time.Now(),
		}
		log.Printf("Device %s marked as present", uuid)
		mu.Unlock()
	}
}

func periodicCheck() {
	for {
		time.Sleep(30 * time.Second)
		mu.Lock()
		for uuid, device := range devices {
			if time.Since(device.LastSeen) > 30*time.Second {
				device.Present = false
				log.Printf("Device %s marked as absent", uuid)
			}
		}
		mu.Unlock()
		log.Println("Checked devices")

		sendRollCall()
	}
}

func sendRollCall() {
	mu.Lock()
	defer mu.Unlock()
	for conn := range connections {
		message := map[string]string{"type": "roll_call"}
		msg, _ := json.Marshal(message)
		if err := conn.WriteMessage(websocket.TextMessage, msg); err != nil {
			log.Println("Error sending message:", err)
			conn.Close()
			delete(connections, conn)
		}
	}
}

func publishServerIP(){
	localIP := getLocalIP()
	for {
		time.Sleep(10 * time.Second)
		sendIPBroadcast(localIP)
	}
}

func getLocalIP() string {
	con, err := net.Dial("udp", "8.8.8.8:80")
	if err != nil {
		log.Println("Error getting local IP:", err)
		return ""
	}

	defer con.Close()

	localAddr := con.LocalAddr().(*net.UDPAddr)
	return localAddr.IP.String()
}

func sendIPBroadcast(ip string) {
	addr, err := net.ResolveUDPAddr("udp", "255.255.255.255:12345")
	if err != nil {
		log.Println("Error resolving UDP address:", err)
		return
	}

	con, err := net.DialUDP("udp", nil, addr)
	if err != nil {
		log.Println("Error dialing UDP:", err)
		return
	}

	defer con.Close()

	_, err = con.Write([]byte(ip))
	if err != nil {
        log.Println("Error sending broadcast message:", err)
	}
}

func main() {
	http.HandleFunc("/ws", handleConnections)
	go periodicCheck()
	go publishServerIP()
	log.Fatal(http.ListenAndServe(":8080", nil))
}
