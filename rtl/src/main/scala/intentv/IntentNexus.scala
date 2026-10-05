package intentv

import chisel3._

/** Conscious Coherence Unit (CCU) core.
  *
  * What it actually is: a 32x32 -> low-32 multiplier gated by an enable, plus
  * an 8-bit saturating idle-cycle counter. The thematic names are aliases:
  *
  *   rawIntent / information -> the two multiplier operands
  *   passionBound            -> output enable (also clears the counter)
  *   emergentStructure       -> product (low 32 bits) when enabled, else 0
  *   systemEntropy           -> cycles since passionBound was last asserted
  *                              (saturates at 255)
  */
class IntentNexus extends Module {
  val io = IO(new Bundle {
    val rawIntent         = Input(UInt(32.W))
    val information       = Input(UInt(32.W))
    val passionBound      = Input(Bool())
    val emergentStructure = Output(UInt(32.W))
    val systemEntropy     = Output(UInt(8.W))
  })

  // Chisel's `*` widens to 64 bits; keep the low 32 (wraps on overflow).
  val coreDynamic = (io.rawIntent * io.information)(31, 0)

  // Not high-impedance: the output is driven to 0 when not enabled.
  io.emergentStructure := Mux(io.passionBound, coreDynamic, 0.U)

  val entropyReg = RegInit(0.U(8.W))
  entropyReg := Mux(io.passionBound, 0.U, Mux(entropyReg === 255.U, entropyReg, entropyReg + 1.U))
  io.systemEntropy := entropyReg
}
