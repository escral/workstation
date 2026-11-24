# Home PC: Ryzen 7 5700X3D, RTX 4070, 32GB.
# shellcheck disable=SC2034
extends=base
modules+=(nvidia bluetooth dev-node dev-bun dev-php claude docker)
GPU=nvidia
AI_TIER=gpu
