#ifndef SHADER_BINDINGS_HLSL
#define SHADER_BINDINGS_HLSL

#define CB_SLOT(slot) register(b##slot, space0)
#define TEX_SLOT(slot) register(t##slot, space0)
#define SAMPLER_SLOT(slot) register(s##slot, space0)
#define STORAGE_SLOT(slot) register(u##slot, space0)

#endif // SHADER_BINDINGS_HLSL
