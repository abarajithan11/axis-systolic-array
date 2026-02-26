package chipyard

import org.chipsalliance.cde.config.Config
import chipyard.my_axi_ip.{MyAxiIPKey, MyAxiIPParams}

class WithMyAxiIP(params: MyAxiIPParams = MyAxiIPParams()) extends Config((site, here, up) => {
  case MyAxiIPKey => Some(params)
})

class SmallBoomMyAxiIPConfig extends Config(
  new WithMyAxiIP() ++
  new SmallBoomConfig
)
