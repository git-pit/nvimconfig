Local copy of [theHamsta/nvim-dap-virtual-text](https://github.com/theHamsta/nvim-dap-virtual-text)
at commit `fbdb48c2ed45f4a8293d0d483f7730d24467ccb6`.

The scope check in `lua/nvim-dap-virtual-text/virtual_text.lua` uses the stopped
frame's column, falling back to the first nonblank column. The upstream code
checks column zero, which incorrectly excludes variables declared in indented
`for` headers when execution stops on the header.
