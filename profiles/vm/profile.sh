# shellcheck disable=SC2034
extends=base
GPU=virtio
AI_TIER=cpu
FIREWALL_ALLOW="ssh"
modules+=(virtio claude chrome telegram slack docker jetbrains)
