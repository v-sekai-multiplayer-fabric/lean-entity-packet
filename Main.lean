import EntityPacket.Codec
import Plausible
open EntityPacket Plausible

/-- Build a packet from integer seeds (Plausible drives `n`). -/
def mk (n : Nat) : Packet :=
  let f : Nat → Int64 := fun k => Int64.ofInt (Int.ofNat ((n * 2654435761 + k * 40503) % 4000000000) - 2000000000)
  let g : Nat → Int16 := fun k => Int16.ofInt (Int.ofNat ((n + k) % 65535) - 32767)
  let u : Nat → UInt32 := fun k => UInt32.ofNat ((n * 7 + k) % 4294967296)
  { gid := u 1
    posUm := (f 0, f 1, f 2)
    vel := (g 0, g 1, g 2)
    hlc := u 2
    classOwner := u 3
    subIndex := u 4
    rot := (g 3, g 4, g 5)
    payload := (Array.range PAYLOAD_LEN).map (fun i => UInt8.ofNat ((n + i*31) % 256)) }

/-- The roundtrip property: decode ∘ encode = id on every field.
    This is the property that would have caught the missing payload write. -/
def roundtrips (n : Nat) : Bool :=
  let p := mk n
  let d := decode (encode p)
  d.gid == p.gid
    && d.posUm == p.posUm
    && d.vel == p.vel
    && d.hlc == p.hlc
    && d.classOwner == p.classOwner
    && d.subIndex == p.subIndex
    && d.rot == p.rot
    && d.payload == p.payload

/-- The packet is always exactly 100 bytes. -/
def sizeInvariant (n : Nat) : Bool := (encode (mk n)).size == SIZE

#eval Testable.check (∀ n : Nat, roundtrips n = true)
#eval Testable.check (∀ n : Nat, sizeInvariant n = true)

def main : IO Unit := do
  let mut bad := 0
  for n in [0:50000] do
    if roundtrips n && sizeInvariant n then pure () else bad := bad + 1
  IO.println s!"entity packet codec: {50000 - bad}/50000 roundtrip+size, {bad} gaps"
