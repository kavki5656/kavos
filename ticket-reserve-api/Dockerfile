# ステージ１：ビルド環境
FROM golang:alpine AS builder

WORKDIR /app

COPY go.mod go.sum* ./
RUN go mod download

COPY . .

RUN CGO_ENABLED=0 GOOS=linux go build -o ticket-api main.go

# ステージ２：本番実行環境
FROM alpine:latest

RUN apk --no-cache add ca-certificates

WORKDIR /app

COPY --from=builder /app/ticket-api .

EXPOSE 8080

CMD ["./ticket-api"]
