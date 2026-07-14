# Architecture

## Objective

The lab studies an OAI 5G NR CU/DU split that broadcasts SIB8/PWS and carries
F1 over controlled IP transports. OAI source remains external and pinned;
repository-owned changes are feature-separated patches under `patches/`.

## Canonical split

- `serber-firecell` hosts the OAI 5GC and one shared CU.
- An independent donor DU provides the cell used only by the Quectel modem.
- The selected access DU hosts the local access-cell radio.
- The commercial phone attaches only to the access cell.

The shared CU must hold both F1 associations. A monolithic donor gNB has no F1
association and therefore cannot prove the target one-CU/two-DU design.

```text
                         +----------------------+
                         | serber-firecell      |
                         | OAI 5GC + shared CU  |
                         +----------+-----------+
                                    |
                   +----------------+----------------+
                   | F1                              | F1
            +------v-------+                  +------v-------+
            | donor DU     |                  | access DU    |
            | donor cell   |                  | local B210   |
            +------+-------+                  +------+-------+
                   |                                 |
             Quectel modem                     Nothing Phone
                   |
          WireGuard outer path
          carrying access-DU F1
```

## Access-DU identity

The MiniPC rollback profile uses B210 serial `8002816`, PCI `0`, TAC `1`, and
DU ID `0xe01`. Jetson uses DU ID `0xe02`. Physical radio ownership must be
checked before launch; USB enumeration alone is not proof that UHD can use the
radio.

## Transport modes

- Ethernet F1 is the canonical rollback path.
- Wi-Fi GRE is a historical working wireless candidate that needs a fresh rerun.
- Quectel/WireGuard is the target wireless F1 path and still needs proof with
  both donor and access DUs attached to the same CU.

## SIB8/PWS boundary

The CU constructs or triggers warning content, sends the F1AP warning request,
and the DU schedules the resulting system information. CU/DU log milestones
prove only the network-side path. Phone-visible warning reception is a separate
acceptance gate.
