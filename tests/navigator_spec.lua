vim.opt.runtimepath:append(vim.fn.getcwd())

local navigator = require("tuios-nvim-navigator")
local boundary = {}
navigator.setup({
	keymaps = {},
	on_boundary = function(direction)
		table.insert(boundary, direction)
	end,
})

local events = {}
for _, autocmd in ipairs(vim.api.nvim_get_autocmds({ group = "TuiosNvimNavigator" })) do
	events[autocmd.event] = true
end
assert(events.VimResume, "VimResume should reannounce navigator state")
assert(events.FocusGained, "FocusGained should reannounce navigator state")

vim.cmd("vnew")
local windows = vim.api.nvim_tabpage_list_wins(0)
vim.api.nvim_set_current_win(windows[#windows])

navigator.navigate("left")
assert(#boundary == 0, "a Neovim split should handle left navigation")

navigator.navigate("left")
assert(vim.deep_equal(boundary, { "left" }), "a Neovim edge should signal TUIOS")
