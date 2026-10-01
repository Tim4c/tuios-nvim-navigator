local M = {}

local defaults = {
	keymaps = {
		left = "<C-h>",
		down = "<C-j>",
		up = "<C-k>",
		right = "<C-l>",
	},
	modes = { "n" },
	on_boundary = nil,
}

local options = vim.deepcopy(defaults)

local commands = {
	left = "wincmd h",
	down = "wincmd j",
	up = "wincmd k",
	right = "wincmd l",
}

local function send(command, value)
	io.stdout:write("\27]7777;tuios-nvim-navigator;" .. command .. ";" .. value .. "\7")
	io.stdout:flush()
end

local function send_boundary(direction)
	if options.on_boundary then
		options.on_boundary(direction)
		return
	end

	send("focus", direction)
end

local function announce_active()
	send("state", "active")
end

function M.navigate(direction)
	local command = commands[direction]
	if not command then
		error("unknown direction: " .. tostring(direction))
	end

	local before = vim.api.nvim_get_current_win()
	vim.cmd(command)
	if vim.api.nvim_get_current_win() == before then
		send_boundary(direction)
	end
end

function M.setup(user_options)
	options = vim.tbl_deep_extend("force", vim.deepcopy(defaults), user_options or {})

	for direction, lhs in pairs(options.keymaps) do
		if lhs and lhs ~= "" then
			vim.keymap.set(options.modes, lhs, function()
				M.navigate(direction)
			end, { silent = true, desc = "Navigate " .. direction .. " through TUIOS" })
		end
	end

	announce_active()
	local group = vim.api.nvim_create_augroup("TuiosNvimNavigator", { clear = true })
	vim.api.nvim_create_autocmd({ "VimResume", "FocusGained" }, {
		group = group,
		callback = announce_active,
	})
	vim.api.nvim_create_autocmd("VimLeavePre", {
		group = group,
		callback = function()
			send("state", "inactive")
		end,
	})
end

return M
