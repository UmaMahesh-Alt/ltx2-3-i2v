# clean base image containing only comfyui, comfy-cli and comfyui-manager
FROM runpod/worker-comfyui:5.8.4-base

# Busts the Docker cache - change this value to force rebuild
#ARG CACHE_BUST=1

# build-time tokens for gated downloads — never baked into final image.
# pass via: docker build --build-arg HF_TOKEN=$HF_TOKEN ...
ARG HF_TOKEN=""

# download models into comfyui
RUN BACKOFFS="10 20 30 60 90" && for i in 1 2 3 4 5; do HF_TOKEN=$HF_TOKEN comfy model download --url 'https://huggingface.co/Lightricks/LTX-2.3-fp8/resolve/main/ltx-2.3-22b-dev-fp8.safetensors' --relative-path models/checkpoints --filename 'ltx-2.3-22b-dev-fp8.safetensors' && break; if [ $i -eq 5 ]; then echo "model-download failed after 5 attempts" >&2; exit 1; fi; SLEEP=$(echo $BACKOFFS | cut -d ' ' -f $i) && echo "model-download attempt $i failed; retrying in $SLEEP seconds" >&2; sleep $SLEEP; done
RUN BACKOFFS="10 20 30 60 90" && for i in 1 2 3 4 5; do HF_TOKEN=$HF_TOKEN comfy model download --url 'https://huggingface.co/Lightricks/LTX-2.3/resolve/main/ltx-2.3-22b-distilled-lora-384.safetensors' --relative-path models/loras --filename 'ltx-2.3-22b-distilled-lora-384.safetensors' && break; if [ $i -eq 5 ]; then echo "model-download failed after 5 attempts" >&2; exit 1; fi; SLEEP=$(echo $BACKOFFS | cut -d ' ' -f $i) && echo "model-download attempt $i failed; retrying in $SLEEP seconds" >&2; sleep $SLEEP; done
RUN BACKOFFS="10 20 30 60 90" && for i in 1 2 3 4 5; do HF_TOKEN=$HF_TOKEN comfy model download --url 'https://huggingface.co/Lightricks/LTX-2.3/resolve/main/ltx-2.3-spatial-upscaler-x2-1.1.safetensors' --relative-path models/latent_upscale_models --filename 'ltx-2.3-spatial-upscaler-x2-1.1.safetensors' && break; if [ $i -eq 5 ]; then echo "model-download failed after 5 attempts" >&2; exit 1; fi; SLEEP=$(echo $BACKOFFS | cut -d ' ' -f $i) && echo "model-download attempt $i failed; retrying in $SLEEP seconds" >&2; sleep $SLEEP; done
RUN BACKOFFS="10 20 30 60 90" && for i in 1 2 3 4 5; do HF_TOKEN=$HF_TOKEN comfy model download --url 'https://huggingface.co/Comfy-Org/ltx-2/resolve/main/split_files/text_encoders/gemma_3_12B_it_fp4_mixed.safetensors' --relative-path models/text_encoders --filename 'gemma_3_12B_it_fp4_mixed.safetensors' && break; if [ $i -eq 5 ]; then echo "model-download failed after 5 attempts" >&2; exit 1; fi; SLEEP=$(echo $BACKOFFS | cut -d ' ' -f $i) && echo "model-download attempt $i failed; retrying in $SLEEP seconds" >&2; sleep $SLEEP; done

# copy all input data (like images or videos) into comfyui (uncomment and adjust if needed)
# COPY input/ /comfyui/input/

# user-provided inputs override the auto-generated placeholders above.
RUN wget --progress=dot:giga -O '/comfyui/input/egyptian_queen.png' "https://cool-anteater-319.convex.cloud/api/storage/e926b8da-f2ad-4634-a080-24beb34e1aa7"

# FROM runpod/worker-comfyui:5.8.4-base

# # =========================================================================
# # STEP 1: Download all LTX-2.3 models
# # =========================================================================

# # Main checkpoint
# RUN mkdir -p /comfyui/models/checkpoints && \
#     wget -q -O '/comfyui/models/checkpoints/ltx-2.3-22b-dev-fp8.safetensors' \
#     'https://huggingface.co/Lightricks/LTX-2.3-fp8/resolve/main/ltx-2.3-22b-dev-fp8.safetensors'

# # LoRA models
# RUN mkdir -p /comfyui/models/loras && \
#     wget -q -O '/comfyui/models/loras/ltx-2.3-22b-distilled-lora-384.safetensors' \
#     'https://huggingface.co/Lightricks/LTX-2.3/resolve/main/ltx-2.3-22b-distilled-lora-384.safetensors'

# # Upscaler model
# RUN mkdir -p /comfyui/models/latent_upscale_models && \
#     wget -q -O '/comfyui/models/latent_upscale_models/ltx-2.3-spatial-upscaler-x2-1.1.safetensors' \
#     'https://huggingface.co/Lightricks/LTX-2.3/resolve/main/ltx-2.3-spatial-upscaler-x2-1.1.safetensors'

# # Text encoder (Gemma 3)
# RUN mkdir -p /comfyui/models/text_encoders && \
#     wget -q -O '/comfyui/models/text_encoders/gemma_3_12B_it_fp4_mixed.safetensors' \
#     'https://huggingface.co/Comfy-Org/ltx-2/resolve/main/split_files/text_encoders/gemma_3_12B_it_fp4_mixed.safetensors'

# # Input image
# RUN mkdir -p /comfyui/input && \
#     wget --progress=dot:giga -O '/comfyui/input/egyptian_queen.png' \
#     "https://cool-anteater-319.convex.cloud/api/storage/0fbfc66e-ca2f-45ed-8606-cec00db4a767"

# =========================================================================
# STEP 2: Override start.sh with network volume symlink setup
# =========================================================================
RUN cat > /start.sh << 'EOF' && chmod +x /start.sh
#!/usr/bin/env bash

# =========================================================================
# NETWORK VOLUME SETUP - Create symlinks to network volume
# =========================================================================
echo "worker-comfyui: Setting up network volume symlinks..."

# Ensure volume directories exist
# mkdir -p /runpod-volume/input
# mkdir -p /runpod-volume/output

# Remove old symlinks if they exist
rm -f /comfyui/input /comfyui/output

# Create symlinks to network volume
ln -s /runpod-volume /comfyui/input
ln -s /runpod-volume /comfyui/output

echo "worker-comfyui: Symlinks created:"
echo "  /comfyui/input → /runpod-volume"
echo "  /comfyui/output → /runpod-volume"

# =========================================================================
# ORIGINAL start.sh CONTENT BELOW
# =========================================================================

# Start SSH server if PUBLIC_KEY is set (enables remote access and dev-sync.sh)
if [ -n "$PUBLIC_KEY" ]; then
    mkdir -p ~/.ssh
    echo "$PUBLIC_KEY" > ~/.ssh/authorized_keys
    chmod 700 ~/.ssh
    chmod 600 ~/.ssh/authorized_keys

    # Generate host keys if they don't exist (removed during image build for security)
    for key_type in rsa ecdsa ed25519; do
        key_file="/etc/ssh/ssh_host_${key_type}_key"
        if [ ! -f "$key_file" ]; then
            ssh-keygen -t "$key_type" -f "$key_file" -q -N ''
        fi
    done

    service ssh start && echo "worker-comfyui: SSH server started" || echo "worker-comfyui: SSH server could not be started" >&2
fi

# Use libtcmalloc for better memory management
TCMALLOC="$(ldconfig -p | grep -Po "libtcmalloc.so.\d" | head -n 1)"
export LD_PRELOAD="${TCMALLOC}"

# ---------------------------------------------------------------------------
# GPU pre-flight check
# Verify that the GPU is accessible before starting ComfyUI. If PyTorch
# cannot initialize CUDA the worker will never be able to process jobs,
# so we fail fast with an actionable error message.
# ---------------------------------------------------------------------------
echo "worker-comfyui: Checking GPU availability..."
if ! GPU_CHECK=$(python3 -c "
import torch
try:
    torch.cuda.init()
    name = torch.cuda.get_device_name(0)
    print(f'OK: {name}')
except Exception as e:
    print(f'FAIL: {e}')
    exit(1)
" 2>&1); then
    echo "worker-comfyui: GPU is not available. PyTorch CUDA init failed:"
    echo "worker-comfyui: $GPU_CHECK"
    echo "worker-comfyui: This usually means the GPU on this machine is not properly initialized."
    echo "worker-comfyui: Please contact RunPod support and report this machine."
    exit 1
fi
echo "worker-comfyui: GPU available — $GPU_CHECK"

# Ensure ComfyUI-Manager runs in offline network mode inside the container
comfy-manager-set-mode offline || echo "worker-comfyui - Could not set ComfyUI-Manager network_mode" >&2

echo "worker-comfyui: Starting ComfyUI"

# Allow operators to tweak verbosity; default is DEBUG.
: "${COMFY_LOG_LEVEL:=DEBUG}"

# PID file used by the handler to detect if ComfyUI is still running
COMFY_PID_FILE="/tmp/comfyui.pid"

# Serve the API and don't shutdown the container
if [ "$SERVE_API_LOCALLY" == "true" ]; then
    python -u /comfyui/main.py --disable-auto-launch --disable-metadata --listen --verbose "${COMFY_LOG_LEVEL}" --log-stdout &
    echo $! > "$COMFY_PID_FILE"

    echo "worker-comfyui: Starting RunPod Handler"
    python -u /handler.py --rp_serve_api --rp_api_host=0.0.0.0
else
    python -u /comfyui/main.py --disable-auto-launch --disable-metadata --verbose "${COMFY_LOG_LEVEL}" --log-stdout &
    echo $! > "$COMFY_PID_FILE"

    echo "worker-comfyui: Starting RunPod Handler"
    python -u /handler.py
fi
EOF
