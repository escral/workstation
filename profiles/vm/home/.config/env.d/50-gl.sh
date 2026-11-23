# virgl tops out at GL 4.2 on some hosts (NVIDIA); Ghostty needs 4.3 and
# runs fine when Mesa claims it.
export MESA_GL_VERSION_OVERRIDE=4.3
export MESA_GLSL_VERSION_OVERRIDE=430
