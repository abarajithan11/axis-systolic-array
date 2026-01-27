package chipyard.my_axi_ip

import chisel3._
import chisel3.experimental.IntParam
import chisel3.util.HasBlackBoxResource

import org.chipsalliance.cde.config.Parameters

import freechips.rocketchip.amba.axi4._
import freechips.rocketchip.diplomacy._
import freechips.rocketchip.prci._
import freechips.rocketchip.subsystem.BaseSubsystem
import freechips.rocketchip.tilelink._

/** BlackBox wrapper for the Verilog module named by pIp.verilogTop. */
class MyAxiIPTopBlackBox(pIp: MyAxiIPParams)
  extends BlackBox(Map(
    "AXI_WIDTH"      -> IntParam(pIp.axiDataBits),
    "AXIL_WIDTH"     -> IntParam(pIp.axiDataBits),
    "ADDR_WIDTH"     -> IntParam(pIp.axiAddrBits),
    "AXI_ID_WIDTH"   -> IntParam(pIp.axiIdBits),
    "AXIL_BASE_ADDR" -> IntParam(pIp.baseAddress)
  )) with HasBlackBoxResource {

  override def desiredName: String = pIp.verilogTop

  private val ID_W = pIp.axiIdBits
  private val A_W  = pIp.axiAddrBits
  private val D_W  = pIp.axiDataBits
  private val S_W  = pIp.axiDataBits / 8

  val io = IO(new Bundle {
    val clk  = Input(Clock())
    val rstn = Input(Bool())

    // AXI slave (MMIO/config)
    val s_axi_awid    = Input(UInt(ID_W.W))
    val s_axi_awaddr  = Input(UInt(A_W.W))
    val s_axi_awlen   = Input(UInt(8.W))
    val s_axi_awsize  = Input(UInt(3.W))
    val s_axi_awburst = Input(UInt(2.W))
    val s_axi_awlock  = Input(Bool())
    val s_axi_awcache = Input(UInt(4.W))
    val s_axi_awprot  = Input(UInt(3.W))
    val s_axi_awvalid = Input(Bool())
    val s_axi_awready = Output(Bool())

    val s_axi_wdata   = Input(UInt(D_W.W))
    val s_axi_wstrb   = Input(UInt(S_W.W))
    val s_axi_wlast   = Input(Bool())
    val s_axi_wvalid  = Input(Bool())
    val s_axi_wready  = Output(Bool())

    val s_axi_bid     = Output(UInt(ID_W.W))
    val s_axi_bresp   = Output(UInt(2.W))
    val s_axi_bvalid  = Output(Bool())
    val s_axi_bready  = Input(Bool())

    val s_axi_arid    = Input(UInt(ID_W.W))
    val s_axi_araddr  = Input(UInt(A_W.W))
    val s_axi_arlen   = Input(UInt(8.W))
    val s_axi_arsize  = Input(UInt(3.W))
    val s_axi_arburst = Input(UInt(2.W))
    val s_axi_arlock  = Input(Bool())
    val s_axi_arcache = Input(UInt(4.W))
    val s_axi_arprot  = Input(UInt(3.W))
    val s_axi_arvalid = Input(Bool())
    val s_axi_arready = Output(Bool())

    val s_axi_rid     = Output(UInt(ID_W.W))
    val s_axi_rdata   = Output(UInt(D_W.W))
    val s_axi_rresp   = Output(UInt(2.W))
    val s_axi_rlast   = Output(Bool())
    val s_axi_rvalid  = Output(Bool())
    val s_axi_rready  = Input(Bool())

    // 3x read masters: AR/R only
    def mm2sBundle = new Bundle {
      val arid    = Output(UInt(ID_W.W))
      val araddr  = Output(UInt(A_W.W))
      val arlen   = Output(UInt(8.W))
      val arsize  = Output(UInt(3.W))
      val arburst = Output(UInt(2.W))
      val arlock  = Output(Bool())
      val arcache = Output(UInt(4.W))
      val arprot  = Output(UInt(3.W))
      val arvalid = Output(Bool())
      val arready = Input(Bool())

      val rid     = Input(UInt(ID_W.W))
      val rdata   = Input(UInt(D_W.W))
      val rresp   = Input(UInt(2.W))
      val rlast   = Input(Bool())
      val rvalid  = Input(Bool())
      val rready  = Output(Bool())
    }

    val m_axi_mm2s_0 = mm2sBundle
    val m_axi_mm2s_1 = mm2sBundle
    val m_axi_mm2s_2 = mm2sBundle

    // write master: AW/W/B only
    val m_axi_s2mm_awid    = Output(UInt(ID_W.W))
    val m_axi_s2mm_awaddr  = Output(UInt(A_W.W))
    val m_axi_s2mm_awlen   = Output(UInt(8.W))
    val m_axi_s2mm_awsize  = Output(UInt(3.W))
    val m_axi_s2mm_awburst = Output(UInt(2.W))
    val m_axi_s2mm_awlock  = Output(Bool())
    val m_axi_s2mm_awcache = Output(UInt(4.W))
    val m_axi_s2mm_awprot  = Output(UInt(3.W))
    val m_axi_s2mm_awvalid = Output(Bool())
    val m_axi_s2mm_awready = Input(Bool())

    val m_axi_s2mm_wdata   = Output(UInt(D_W.W))
    val m_axi_s2mm_wstrb   = Output(UInt(S_W.W))
    val m_axi_s2mm_wlast   = Output(Bool())
    val m_axi_s2mm_wvalid  = Output(Bool())
    val m_axi_s2mm_wready  = Input(Bool())

    val m_axi_s2mm_bid     = Input(UInt(ID_W.W))
    val m_axi_s2mm_bresp   = Input(UInt(2.W))
    val m_axi_s2mm_bvalid  = Input(Bool())
    val m_axi_s2mm_bready  = Output(Bool())
  })

  addResource(pIp.resourcePath)
}

class MyAxiIPWrapper(pIp: MyAxiIPParams) extends Module {
  private val axiParams = AXI4BundleParameters(
    addrBits       = pIp.axiAddrBits,
    dataBits       = pIp.axiDataBits,
    idBits         = pIp.axiIdBits,
    echoFields     = Nil,
    requestFields  = Nil,
    responseFields = Nil
  )

  val io = IO(new Bundle {
    val s_axi        = Flipped(new AXI4Bundle(axiParams))
    val m_axi_mm2s_0 = new AXI4Bundle(axiParams)
    val m_axi_mm2s_1 = new AXI4Bundle(axiParams)
    val m_axi_mm2s_2 = new AXI4Bundle(axiParams)
    val m_axi_s2mm   = new AXI4Bundle(axiParams)
  })

  val bb = Module(new MyAxiIPTopBlackBox(pIp))
  bb.io.clk  := clock
  bb.io.rstn := !reset.asBool

  private def zero[T <: Data](x: T): T = 0.U.asTypeOf(x)

  // slave
  bb.io.s_axi_awlock  := false.B
  bb.io.s_axi_arlock  := false.B

  bb.io.s_axi_awid    := io.s_axi.aw.bits.id
  bb.io.s_axi_awaddr  := io.s_axi.aw.bits.addr
  bb.io.s_axi_awlen   := io.s_axi.aw.bits.len
  bb.io.s_axi_awsize  := io.s_axi.aw.bits.size
  bb.io.s_axi_awburst := io.s_axi.aw.bits.burst
  bb.io.s_axi_awcache := io.s_axi.aw.bits.cache
  bb.io.s_axi_awprot  := io.s_axi.aw.bits.prot
  bb.io.s_axi_awvalid := io.s_axi.aw.valid
  io.s_axi.aw.ready   := bb.io.s_axi_awready

  bb.io.s_axi_wdata   := io.s_axi.w.bits.data
  bb.io.s_axi_wstrb   := io.s_axi.w.bits.strb
  bb.io.s_axi_wlast   := io.s_axi.w.bits.last
  bb.io.s_axi_wvalid  := io.s_axi.w.valid
  io.s_axi.w.ready    := bb.io.s_axi_wready

  io.s_axi.b.bits      := zero(io.s_axi.b.bits)
  io.s_axi.b.bits.id   := bb.io.s_axi_bid
  io.s_axi.b.bits.resp := bb.io.s_axi_bresp
  io.s_axi.b.valid     := bb.io.s_axi_bvalid
  bb.io.s_axi_bready   := io.s_axi.b.ready

  bb.io.s_axi_arid    := io.s_axi.ar.bits.id
  bb.io.s_axi_araddr  := io.s_axi.ar.bits.addr
  bb.io.s_axi_arlen   := io.s_axi.ar.bits.len
  bb.io.s_axi_arsize  := io.s_axi.ar.bits.size
  bb.io.s_axi_arburst := io.s_axi.ar.bits.burst
  bb.io.s_axi_arcache := io.s_axi.ar.bits.cache
  bb.io.s_axi_arprot  := io.s_axi.ar.bits.prot
  bb.io.s_axi_arvalid := io.s_axi.ar.valid
  io.s_axi.ar.ready   := bb.io.s_axi_arready

  io.s_axi.r.bits      := zero(io.s_axi.r.bits)
  io.s_axi.r.bits.id   := bb.io.s_axi_rid
  io.s_axi.r.bits.data := bb.io.s_axi_rdata
  io.s_axi.r.bits.resp := bb.io.s_axi_rresp
  io.s_axi.r.bits.last := bb.io.s_axi_rlast
  io.s_axi.r.valid     := bb.io.s_axi_rvalid
  bb.io.s_axi_rready   := io.s_axi.r.ready

  private def tieOffWrite(m: AXI4Bundle): Unit = {
    m.aw.valid := false.B; m.aw.bits := zero(m.aw.bits)
    m.w.valid  := false.B; m.w.bits  := zero(m.w.bits)
    m.b.ready  := true.B
  }
  private def tieOffRead(m: AXI4Bundle): Unit = {
    m.ar.valid := false.B; m.ar.bits := zero(m.ar.bits)
    m.r.ready  := false.B
  }

  tieOffWrite(io.m_axi_mm2s_0)
  tieOffWrite(io.m_axi_mm2s_1)
  tieOffWrite(io.m_axi_mm2s_2)
  tieOffRead(io.m_axi_s2mm)

  // mm2s_0
  io.m_axi_mm2s_0.ar.bits := zero(io.m_axi_mm2s_0.ar.bits)
  io.m_axi_mm2s_0.ar.bits.id    := bb.io.m_axi_mm2s_0.arid
  io.m_axi_mm2s_0.ar.bits.addr  := bb.io.m_axi_mm2s_0.araddr
  io.m_axi_mm2s_0.ar.bits.len   := bb.io.m_axi_mm2s_0.arlen
  io.m_axi_mm2s_0.ar.bits.size  := bb.io.m_axi_mm2s_0.arsize
  io.m_axi_mm2s_0.ar.bits.burst := bb.io.m_axi_mm2s_0.arburst
  io.m_axi_mm2s_0.ar.bits.cache := bb.io.m_axi_mm2s_0.arcache
  io.m_axi_mm2s_0.ar.bits.prot  := bb.io.m_axi_mm2s_0.arprot
  io.m_axi_mm2s_0.ar.valid      := bb.io.m_axi_mm2s_0.arvalid
  bb.io.m_axi_mm2s_0.arready    := io.m_axi_mm2s_0.ar.ready

  bb.io.m_axi_mm2s_0.rid    := io.m_axi_mm2s_0.r.bits.id
  bb.io.m_axi_mm2s_0.rdata  := io.m_axi_mm2s_0.r.bits.data
  bb.io.m_axi_mm2s_0.rresp  := io.m_axi_mm2s_0.r.bits.resp
  bb.io.m_axi_mm2s_0.rlast  := io.m_axi_mm2s_0.r.bits.last
  bb.io.m_axi_mm2s_0.rvalid := io.m_axi_mm2s_0.r.valid
  io.m_axi_mm2s_0.r.ready   := bb.io.m_axi_mm2s_0.rready

  // mm2s_1
  io.m_axi_mm2s_1.ar.bits := zero(io.m_axi_mm2s_1.ar.bits)
  io.m_axi_mm2s_1.ar.bits.id    := bb.io.m_axi_mm2s_1.arid
  io.m_axi_mm2s_1.ar.bits.addr  := bb.io.m_axi_mm2s_1.araddr
  io.m_axi_mm2s_1.ar.bits.len   := bb.io.m_axi_mm2s_1.arlen
  io.m_axi_mm2s_1.ar.bits.size  := bb.io.m_axi_mm2s_1.arsize
  io.m_axi_mm2s_1.ar.bits.burst := bb.io.m_axi_mm2s_1.arburst
  io.m_axi_mm2s_1.ar.bits.cache := bb.io.m_axi_mm2s_1.arcache
  io.m_axi_mm2s_1.ar.bits.prot  := bb.io.m_axi_mm2s_1.arprot
  io.m_axi_mm2s_1.ar.valid      := bb.io.m_axi_mm2s_1.arvalid
  bb.io.m_axi_mm2s_1.arready    := io.m_axi_mm2s_1.ar.ready

  bb.io.m_axi_mm2s_1.rid    := io.m_axi_mm2s_1.r.bits.id
  bb.io.m_axi_mm2s_1.rdata  := io.m_axi_mm2s_1.r.bits.data
  bb.io.m_axi_mm2s_1.rresp  := io.m_axi_mm2s_1.r.bits.resp
  bb.io.m_axi_mm2s_1.rlast  := io.m_axi_mm2s_1.r.bits.last
  bb.io.m_axi_mm2s_1.rvalid := io.m_axi_mm2s_1.r.valid
  io.m_axi_mm2s_1.r.ready   := bb.io.m_axi_mm2s_1.rready

  // mm2s_2
  io.m_axi_mm2s_2.ar.bits := zero(io.m_axi_mm2s_2.ar.bits)
  io.m_axi_mm2s_2.ar.bits.id    := bb.io.m_axi_mm2s_2.arid
  io.m_axi_mm2s_2.ar.bits.addr  := bb.io.m_axi_mm2s_2.araddr
  io.m_axi_mm2s_2.ar.bits.len   := bb.io.m_axi_mm2s_2.arlen
  io.m_axi_mm2s_2.ar.bits.size  := bb.io.m_axi_mm2s_2.arsize
  io.m_axi_mm2s_2.ar.bits.burst := bb.io.m_axi_mm2s_2.arburst
  io.m_axi_mm2s_2.ar.bits.cache := bb.io.m_axi_mm2s_2.arcache
  io.m_axi_mm2s_2.ar.bits.prot  := bb.io.m_axi_mm2s_2.arprot
  io.m_axi_mm2s_2.ar.valid      := bb.io.m_axi_mm2s_2.arvalid
  bb.io.m_axi_mm2s_2.arready    := io.m_axi_mm2s_2.ar.ready

  bb.io.m_axi_mm2s_2.rid    := io.m_axi_mm2s_2.r.bits.id
  bb.io.m_axi_mm2s_2.rdata  := io.m_axi_mm2s_2.r.bits.data
  bb.io.m_axi_mm2s_2.rresp  := io.m_axi_mm2s_2.r.bits.resp
  bb.io.m_axi_mm2s_2.rlast  := io.m_axi_mm2s_2.r.bits.last
  bb.io.m_axi_mm2s_2.rvalid := io.m_axi_mm2s_2.r.valid
  io.m_axi_mm2s_2.r.ready   := bb.io.m_axi_mm2s_2.rready

  // s2mm
  io.m_axi_s2mm.aw.bits := zero(io.m_axi_s2mm.aw.bits)
  io.m_axi_s2mm.aw.bits.id    := bb.io.m_axi_s2mm_awid
  io.m_axi_s2mm.aw.bits.addr  := bb.io.m_axi_s2mm_awaddr
  io.m_axi_s2mm.aw.bits.len   := bb.io.m_axi_s2mm_awlen
  io.m_axi_s2mm.aw.bits.size  := bb.io.m_axi_s2mm_awsize
  io.m_axi_s2mm.aw.bits.burst := bb.io.m_axi_s2mm_awburst
  io.m_axi_s2mm.aw.bits.cache := bb.io.m_axi_s2mm_awcache
  io.m_axi_s2mm.aw.bits.prot  := bb.io.m_axi_s2mm_awprot
  io.m_axi_s2mm.aw.valid      := bb.io.m_axi_s2mm_awvalid
  bb.io.m_axi_s2mm_awready    := io.m_axi_s2mm.aw.ready

  io.m_axi_s2mm.w.bits := zero(io.m_axi_s2mm.w.bits)
  io.m_axi_s2mm.w.bits.data := bb.io.m_axi_s2mm_wdata
  io.m_axi_s2mm.w.bits.strb := bb.io.m_axi_s2mm_wstrb
  io.m_axi_s2mm.w.bits.last := bb.io.m_axi_s2mm_wlast
  io.m_axi_s2mm.w.valid     := bb.io.m_axi_s2mm_wvalid
  bb.io.m_axi_s2mm_wready   := io.m_axi_s2mm.w.ready

  bb.io.m_axi_s2mm_bid    := io.m_axi_s2mm.b.bits.id
  bb.io.m_axi_s2mm_bresp  := io.m_axi_s2mm.b.bits.resp
  bb.io.m_axi_s2mm_bvalid := io.m_axi_s2mm.b.valid
  io.m_axi_s2mm.b.ready   := bb.io.m_axi_s2mm_bready
}

class MyAxiIP(pIp: MyAxiIPParams)(implicit p: Parameters) extends LazyModule {
  private val beatBytes = pIp.axiDataBits / 8

  val clockNode = ClockSinkNode(Seq(ClockSinkParameters()))

  val cfg = AXI4SlaveNode(Seq(
    AXI4SlavePortParameters(
      slaves = Seq(
        AXI4SlaveParameters(
          address       = Seq(AddressSet(pIp.baseAddress, pIp.cfgBytes - 1)),
          regionType    = RegionType.UNCACHED,
          executable    = false,
          supportsRead  = TransferSizes(1, beatBytes),
          supportsWrite = TransferSizes(1, beatBytes)
        )
      ),
      beatBytes = beatBytes
    )
  ))(ValName("my_axi_ip_cfg"))

  private def mport(name: String): AXI4MasterNode = {
    val idRange = IdRange(0, pIp.idCount)
    AXI4MasterNode(Seq(
      AXI4MasterPortParameters(
        masters = Seq(AXI4MasterParameters(
          name      = name,
          id        = idRange,
          maxFlight = Some(pIp.maxFlight),
          aligned   = true
        ))
      )
    ))(ValName(name))
  }

  val mm2s0 = mport("my_axi_ip_mm2s_0")
  val mm2s1 = mport("my_axi_ip_mm2s_1")
  val mm2s2 = mport("my_axi_ip_mm2s_2")
  val s2mm  = mport("my_axi_ip_s2mm")

  lazy val module = new LazyRawModuleImp(this) {
    val (cb, _) = clockNode.in(0)
    val ipClock = cb.clock
    val ipReset = cb.reset.asBool.asAsyncReset

    val w = withClockAndReset(ipClock, ipReset) { Module(new MyAxiIPWrapper(pIp)) }

    val (cfgIn, _) = cfg.in(0)
    w.io.s_axi <> cfgIn

    val (m0, _) = mm2s0.out(0); w.io.m_axi_mm2s_0 <> m0
    val (m1, _) = mm2s1.out(0); w.io.m_axi_mm2s_1 <> m1
    val (m2, _) = mm2s2.out(0); w.io.m_axi_mm2s_2 <> m2
    val (m3, _) = s2mm.out(0);  w.io.m_axi_s2mm   <> m3
  }
}

trait CanHavePeripheryMyAxiIP { this: BaseSubsystem =>
  p(MyAxiIPKey).foreach { params =>
    val ip = LazyModule(new MyAxiIP(params))

    ip.clockNode := this.sbus.fixedClockNode

    this.pbus.coupleTo("my_axi_ip_cfg") { bus =>
      ip.cfg :=
        AXI4UserYanker() :=
        AXI4Deinterleaver(params.maxBurstBytes) :=
        AXI4Buffer() :=                      // optional but recommended
        TLToAXI4() :=
        TLFragmenter(pbus.beatBytes, pbus.blockBytes, holdFirstDeny = true) :=
        bus
    }

    def attachMaster(name: String, n: AXI4MasterNode): Unit = {
      this.sbus.coupleFrom(name) { tl =>
        tl :=
          TLBuffer() :=
          AXI4ToTL() :=
          AXI4UserYanker(capMaxFlight = Some(params.maxFlight)) :=
          AXI4Fragmenter() :=
          n
      }
    }

    attachMaster("my_axi_ip_mm2s_0", ip.mm2s0)
    attachMaster("my_axi_ip_mm2s_1", ip.mm2s1)
    attachMaster("my_axi_ip_mm2s_2", ip.mm2s2)
    attachMaster("my_axi_ip_s2mm",   ip.s2mm)
  }
}
