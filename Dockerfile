FROM golang:1.22-alpine AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod verify && go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
    go build -ldflags="-w -s" -trimpath -o /pvz-service ./cmd

FROM alpine:3.20.0
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
WORKDIR /app
COPY --from=builder --chown=appuser:appgroup /pvz-service /app/
COPY --from=builder --chown=appuser:appgroup /app/migrations /app/migrations
USER appuser
EXPOSE 8080
ENTRYPOINT ["/app/pvz-service"]