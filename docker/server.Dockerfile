ARG BUILDPLATFORM
FROM --platform=$BUILDPLATFORM node:22-alpine AS ui-builder
# alpine install make
RUN apk add --no-cache make

WORKDIR /app

COPY Makefile ./
COPY ui/package.json ui/package-lock.json ./
COPY ui ui
RUN mkdir -p internal/registry/api/ui/dist
RUN make build-ui

ARG BUILDPLATFORM
FROM --platform=$BUILDPLATFORM golang:1.25-alpine AS builder

# alpine install make
RUN apk add --no-cache make

WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download && go mod verify

COPY cmd cmd
COPY internal internal
COPY pkg pkg

COPY --from=ui-builder /app/internal/registry/api/ui/dist /app/internal/registry/api/ui/dist

# Build
# the GOARCH has not a default value to allow the binary be built according to the host where the command
# was called. For example, if we call make docker-build in a local env which has the Apple Silicon M1 SO
# the docker BUILDPLATFORM arg will be linux/arm64 when for Apple x86 it will be linux/amd64. Therefore,
# by leaving it empty we can ensure that the container and binary shipped on it will have the same platform.
ARG TARGETARCH
ARG TARGETPLATFORM
ARG LDFLAGS
RUN CGO_ENABLED=0 GOOS=${TARGETOS:-linux} GOARCH=${TARGETARCH} go build -a -ldflags "$LDFLAGS" -o bin/arctl-server cmd/server/main.go

FROM docker:28.5.1-cli AS runtime

COPY --from=builder /app/bin/arctl-server /app/bin/arctl-server
COPY .env /app/.env
COPY docker/server-entrypoint.sh /app/server-entrypoint.sh
RUN chmod +x /app/server-entrypoint.sh

LABEL org.opencontainers.image.source=https://github.com/agentregistry-dev/agentregistry
LABEL org.opencontainers.image.description="Agent Registry Server"
LABEL org.opencontainers.image.authors="Agent Registry Creators 🤖"

CMD ["/app/server-entrypoint.sh"]