# Work PC: i7-6700, Intel HD 530, 32GB.
# shellcheck disable=SC2034
extends=base
modules+=(dev-node dev-bun dev-php claude docker)
GPU=intel
AI_TIER=cpu
