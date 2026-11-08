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

-- nvim_ui_send (Neovim 0.12+) writes to the terminal of the attached UI only:
-- nothing reaches stdout when Neovim runs headless or with its output
-- redirected (`nvim --headless ... | cmd` got the sequence as garbage), and it
-- does not interleave with the TUI's own output. Older versions keep writing to
-- stdout, but only while a UI is attached.
local function send(command, value)
	local sequence = "\27]7777;tuios-nvim-navigator;" .. command .. ";" .. value .. "\7"
	if vim.api.nvim_ui_send then
		vim.api.nvim_ui_send(sequence)
	elseif #vim.api.nvim_list_uis() > 0 then
		io.stdout:write(sequence)
		io.stdout:flush()
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
	-- UIEnter: the TUI attaches after init.lua has run, so an announcement made
	-- during setup() at startup has no UI to go to yet.
	vim.api.nvim_create_autocmd({ "UIEnter", "VimResume", "FocusGained" }, {
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
