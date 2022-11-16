command! -nargs=* SwapSplit lua require("swap-split").swap()

highlight SwapSplitStatusLine gui=bold guifg=#151515 guibg=#e1af6a
