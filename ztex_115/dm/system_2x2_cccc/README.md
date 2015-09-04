2x2 CCCC Design for the ZTEX 1.15b/d Boards
===========================================

This is a sample system with 4 compute tiles, a mesh network, debug support and
a connection to a host PC using USB 2.0. It supports the ZTEX 1.15b/d boards.


GLIP Sources
------------
This design contains the GLIP communication interface. To update to a newer
version, copy

    GLIP_SRC/src/backend_cypressfx2/logic/verilog/glip_cypressfx2_toplevel.v
    GLIP_SRC/src/backend_cypressfx2/logic/boards/ztex_115/fx2.ucf
    GLIP_SRC/src/backend_cypressfx2/logic/boards/ztex_115/fx2.sdc

into this directory.

