-- Auto-closing pairs with plain insert-mode mappings, no plugin.
--   typing an opener inserts the closer:   (| -> (|)
--   typing the closer steps over it:        (x|) -> (x)|
--   <CR> right before a closer steps over it too, `{|}` + <CR> opens a block instead
--   <BS> inside an empty pair deletes both halves
local M = {}

local pairs_ = { ['('] = ')', ['['] = ']', ['{'] = '}', ['<'] = '>', ['"'] = '"', ["'"] = "'" }
local closers = { [')'] = true, [']'] = true, ['}'] = true, ['>'] = true, ['"'] = true, ["'"] = true }

-- <C-g>U keeps the cursor move inside the same undo/dot-repeat step
local left = '<C-g>U<Left>'
local right = '<C-g>U<Right>'

--- @return string before, string after The text of the current line around the cursor
local function around_cursor()
  local col = vim.api.nvim_win_get_cursor(0)[2]
  local line = vim.api.nvim_get_current_line()
  return line:sub(1, col), line:sub(col + 1)
end

local function open(opener)
  local closer = pairs_[opener]
  return function()
    local before, after = around_cursor()
    if opener == '<' then
      -- only templates and includes, never `a < b` or `cout << x`
      local is_template = before:find('[%w_]$') ~= nil and not before:find('operator$')
      local is_keyword = before:find('template%s*$') ~= nil or before:find('#%s*include%s*$') ~= nil
      if not is_template and not is_keyword then return opener end
    end
    -- don't pair right in front of a word: `|foo` -> `(foo`
    if after:find('^[%w_]') then return opener end
    return opener .. closer .. left
  end
end

local function close(closer)
  return function()
    local _, after = around_cursor()
    return after:sub(1, 1) == closer and right or closer
  end
end

local function quote(char)
  return function()
    local before, after = around_cursor()
    if after:sub(1, 1) == char then return right end
    -- not next to a word (apostrophes, `1'000`), an escape, or another quote of the same kind
    if before:find('[%w_\\]$') or after:find('^[%w_]') or before:sub(-1) == char then return char end
    return char .. char .. left
  end
end

local function backspace()
  local before, after = around_cursor()
  local opener = before:sub(-1)
  if opener ~= '' and pairs_[opener] and pairs_[opener] == after:sub(1, 1) then return '<BS><Del>' end
  return '<BS>'
end

--- What <CR> should do next to a pair, or nil when it should just be a newline.
--- @return string? keys
function M.enter_keys()
  local before, after = around_cursor()
  local next_char = after:sub(1, 1)
  if not closers[next_char] then return nil end
  -- `{|}`: open a block instead of leaving it
  if next_char == '}' and before:sub(-1) == '{' then return '<CR><C-o>O' end
  -- a `>` only counts when it closes a `<` on this line (not `a > b` or `->`)
  if next_char == '>' and (before:sub(-1) == '-' or not before:find('<', 1, true)) then return nil end
  return right
end

--- <CR> handler for use from another mapping (blink.cmp's keymap).
--- @return boolean handled
function M.enter()
  local keys = M.enter_keys()
  if not keys then return false end
  vim.api.nvim_feedkeys(vim.keycode(keys), 'n', false)
  return true
end

function M.setup()
  local opts = { expr = true, replace_keycodes = true, desc = 'autopairs' }
  for opener, closer in pairs(pairs_) do
    if opener == closer then
      vim.keymap.set('i', opener, quote(opener), opts)
    else
      vim.keymap.set('i', opener, open(opener), opts)
      vim.keymap.set('i', closer, close(closer), opts)
    end
  end
  vim.keymap.set('i', '<BS>', backspace, opts)
  -- blink.cmp maps <CR> itself and calls M.enter(); this is the fallback when it's not loaded
  vim.keymap.set('i', '<CR>', function() return M.enter_keys() or '<CR>' end, opts)
end

return M
