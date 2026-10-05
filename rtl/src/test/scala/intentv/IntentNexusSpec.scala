package intentv

import chisel3._
import chiseltest._
import org.scalatest.flatspec.AnyFlatSpec

class IntentNexusSpec extends AnyFlatSpec with ChiselScalatestTester {
  "IntentNexus" should "output the low 32 bits of the product only when bound" in {
    test(new IntentNexus) { c =>
      c.io.rawIntent.poke(6.U)
      c.io.information.poke(7.U)
      c.io.passionBound.poke(false.B)
      c.io.emergentStructure.expect(0.U)
      c.io.passionBound.poke(true.B)
      c.io.emergentStructure.expect(42.U)

      c.io.rawIntent.poke("hffffffff".U)
      c.io.information.poke(2.U)
      c.io.emergentStructure.expect("hfffffffe".U) // truncated
    }
  }

  it should "count idle cycles, saturate at 255, and clear when bound" in {
    test(new IntentNexus) { c =>
      c.io.passionBound.poke(false.B)
      c.clock.step(3)
      c.io.systemEntropy.expect(3.U)
      c.clock.step(300)
      c.io.systemEntropy.expect(255.U)
      c.io.passionBound.poke(true.B)
      c.clock.step(1)
      c.io.systemEntropy.expect(0.U)
    }
  }
}

class CcuMmioSpec extends AnyFlatSpec with ChiselScalatestTester {
  private def write(c: CcuMmio, a: Int, d: BigInt): Unit = {
    c.io.addr.poke(a.U); c.io.wdata.poke(d.U); c.io.wen.poke(true.B)
    c.clock.step(1); c.io.wen.poke(false.B)
  }
  private def read(c: CcuMmio, a: Int): BigInt = {
    c.io.addr.poke(a.U); c.io.rdata.peekInt()
  }

  "CcuMmio" should "multiply through the register interface" in {
    test(new CcuMmio) { c =>
      write(c, 0x00, 1000); write(c, 0x04, 1000)
      assert(read(c, 0x0C) == 0)        // not bound yet
      write(c, 0x08, 1)
      assert(read(c, 0x0C) == 1000000)
      write(c, 0x08, 0)
      assert(read(c, 0x0C) == 0)
    }
  }

  it should "ignore writes to read-only registers" in {
    test(new CcuMmio) { c =>
      write(c, 0x0C, 123); write(c, 0x10, 123)
      assert(read(c, 0x0C) == 0)
    }
  }
}
