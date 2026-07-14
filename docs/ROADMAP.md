# Roadmap

## 1. Restore the rollback baseline

- return B210 `8002816` to MiniPC on USB3;
- reconcile the pinned OAI source and required SIB8 patch;
- rerun Ethernet CU/DU with all machine and phone gates;
- prove clean stop and repeatable rollback.

## 2. Close the Jetson phone-service blocker

- refresh live attach state after the active xHCI IRQ fix;
- separate PWS reception, 5G indication, PDU session, internet, and throughput;
- compare with the earlier 6.5–7.3 Mb/s result without treating it as current.

## 3. Prove canonical Quectel backhaul

- replace the monolithic-donor assumption with an independent donor DU;
- attach donor and access DUs to the same CU;
- prove inner F1 and outer WireGuard packet paths;
- rerun phone-visible service and Ethernet rollback.

## 4. Revalidate alternatives

- Pi Ethernet, then Wi-Fi GRE;
- X310 only after proving transport above 1 Gb/s for the 106-PRB branch;
- compare performance and power only after each scenario reaches the same
  acceptance boundary.
