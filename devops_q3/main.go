package main

import (
    "fmt"
    "log"
    "net/http"
)

func handler(w http.ResponseWriter, r *http.Request) {
    log.Println("Received request for:", r.URL.Path)
    fmt.Fprintf(w, "Hello, DevOps World! This is the microservice.")
}

func main() {
    http.HandleFunc("/", handler)
    log.Println("Starting web server on port 8080...")
    
    // This server listens on 8080.
    if err := http.ListenAndServe(":8080", nil); err != nil {
        log.Fatal(err)
    }
}
