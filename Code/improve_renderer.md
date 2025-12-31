# Renderer Improvement Plan

## Overview

This document tracks the planned improvements to the Sedulous renderer codebase. The renderer has a solid architectural foundation but needs work on material systems, resource management, and shader handling.

---

## What's Working Well

- **Layered architecture** - Clean separation between `Sedulous.Engine.Renderer` (abstraction) and `Sedulous.Engine.Renderer.RHI` (implementation)
- **Scene modules** - RenderModule and AnimationModule per-scene is a good pattern
- **Reference counting** - GPUResourceHandle prevents use-after-free
- **RenderGraph foundation** - Good abstraction for command scheduling
- **Animation math** - Correct quaternion SLERP, matrix composition, hierarchy traversal

---

## Key Problems

1. **RHIRendererSubsystem is monolithic (~600 lines)** - Pipeline creation, resource management, window handling, shader compilation all mixed together
2. **Too many separate caches in RenderModule** - 7 different dictionaries with different lifetime semantics
3. **Incomplete material system** - PhongMaterial and PBRMaterial defined but no pipelines/shaders
4. **Shaders embedded as strings** - No hot-reloading, no variants, difficult to maintain
5. **Hardcoded limits without validation** - MAX_OBJECTS=1000, MAX_BONES=128 with no overflow checks
6. **Inconsistent resource ownership** - Mix of ref-counted handles and raw pointers

---

## Phase 1: Code Cleanup & Consolidation

### 1.1 Consolidate GPU resource caching
- [x] Create unified `RenderCache` class for all renderer -> GPU resource mappings
- [x] Single point for cleanup and lifetime management
- [x] Replace 7 separate dictionaries in RenderModule

### 1.2 Extract pipeline management
- [x] Create `PipelineManager` class
- [x] Move pipeline creation from RHIRendererSubsystem
- [x] Add material type -> pipeline registry

### 1.3 Extract shader management
- [x] Create `ShaderManager` class
- [ ] Load shaders from files instead of embedded strings
- [ ] Add shader compilation caching

---

## Phase 2: Material System Improvements

### 2.1 Material pipeline registry
- [x] Create `MaterialPipelineRegistry` class
- [x] Register pipelines by material type
- [x] Remove hardcoded switch statements

### 2.2 Implement missing pipelines
- [x] Phong pipeline (lighting support)
- [x] Skinned Phong pipeline (animated meshes with lighting)
- [x] PBR pipeline (physically-based rendering)
- [x] Skinned PBR pipeline (animated meshes with PBR)

### 2.3 Material serialization
- [ ] Define material file format
- [ ] Implement `MaterialResourceManager.LoadFromMemory()`

---

## Phase 3: Rendering Pipeline

### 3.1 Add render passes
- [ ] Depth prepass for better z-rejection
- [x] Separate opaque and transparent passes
- [x] Sort transparent objects back-to-front

### 3.2 Add culling
- [x] Frustum culling
- [ ] Optional occlusion culling

### 3.3 Add render statistics
- [x] Draw call count
- [x] Triangle count
- [x] GPU memory usage tracking

---

## Phase 4: Animation System

### 4.1 Animation blending
- [ ] CrossFade between animations
- [ ] Animation layers/masks

### 4.2 Optimization
- [ ] Dirty flag for unchanged poses
- [ ] Cache computed matrices when animation paused

### 4.3 Animation events
- [ ] Callbacks for animation completion
- [ ] Keyframe event triggers

---

## Phase 5: Resource Management Hardening

### 5.1 Thread-safe deletion queue
- [ ] Don't delete GPU resources immediately on ReleaseRef()
- [ ] Queue for deletion at end of frame

### 5.2 Validation
- [ ] Bone count <= MAX_BONES check
- [ ] Buffer overflow protection
- [ ] Null checks in critical paths

### 5.3 Memory tracking
- [ ] GPU memory budgets
- [ ] Resource usage statistics

---

## Target File Structure

```
Sedulous.Engine.Renderer.RHI/
├── RHIRendererSubsystem.bf      (simplified - just orchestration)
├── Modules/
│   ├── RenderModule.bf
│   └── AnimationModule.bf
├── Pipeline/
│   ├── PipelineManager.bf       (NEW)
│   ├── MaterialPipelineRegistry.bf (NEW)
│   └── ShaderManager.bf         (NEW)
├── Cache/
│   ├── RenderCache.bf           (NEW - consolidated caching)
│   └── GPUResourceManager.bf
├── GPU/
│   ├── GPUMesh.bf
│   ├── GPUSkinnedMesh.bf
│   ├── GPUMaterial.bf
│   ├── GPUTexture.bf
│   └── GPUSkeleton.bf
├── RenderGraph/
│   └── (existing)
└── Shaders/                     (NEW - external shader files)
    ├── Unlit.hlsl
    ├── Phong.hlsl
    └── Skinned.hlsl
```

---

## Progress Log

| Date | Changes |
|------|---------|
| 2024-12-31 | Initial plan created |
| 2025-12-31 | Phase 1.1 complete - Created RenderCache, refactored RenderModule |
| 2025-12-31 | Phase 1.2 complete - Created PipelineManager, extracted from RHIRendererSubsystem |
| 2025-12-31 | Phase 1.3 partial - Created ShaderManager for shader compilation |
| 2025-12-31 | Phase 2.1 complete - Created MaterialPipelineRegistry, removed hardcoded switches |
| 2025-12-31 | Phase 2.2 partial - Implemented Phong pipeline with lighting support |
| 2025-12-31 | Phase 2.2 continued - Added SkinnedPhongPipeline for animated meshes with lighting, updated RenderModule to select pipeline based on material type |
| 2025-12-31 | Scene-based lighting - Created LightingUniforms, added lighting buffer to PipelineManager, RenderModule collects DirectionalLight from scene, removed light properties from PhongMaterial |
| 2025-12-31 | Phase 2.2 complete - Implemented PBR pipeline with Cook-Torrance BRDF, skinned PBR variant, fixed camera position for view direction, fixed SDLImageLoader for indexed/palette PNG images |
| 2025-12-31 | Phase 3 partial - Added frustum culling, separate opaque/transparent render passes, proper sorting (front-to-back for opaque, back-to-front for transparent) |
| 2025-12-31 | Phase 3.3 complete - Added RenderStatistics with draw call count, triangle count, objects rendered/culled, GPU memory tracking |

