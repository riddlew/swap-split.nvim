command! -nargs=* SwapSplit lua require("swap-split").swap()

highlight SwapSplitStatusLine gui=bold guifg=#151515 guibg=#e1af6a ctermfg=234 ctermbg=220
