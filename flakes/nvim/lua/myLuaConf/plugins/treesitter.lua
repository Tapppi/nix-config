-- [[ Configure Treesitter ]]
-- See `:help nvim-treesitter`

local keymap = require("myLuaConf.keymap")

local function enable_treesitter(bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) or vim.bo[bufnr].buftype ~= "" then
    return
  end

  local ok = pcall(vim.treesitter.start, bufnr)
  if not ok then
    return
  end

  vim.bo[bufnr].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
end

local function setup_incremental_selection(mappings)
  local selection_state = {}

  local function get_node_chain()
    local node = vim.treesitter.get_node()
    if not node then
      return nil
    end

    local chain = {}
    while node do
      table.insert(chain, node)
      node = node:parent()
    end

    return chain
  end

  local function select_node(node)
    local start_row, start_col, end_row, end_col = node:range()

    vim.fn.setpos("'<", { 0, start_row + 1, start_col + 1, 0 })
    vim.fn.setpos("'>", { 0, end_row + 1, math.max(end_col, 1), 0 })
    vim.cmd.normal({ args = { "gv" }, bang = true })
  end

  local function set_selection(index)
    local bufnr = vim.api.nvim_get_current_buf()
    local state = selection_state[bufnr]
    if not state or not state.nodes[index] then
      return
    end

    state.index = index
    select_node(state.nodes[index])
  end

  local function init_selection()
    local bufnr = vim.api.nvim_get_current_buf()
    local nodes = get_node_chain()
    if not nodes then
      return
    end

    selection_state[bufnr] = { nodes = nodes, index = 1 }
    set_selection(1)
  end

  local function expand_selection()
    local bufnr = vim.api.nvim_get_current_buf()
    local state = selection_state[bufnr]
    if not state then
      init_selection()
      return
    end

    set_selection(math.min(state.index + 1, #state.nodes))
  end

  local function shrink_selection()
    local bufnr = vim.api.nvim_get_current_buf()
    local state = selection_state[bufnr]
    if not state then
      return
    end

    set_selection(math.max(state.index - 1, 1))
  end

  vim.keymap.set("n", mappings.init_selection, init_selection, { desc = "Treesitter: Init selection" })
  vim.keymap.set({ "x", "o" }, mappings.node_incremental, expand_selection, { desc = "Treesitter: Expand selection" })
  vim.keymap.set(
    { "x", "o" },
    mappings.scope_incremental,
    expand_selection,
    { desc = "Treesitter: Expand selection scope" }
  )
  vim.keymap.set({ "x", "o" }, mappings.node_decremental, shrink_selection, { desc = "Treesitter: Shrink selection" })
end

return {
  {
    "nvim-treesitter",
    for_cat = "general.treesitter",
    event = "DeferredUIEnter",
    load = function(name)
      vim.cmd.packadd({ args = { name } })
      vim.cmd.packadd({ args = { "nvim-treesitter-textobjects" } })
    end,
    after = function()
      -- [[ Configure Treesitter ]]
      -- See `:help nvim-treesitter`
      local treesitter_keymaps = keymap.get_treesitter_keymaps()
      require("nvim-treesitter").setup()
      require("nvim-treesitter-textobjects").setup(treesitter_keymaps.textobjects)
      setup_incremental_selection(treesitter_keymaps.incremental_selection.keymaps)

      local group = vim.api.nvim_create_augroup("my-treesitter", { clear = true })
      vim.api.nvim_create_autocmd("FileType", {
        group = group,
        callback = function(args)
          enable_treesitter(args.buf)
        end,
      })

      for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
        enable_treesitter(bufnr)
      end
    end,
  },
}
