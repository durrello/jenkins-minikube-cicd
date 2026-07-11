package main

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
)

// Version is set at build time via ldflags
var Version = "dev"

type InfoResponse struct {
	App      string `json:"app"`
	Version  string `json:"version"`
	Hostname string `json:"hostname"`
}

func main() {
	mux := http.NewServeMux()
	mux.HandleFunc("/", infoHandler)
	mux.HandleFunc("/health", healthHandler)
	mux.HandleFunc("/ready", readyHandler)

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	log.Printf("demo-app %s starting on :%s", Version, port)
	if err := http.ListenAndServe(fmt.Sprintf(":%s", port), mux); err != nil {
		log.Fatalf("server failed: %v", err)
	}
}

// infoHandler returns application metadata as JSON.
func infoHandler(w http.ResponseWriter, r *http.Request) {
	if r.URL.Path != "/" {
		http.NotFound(w, r)
		return
	}

	hostname, _ := os.Hostname()
	resp := InfoResponse{
		App:      "demo-app",
		Version:  Version,
		Hostname: hostname,
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(resp)
}

// healthHandler returns 200 if the service is alive.
func healthHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	fmt.Fprint(w, `{"status":"healthy"}`)
}

// readyHandler returns 200 if the service is ready to accept traffic.
func readyHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	fmt.Fprint(w, `{"status":"ready"}`)
}
