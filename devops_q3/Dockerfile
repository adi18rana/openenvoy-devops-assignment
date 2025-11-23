FROM golang:1.21-alpine AS builder

WORKDIR /app

COPY go.mod ./
COPY . .

# Fix bug: fail build if formatting errors found
RUN test -z "$(gofmt -l .)"

RUN CGO_ENABLED=0 GOOS=linux go build -o /app/server .

# --- Final Stage ---
FROM alpine:latest

WORKDIR /root/
COPY --from=builder /app/server .

# EXPOSE correct port 8080 matching the server in main.go
EXPOSE 8080

CMD ["./server"]
