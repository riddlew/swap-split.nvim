----------------------------------------------------------------------------
-- Swap-Split
-- Swaps your current split with another split.

-- @author Xorid
----------------------------------------------------------------------------

local M = {
	ignore_filetypes = {
		'NvimTree'
	}
}
local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890"

local function get_input_char()
	local char = vim.fn.getchar()
	return vim.fn.nr2char(char)
end

local function clear_prompt()
	if vim.opt.cmdheight._value ~= 0 then
		vim.cmd "normal! :"
	end
end

local function get_allowed_winids()
	local tabpage = vim.api.nvim_get_current_tabpage()
	local ids = vim.api.nvim_tabpage_list_wins(tabpage)
	local currentwin = vim.api.nvim_get_current_win()

	return vim.tbl_filter(function(id)
		local buf = vim.api.nvim_win_get_buf(id)
		local ft = vim.api.nvim_buf_get_option(buf, "filetype")

		return not vim.tbl_contains(M.ignore_filetypes, ft) and id ~= currentwin
	end, ids)
end

function M.select_win()
	-- local tabpage = vim.api.nvim_get_current_tabpage()
	-- local winids = vim.api.nvim_tabpage_list_wins(tabpage)
	local winids = get_allowed_winids()
	local current_buf = vim.api.nvim_get_current_buf()
	local current_ft = vim.api.nvim_buf_get_option(current_buf, "filetype")
	local win_opts = {}
	local win_chars = {}
	local char_i = 1

	if #winids == 0 or vim.tbl_contains(M.ignore_filetypes, current_ft) then
		return -1
	elseif #winids == 1 then
		return winids[1]
	end

	local laststatus = vim.o.laststatus
	vim.o.laststatus = 2

	for _, id in ipairs(winids) do
		local char = chars:sub(char_i, char_i)
		local ok_statusline, statusline = pcall(vim.api.nvim_win_get_option, id, "statusline")
		local ok_hl, winhl = pcall(vim.api.nvim_win_get_option, id, "winhl")

		win_opts[id] = {
			statusline = ok_statusline and statusline or "",
			winhl = ok_hl and winhl or "",
		}

		win_chars[char] = id
		vim.api.nvim_win_set_option(id, "statusline", "%=" .. char .. "%=")
		vim.api.nvim_win_set_option(id, "winhl", "StatusLine:SwapSplitStatusLine,StatusLineNC:SwapSplitStatusLine")

		char_i = char_i + 1
		if char_i > #chars then
			break
		end
	end

	vim.cmd "redraw"
	if vim.opt.cmdheight._value ~= 0 then
		print("[Swap-Split] Select window:")
	end

	local _, response = pcall(get_input_char)
	response = (response or ""):upper()
	clear_prompt()

	for _, id in ipairs(winids) do
		for opt, value in pairs(win_opts[id]) do
			vim.api.nvim_win_set_option(id, opt, value)
		end
	end

	vim.o.laststatus = laststatus

	if not vim.tbl_contains(vim.split(chars, ""), response) then
		return
	end

	return win_chars[response]
end

local function swap_splits(from, to)
	vim.api.nvim_win_set_buf(from.win, to.buf)
	vim.api.nvim_win_set_buf(to.win, from.buf)
	vim.api.nvim_set_current_win(to.win)
end

function M.swap()
	local from = {
		win = vim.api.nvim_get_current_win(),
		buf = vim.api.nvim_win_get_buf(0),
	}

	local winid = M.select_win()
	if winid == nil or winid < 0 then
		return
	end

	local to = {
		win = winid,
		buf = vim.api.nvim_win_get_buf(winid)
	}

	swap_splits(from, to)
end

function M.setup(opts)
	M = vim.tbl_deep_extend("force", M, opts or {})
end

return M
