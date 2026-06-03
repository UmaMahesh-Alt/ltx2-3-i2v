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
# COPY start.sh from repo (not cat > file)
COPY start.sh /start.sh
RUN chmod +x /start.sh
