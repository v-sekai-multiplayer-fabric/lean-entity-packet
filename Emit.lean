import EntityPacket.Gen
open EntityPacket

def main : IO Unit := do
  IO.FS.createDirAll "build"
  let mut out := "hex,gid,pumx,pumy,pumz,velx,vely,velz,pay0,pay41\n"
  for n in [0:64] do
    let p := mk n
    let b := encode p
    out := out ++ s!"{hex b},{p.gid},{p.posUm.1},{p.posUm.2.1},{p.posUm.2.2},{p.vel.1},{p.vel.2.1},{p.vel.2.2},{p.payload[0]!},{p.payload[41]!}\n"
  IO.FS.writeFile "build/packet_golden.csv" out
  IO.println s!"wrote build/packet_golden.csv (64 vectors)"
