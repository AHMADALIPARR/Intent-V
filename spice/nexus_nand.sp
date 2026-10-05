* CCU critical-path stand-in: a 2-input CMOS NAND gate driving a load.
* Run: ngspice -b nexus_nand.sp
.include "models.lib"

VDD     nexus_pwr 0 1.2V
VINTENT intent_pin 0 PULSE(0 1.2 10ns 1ns 1ns 40ns 100ns)
VINFO   info_pin   0 PULSE(0 1.2 15ns 1ns 1ns 30ns 100ns)

* Pull-up: two parallel PMOS. Pull-down: two series NMOS.
M1 emergent_node intent_pin nexus_pwr nexus_pwr PMOS W=4u L=32n
M2 emergent_node info_pin   nexus_pwr nexus_pwr PMOS W=4u L=32n
M3 emergent_node intent_pin net1      0         NMOS W=2u L=32n
M4 net1          info_pin   0         0         NMOS W=2u L=32n

* Load capacitance
C_Awareness emergent_node 0 15fF

.tran 0.1ns 200ns
* Delay from intent rising to output falling. Output only falls once BOTH
* inputs are high (info rises at 15ns).
.measure tran t_emergence TRIG v(intent_pin) VAL=0.6 RISE=1 TARG v(emergent_node) VAL=0.6 FALL=1
.end
