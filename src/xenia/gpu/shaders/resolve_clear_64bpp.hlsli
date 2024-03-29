#define XE_RESOLVE_CLEAR
#include "resolve.hlsli"

RWBuffer<uint4> xe_resolve_dest : register(u0);

[numthreads(8, 8, 1)]
void main(uint3 xe_thread_id : SV_DispatchThreadID) {
  // 1 thread = 8 host samples (same as resolve granularity at 1x1 scale).
  uint2 extent_scale =
      uint2(XeResolveEdramMsaaSamples() >= uint2(kXenosMsaaSamples_4X,
                                                 kXenosMsaaSamples_2X));
  // Group height can't cross resolve granularity, Y overflow check not needed.
  [branch] if (xe_thread_id.x >=
               (XeResolveScaledSizeDiv8().x << extent_scale.x)) {
    return;
  }
  uint address_int4s =
      XeEdramOffsetInts(
          (xe_thread_id.xy << uint2(3u, 0u)) +
              (XeResolveScaledOffset() << extent_scale),
          XeResolveEdramBaseTiles(), XeResolveEdramPitchTiles(),
          kXenosMsaaSamples_1X, false, 1u, 0u, XeResolveResolutionScale())
      >> 2u;
  uint i;
  [unroll] for (i = 0u; i < 4u; ++i) {
    xe_resolve_dest[address_int4s + i] = xe_resolve_clear_value.xyxy;
  }
}
