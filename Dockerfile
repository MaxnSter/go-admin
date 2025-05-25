# Build stage
FROM golang:1.24-alpine AS builder

# Install build dependencies
RUN apk add --no-cache gcc musl-dev sqlite-dev

WORKDIR /src
COPY go.mod go.sum ./
RUN go mod download

COPY . .
RUN CGO_ENABLED=1 GOOS=linux go build -tags sqlite3 -ldflags="-w -s -extldflags '-static'" -a -installsuffix cgo -o go-admin .

# Runtime stage
FROM alpine

# ENV GOPROXY https://goproxy.cn/

RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.ustc.edu.cn/g' /etc/apk/repositories

RUN apk update --no-cache
RUN apk add --no-cache ca-certificates tzdata sqlite
ENV TZ Asia/Shanghai

WORKDIR /app
COPY --from=builder /src/go-admin /app/go-admin
COPY ./config/settings.demo.yml /app/config/settings.yml
COPY ./go-admin-db.db /app/go-admin-db.db

# Create necessary directories
RUN mkdir -p /app/temp/logs /app/static

EXPOSE 8000
RUN chmod +x /app/go-admin
CMD ["/app/go-admin","server","-c", "/app/config/settings.yml"]