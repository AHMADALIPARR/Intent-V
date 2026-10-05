package intentv

import chisel3._
import chisel3.util._

/** Minimal memory-mapped register interface for [[IntentNexus]].
  *
  * Offsets from the CCU base (must match firmware/src/ccu.zig):
  *   0x00 raw_intent         RW
  *   0x04 information        RW
  *   0x08 passion_bound      RW (bit 0)
  *   0x0C emergent_structure RO
  *   0x10 system_entropy     RO (bits 7:0)
  *
  * Single-cycle, no wait states. Reads are combinational. Unmapped reads
  * return 0; writes to read-only or unmapped offsets are ignored.
  */
class CcuMmio extends Module {
  val io = IO(new Bundle {
    val addr  = Input(UInt(8.W))
    val wdata = Input(UInt(32.W))
    val wen   = Input(Bool())
    val rdata = Output(UInt(32.W))
  })

  val nexus  = Module(new IntentNexus)
  val intent = RegInit(0.U(32.W))
  val info   = RegInit(0.U(32.W))
  val bound  = RegInit(false.B)

  when(io.wen) {
    switch(io.addr) {
      is(0x00.U) { intent := io.wdata }
      is(0x04.U) { info := io.wdata }
      is(0x08.U) { bound := io.wdata(0) }
    }
  }

  nexus.io.rawIntent    := intent
  nexus.io.information  := info
  nexus.io.passionBound := bound

  io.rdata := 0.U
  switch(io.addr) {
    is(0x00.U) { io.rdata := intent }
    is(0x04.U) { io.rdata := info }
    is(0x08.U) { io.rdata := bound.asUInt }
    is(0x0C.U) { io.rdata := nexus.io.emergentStructure }
    is(0x10.U) { io.rdata := nexus.io.systemEntropy }
  }
}

object Elaborate extends App {
  (new chisel3.stage.ChiselStage).emitVerilog(new CcuMmio, Array("--target-dir", "generated"))
}
