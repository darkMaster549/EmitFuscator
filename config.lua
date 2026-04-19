-- You can Control here the passes/noise/sep/ofct/mrk/mxps --
return {
    sep = "Q",
    offset = 90000,
    marker = "LOL!", -- you can change this for your own marker
    max_passes = 2, -- don't change this or Obfuscted code might not work Change it in pipeline maximum is only 2 don't increase it --
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
