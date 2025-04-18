#!/usr/bin/env bash
set -e          # exit on first error
set -o pipefail # catch errors in piped commands

###############################################################################
# ComfyUI fresh install on an RTX 5080/5090 RunPod (or any CUDA 12.8+ GPU)
#   – no sudo, runs as root in the pod
#   – Python 3.10‑3.11 image with *no* pre‑installed Torch assumed
###############################################################################

CUDA_TAG=${CUDA_TAG:-cu128}          # allow override: CUDA_TAG=cu130 bash install...
TORCH_NIGHTLY_INDEX="https://download.pytorch.org/whl/nightly/${CUDA_TAG}"

echo "=== [1] workspace ======================================================="
cd ~
mkdir -p comfy && cd comfy

echo "=== [2] apt packages ===================================================="
apt update -y
apt install -y git python3-venv build-essential \
               libgl1 libglib2.0-0 libsm6 libxext6 libxrender-dev ffmpeg

echo "=== [3] clone ComfyUI ==================================================="
git clone --depth 1 https://github.com/comfyanonymous/ComfyUI.git
cd ComfyUI

echo "=== [4] venv ============================================================"
python3 -m venv venv
source venv/bin/activate
pip install --upgrade --no-cache-dir pip wheel setuptools

echo "=== [5] base deps ======================================================="
pip install --no-cache-dir \
    opencv-python-headless==4.* \
    'pillow>=10.2.0,<11' \
    psutil scipy>=1.12 sympy imageio einops>=0.7 \
    accelerate>=0.27 torchsde safetensors tqdm \
    requests markdown2 fonttools ninja

echo "=== [6] GPU‑ready nightly PyTorch stack ================================="
pip install --pre --no-cache-dir --index-url "${TORCH_NIGHTLY_INDEX}" \
    torch torchvision torchaudio

echo "=== [7] vision / diffusion libs ========================================="
pip install --no-cache-dir \
    'transformers>=4.39' 'diffusers>=0.27.2' \
    sentencepiece huggingface-hub

echo "=== [8] web server libs ================================================"
pip install --no-cache-dir aiohttp>=3.11 aiohttp_cors websockets

echo "=== [9] ComfyUI split frontend & templates =============================="
pip install --no-cache-dir \
    comfyui-frontend-package==1.17.1 \
    comfyui-workflow-templates==0.1.1

echo "=== [10] done – launch command =========================================="
echo
echo "Inside this venv run:"
echo "  source ~/comfy/ComfyUI/venv/bin/activate"
echo "  python ~/comfy/ComfyUI/main.py --listen 0.0.0.0 --port 8188"
