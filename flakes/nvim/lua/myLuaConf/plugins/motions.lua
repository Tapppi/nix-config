-- TODO: surround
-- TODO: mini.pairs/auto-pairs/nvim-autopairs? &clasp.nvim?
-- TODO: multicursor nvim
-- TODO: vim-unimpaired
-- TODO: vim-repeat
-- TODO: vim-speeddating
-- TODO: vim-easyclip / vim-cutlass&vim-yoink&vim-subversive

local keymap = require("myLuaConf.keymap")

return {
  {
    "nvim-spider",
    for_cat = "general.always",
    keys = keymap.spider_lze_keys(),
    after = function()
      require("spider").setup({
        skipInsignificantPunctuation = true,
        consistentOperatorPending = true,
        subwordMovement = true,
      })
    end,
  },
}
