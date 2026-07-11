# syntax=docker/dockerfile:1

# ---------- Build stage ----------
FROM golang:1.22-alpine AS builder

WORKDIR /src

# Copy module file and download dependencies (cached layer)
COPY go.mod ./
RUN go mod download

# Copy source and build a statically-linked binary
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o /app/demo-app .

# ---------- Runtime stage ----------
FROM alpine:3.20

# Install ca-certificates for any outbound HTTPS calls
RUN apk --no-cache add ca-certificates

# Run as non-root user for security
RUN adduser -D -u 1000 appuser
USER appuser

WORKDIR /app
COPY --from=builder /app/demo-app .

EXPOSE 8080

ENTRYPOINT ["./demo-app"]
