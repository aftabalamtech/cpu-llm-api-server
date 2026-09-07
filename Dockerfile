FROM ghcr.io/ggml-org/llama.cpp:server

WORKDIR /app

# The official llama.cpp server image installs the server binary at /app/llama-server.
# Verify it during the image build so a broken/mismatched base image fails early.
RUN test -x /app/llama-server \
    && /app/llama-server --version \
    && echo "Verified llama-server at /app/llama-server"

COPY scripts/start.sh /app/scripts/start.sh
COPY scripts/download-model.sh /app/scripts/download-model.sh
RUN chmod +x /app/scripts/start.sh /app/scripts/download-model.sh \
    && mkdir -p /models

ENV HOST=0.0.0.0 \
    MODEL_DIR=/models \
    DOWNLOAD_MODEL=true \
    LLAMA_SERVER_BIN=/app/llama-server \
    CPU_THREADS=2 \
    CPU_THREADS_BATCH=2 \
    CONTEXT_SIZE=2048 \
    BATCH_SIZE=256 \
    UBATCH_SIZE=128 \
    PARALLEL=1 \
    LOG_VERBOSITY=3

VOLUME ["/models"]
ENTRYPOINT ["/app/scripts/start.sh"]
