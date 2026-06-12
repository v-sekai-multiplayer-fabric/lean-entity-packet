# entity_packet

The Lean 4 + Plausible source-of-truth for the fabric's 100-byte entity packet
(`XRGridEntityPacket`). The wire is fully integral — no floats — so it models
exactly in Lean, and Plausible roundtrip properties find codec gaps in seconds
instead of an engine rebuild.

## Layout (100 bytes, all integral)

| offset | field | encoding |
| --- | --- | --- |
| 0 | global_id | u32 |
| 4 | position x/y/z | **int64 absolute micrometers** (no origin shift) |
| 28 | velocity x/y/z | i16, scaled to ±`PBVH_V_MAX_PHYSICAL_DEFAULT` (500000 μm/tick) |
| 40 | hlc | u32 (frame<<8 \| counter) |
| 44 | class\|owner | u32 |
| 48 | sub_index | u32 |
| 52 | rotation | i16 swing-twist ×3 |
| 58 | payload | 42 bytes userdata (cmd/action/state/name) |

Position int64 μm is the integral twin of the `precision=double` large-world
coordinate, and matches the Lean-proved predictive BVH's int64-μm AABB space
(`lean-predictive-bvh`, kept in sync). Velocity shares the BVH's `V_MAX` scale.

## Verify

```sh
lake exe packet_demo    # Plausible roundtrip + size, 50000-vector sweep
lake exe packet_emit    # writes packet_golden.csv (Lean canonical bytes)
# differential: the engine's C++ XRGridEntityPacket.decode must match
godot --headless --script packet_diff.gd   # PACKET DIFFERENTIAL PASS
```

Verified: Plausible clean + 50000/50000 roundtrip; C++ decode matches the spec
on 64 golden vectors.
