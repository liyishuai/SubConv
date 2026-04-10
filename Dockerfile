FROM --platform=$BUILDPLATFORM python:3.13-alpine3.22 AS builder
LABEL name="subconv"

WORKDIR /app

RUN apk add --update-cache ca-certificates tzdata patchelf clang ccache && \
    apk upgrade --no-cache

RUN pip3 install uv

ENV UV_LINK_MODE=copy UV_PYTHON_DOWNLOADS=0

COPY pyproject.toml uv.lock ./

RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --locked --no-install-project --no-editable --group build

COPY . .

RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --locked --no-editable --group build

RUN --mount=type=cache,target=/root/.cache/Nuitka \
    uv run python -m nuitka --clang --onefile --standalone api.py && \
    chmod +x api.bin


FROM alpine:3.22

WORKDIR /app

RUN apk upgrade --no-cache

COPY --from=builder /app/api.bin /app/api.bin
COPY --from=builder /usr/share/zoneinfo /usr/share/zoneinfo
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY static /app/static
COPY config.yaml /app/config.yaml

EXPOSE 8080

ENTRYPOINT ["/app/api.bin"]
