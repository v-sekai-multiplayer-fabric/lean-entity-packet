namespace EntityPacket

/-- The 100-byte fabric entity packet, modelled exactly as the C++
    (`XRGridEntityPacket`). Every field is integral — the wire has no floats.
    This Lean spec is the source of truth the C++ must match; Plausible
    roundtrip properties find codec gaps without an engine rebuild. -/

def SIZE : Nat := 100
def PAYLOAD_OFFSET : Nat := 58
def PAYLOAD_LEN : Nat := SIZE - PAYLOAD_OFFSET   -- 42

abbrev Bytes := Array UInt8

/-- little-endian put/get for the widths the packet uses. -/
def putU32 (b : Bytes) (off : Nat) (v : UInt32) : Bytes := Id.run do
  let mut b := b
  for i in [0:4] do
    b := b.set! (off + i) (((v >>> (UInt32.ofNat (i*8))) &&& 0xFF).toUInt8)
  return b
def getU32 (b : Bytes) (off : Nat) : UInt32 := Id.run do
  let mut v : UInt32 := 0
  for i in [0:4] do
    v := v ||| ((b[off+i]!).toUInt32 <<< (UInt32.ofNat (i*8)))
  return v

def putI64 (b : Bytes) (off : Nat) (v : Int64) : Bytes := Id.run do
  let u : UInt64 := v.toUInt64
  let mut b := b
  for i in [0:8] do
    b := b.set! (off + i) (((u >>> (UInt64.ofNat (i*8))) &&& 0xFF).toUInt8)
  return b
def getI64 (b : Bytes) (off : Nat) : Int64 := Id.run do
  let mut u : UInt64 := 0
  for i in [0:8] do
    u := u ||| ((b[off+i]!).toUInt64 <<< (UInt64.ofNat (i*8)))
  return u.toInt64

def putI16 (b : Bytes) (off : Nat) (v : Int16) : Bytes := Id.run do
  let u : UInt16 := v.toUInt16
  let b := b.set! off ((u &&& 0xFF).toUInt8)
  b.set! (off+1) (((u >>> 8) &&& 0xFF).toUInt8)
def getI16 (b : Bytes) (off : Nat) : Int16 :=
  (((b[off]!).toUInt16) ||| ((b[off+1]!).toUInt16 <<< 8)).toInt16

/-- An entity envelope's integral fields (position already in μm). -/
structure Packet where
  gid       : UInt32
  posUm     : Int64 × Int64 × Int64   -- absolute micrometers
  vel       : Int16 × Int16 × Int16   -- PBVH-scaled i16
  hlc       : UInt32
  classOwner: UInt32                   -- (class<<24)|owner
  subIndex  : UInt32
  rot       : Int16 × Int16 × Int16    -- swing-twist
  payload   : Bytes                    -- 42 bytes
  deriving Repr

def encode (p : Packet) : Bytes := Id.run do
  let mut b : Bytes := Array.replicate SIZE 0
  b := putU32 b 0 p.gid
  b := putI64 b 4 p.posUm.1
  b := putI64 b 12 p.posUm.2.1
  b := putI64 b 20 p.posUm.2.2
  b := putI16 b 28 p.vel.1
  b := putI16 b 30 p.vel.2.1
  b := putI16 b 32 p.vel.2.2
  b := putU32 b 40 p.hlc
  b := putU32 b 44 p.classOwner
  b := putU32 b 48 p.subIndex
  b := putI16 b 52 p.rot.1
  b := putI16 b 54 p.rot.2.1
  b := putI16 b 56 p.rot.2.2
  for i in [0:PAYLOAD_LEN] do
    if h : i < p.payload.size then
      b := b.set! (PAYLOAD_OFFSET + i) (p.payload[i]!)
  return b

def decode (b : Bytes) : Packet :=
  { gid := getU32 b 0
    posUm := (getI64 b 4, getI64 b 12, getI64 b 20)
    vel := (getI16 b 28, getI16 b 30, getI16 b 32)
    hlc := getU32 b 40
    classOwner := getU32 b 44
    subIndex := getU32 b 48
    rot := (getI16 b 52, getI16 b 54, getI16 b 56)
    payload := (Array.range PAYLOAD_LEN).map (fun i => b[PAYLOAD_OFFSET + i]!) }

end EntityPacket
