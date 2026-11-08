vim.opt.runtimepath:append(vim.fn.getcwd())

local navigator = require("tuios-nvim-navigator")
local boundary = {}

-- Without an attached UI nothing may go to stdout: `nvim --headless ... | cmd`
-- would otherwise get the escape sequence as part of its output.
local real_stdout = io.stdout
local written = {}
io.stdout = {
	write = function(_, s)
		table.insert(written, s)
	end,
	flush = function() end,
}
navigator.setup({
	keymaps = {},
	on_boundary = function(direction)
		table.insert(boundary, direction)
	end,
})
io.stdout = real_stdout
assert(#written == 0, "setup without a UI should not write to stdout")

local events = {}
for _, autocmd in ipairs(vim.api.nvim_get_autocmds({ group = "TuiosNvimNavigator" })) do
	events[autocmd.event] = true
end
assert(events.UIEnter, "UIEnter should announce navigator state once the TUI attaches")
assert(events.VimResume, "VimResume should reannounce navigator state")
assert(events.FocusGained, "FocusGained should reannounce navigator state")

vim.cmd("vnew")
local windows = vim.api.nvim_tabpage_list_wins(0)
vim.api.nvim_set_current_win(windows[#windows])

navigator.navigate("left")
assert(#boundary == 0, "a Neovim split should handle left navigation")

navigator.navigate("left")
assert(vim.deep_equal(boundary, { "left" }), "a Neovim edge should signal TUIOS")

navigator.setup()
for _, lhs in ipairs({ "<A-Left>", "<A-Down>", "<A-Up>", "<A-Right>" }) do
	assert(next(vim.fn.maparg(lhs, "n", false, true)) ~= nil, "default mapping missing: " .. lhs)
end
