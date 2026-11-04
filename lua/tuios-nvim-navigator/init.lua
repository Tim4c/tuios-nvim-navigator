local M = {}

local defaults = {
	keymaps = {
		left = "<A-Left>",
		down = "<A-Down>",
		up = "<A-Up>",
		right = "<A-Right>",
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

local function check_direction(direction)
	if not commands[direction] then
		error("unknown direction: " .. tostring(direction))
	end
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

-- A floating window has no split neighbours: `wincmd` from it lands in
-- whatever window lies behind it instead of reaching an edge.
local function is_floating()
	return vim.api.nvim_win_get_config(0).relative ~= ""
end

---Ask TUIOS to focus the pane in `direction`, without moving between Neovim
---windows first. Useful for integrations that know they are at an edge, such
---as a file tree drawn in a floating window.
---@param direction "left"|"down"|"up"|"right"
function M.focus(direction)
	check_direction(direction)
	send_boundary(direction)
end

function M.navigate(direction)
	check_direction(direction)

	if is_floating() then
		send_boundary(direction)
		return
	end

	local before = vim.api.nvim_get_current_win()
	vim.cmd(commands[direction])
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
