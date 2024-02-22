FROM golang:1.22-alpine

WORKDIR /exporter-app

COPY . .

RUN go mod download

ENTRYPOINT [ "go", "run", "main.go"]
