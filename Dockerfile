FROM ghcr.io/ggml-org/llama.cpp:server

WORKDIR /app
COPY scripts/start.sh /app/scripts/start.sh
COPY scripts/download-model.sh /app/scripts/download-model.sh
RUN chmod +x /app/scripts/start.sh /app/scripts/download-model.sh

ENV HOST=0.0.0.0 \
    MODEL_DIR=/models \
    MODEL_PATH=/models/model.gguf \
    DOWNLOAD_MODEL=true \
    CPU_THREADS=2 \
    CPU_THREADS_BATCH=2 \
    CONTEXT_SIZE=2048 \
    BATCH_SIZE=256 \
    UBATCH_SIZE=128 \
    PARALLEL=1 \
    LOG_VERBOSITY=3

RUN mkdir -p /models
VOLUME ["/models"]
ENTRYPOINT ["/app/scripts/start.sh"]
