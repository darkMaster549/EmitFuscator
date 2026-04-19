-- You can Control here the passes/noise/sep/ofct/mrk/mxps --
return {
    sep = "Q",
    offset = 90000,
    marker = "LOL!", -- you can change this for your own marker
    max_passes = 2,
    passes = {
        rename    = true,
        strings   = true,
        numbers   = true,
        deadcode  = true,
        flatten   = true,
    },
    noise = {
        multiplier = 0.5,
        min        = 80,
        block_size = 150,
    },
}
