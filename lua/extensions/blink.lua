local M = {}

local kinds = vim.lsp.protocol.CompletionItemKind
local callable_kinds = { [kinds.Function] = true, [kinds.Method] = true, [kinds.Constructor] = true }

--- Rewrite a call so accepting it leaves the cursor inside the parens:
--- `insert(${1:const value_type &x})` -> `insert($0)`
local function strip_snippet_args(text)
  if type(text) ~= 'string' or not text:find('%b()') then return text end
  return (text:gsub('%$0', ''):gsub('%(.*%)', '($0)', 1))
end

--- Stream manipulators (`endl`, `flush`, `hex`, ...) are functions that are passed
--- by name rather than called: their only parameter is the stream itself.
local function is_stream_manipulator(item)
  local detail = type(item.labelDetails) == 'table' and item.labelDetails.detail
  if type(detail) ~= 'string' then return false end
  -- drop template arguments first: `(basic_ostream<CharT, Traits> &os)` -> `(basic_ostream &os)`
  local param = detail:gsub('%b<>', ''):match('^%(([^,]*)%)$')
  if not param then return false end
  return param:find('^basic_[io]+stream ?&') ~= nil
    or param:find('^basic_ios ?&') ~= nil
    or param:find('^ios_base ?&') ~= nil
end

local function strip_snippet_call(text)
  if type(text) ~= 'string' then return text end
  return (text:gsub('%(.*%)', '', 1))
end

local function cursor_inside_parens(item)
  if item.cursor_inside_parens then return end
  item.cursor_inside_parens = true

  if is_stream_manipulator(item) then
    item.insertText = strip_snippet_call(item.insertText)
    if type(item.textEdit) == 'table' then
      item.textEdit = vim.tbl_extend('force', item.textEdit, { newText = strip_snippet_call(item.textEdit.newText) })
    end
    return
  end

  local snippet = vim.lsp.protocol.InsertTextFormat.Snippet
  local text = type(item.textEdit) == 'table' and item.textEdit.newText or item.insertText
  if item.insertTextFormat ~= snippet then
    -- plain text like `size()`: only safe to turn into a snippet without special characters
    if type(text) ~= 'string' or not text:find('%(%)$') or text:find('[$\\}]') then return end
    item.insertTextFormat = snippet
  end

  item.insertText = strip_snippet_args(item.insertText)
  if type(item.textEdit) == 'table' then
    item.textEdit = vim.tbl_extend('force', item.textEdit, { newText = strip_snippet_args(item.textEdit.newText) })
  end
end

local c_family = { c = true, cpp = true, objc = true, objcpp = true, cuda = true }

--- clangd answers a completion request triggered by `<`, `>`, `:`, `"` or `/` with nothing
--- unless it's `->`, `::` or an #include, and blink then keeps asking the same way while
--- the word is typed. So `make_unique<|>` never got completions for the type. Re-send those
--- requests as a normal (non trigger character) request instead.
local function get_lsp_completions(self, ctx, callback)
  local trigger = ctx.trigger
  if c_family[vim.bo[ctx.bufnr].filetype] and trigger.kind == 'trigger_character' then
    local char = trigger.character
    local before = ctx.line:sub(1, ctx.bounds.start_col - 1)
    local honoured = char == '.'
      or (char == '>' and before:sub(-2) == '->')
      or (char == ':' and before:sub(-2) == '::')
      or ((char == '<' or char == '"' or char == '/') and before:find('^%s*#%s*include') ~= nil)
    -- right after `<` offer types straight away (template arguments), for the other
    -- characters wait until a word is being typed
    if not honoured and (char == '<' or ctx.bounds.length > 0) then
      ctx = setmetatable({
        trigger = vim.tbl_extend('force', trigger, { kind = 'keyword', character = vim.NIL }),
      }, { __index = ctx })
      ctx.trigger.character = nil
    end
  end
  return self:get_completions(ctx, callback)
end

local type_kinds = {
  [kinds.Class] = true,
  [kinds.Struct] = true,
  [kinds.Interface] = true,
  [kinds.Enum] = true,
  [kinds.TypeParameter] = true,
}

--- Rank completions by where the cursor is. Neither blink nor the language server type-check
--- the candidates, so this is a heuristic: where a value is expected (after `=`, `==`, `!=` or `return`),
--- type names like `nullptr_t` are pushed below values like `nullptr`.
local function rank_for_context(ctx, items)
  local before = ctx.line:sub(1, ctx.bounds.start_col - 1)
  local wants_value = before:find('[^=!<>+%-*/%%&|^]=%s*$') ~= nil -- assignment / initialisation
    or before:find('[=!]=%s*$') ~= nil -- comparison
    or before:find('%f[%w_]return%s+$') ~= nil
  local snippet_offset = require('blink.cmp.config').snippets.score_offset

  for _, item in ipairs(items) do
    local offset = 0
    if wants_value and type_kinds[item.kind] then offset = offset - 5 end
    -- clangd reports keywords (`nullptr`, `true`, ...) as snippets, which blink ranks lower.
    -- Undo that for ones that insert plain text.
    local text = type(item.textEdit) == 'table' and item.textEdit.newText or item.insertText or item.label
    if item.kind == kinds.Snippet and not text:find('$', 1, true) then offset = offset - snippet_offset end
    item.score_offset = offset
  end
  return items
end

--- Collapse function overloads into a single completion item showing only the name.
local function collapse_overloads(_, items)
  local seen, out = {}, {}
  for _, item in ipairs(items) do
    local name = callable_kinds[item.kind] and item.label:match('^[^(]+')
    if not name or vim.trim(name) == 'operator' then
      out[#out + 1] = item
    else
      cursor_inside_parens(item)
      local key = item.kind .. '\0' .. name
      local first = seen[key]
      if not first then
        seen[key] = item
        out[#out + 1] = item
      elseif not first.overloads_collapsed then
        -- there's more than one overload: drop the arguments from the one we keep
        first.overloads_collapsed = true
        first.label = name
        if type(first.labelDetails) == 'table' then first.labelDetails.detail = nil end
      end
    end
  end
  return out
end

-- 'cinkeys'/'indentkeys' only fire on typed characters, so a completed label such as
-- `private:` or `default:` keeps the indent it was typed at. Reindent it on accept.
local function reindent_accepted_label()
  if not vim.bo.cindent and vim.bo.indentexpr == '' then return end
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  local line = vim.api.nvim_get_current_line()
  if not line:sub(1, col):match('^%s*[%w_]+%s*:$') or line:sub(col + 1):match('%S') then return end

  vim.cmd('silent! keepjumps normal! ==')
  local reindented = vim.api.nvim_get_current_line()
  vim.api.nvim_win_set_cursor(0, { row, col + #reindented - #line })
end

-- Signature cycling: the signature window lists every overload bottom -> top with the
-- active one last, and <C-s> rotates to the next one without leaving insert mode.
local sig_ns = vim.api.nvim_create_namespace('blink_signature_overloads')
local sig = { help = nil, label = nil, context_id = nil, index = 1, show_all = true }

local function setup_signature_cycling()
  local window = require('blink.cmp.signature.window')
  local open = window.open_with_signature_help

  window.open_with_signature_help = function(context, help)
    help = help._full or help
    local sigs = help.signatures or {}
    if #sigs == 0 then
      sig.help = nil
      return open(context, help)
    end

    -- forget the chosen overload when a new call is started
    if sig.context_id ~= context.id then sig.label = nil end
    sig.context_id, sig.help = context.id, help

    -- keep showing the overload picked with <C-s> while typing, otherwise use the server's pick
    local index = (help.activeSignature or 0) + 1
    if sig.label then
      for i, s in ipairs(sigs) do
        if s.label == sig.label then
          index = i
          break
        end
      end
    end
    if not sigs[index] then index = 1 end
    sig.index = index
    help.activeSignature = index - 1

    -- list bottom -> top: the active overload on the last line (closest to the cursor), the next one above it
    local active, ordered = sigs[index], {}
    for i = sig.show_all and #sigs - 1 or 0, 0, -1 do
      ordered[#ordered + 1] = sigs[(index - 1 + i) % #sigs + 1]
    end
    -- blink always draws the active parameter highlight on the first line, which is the wrong
    -- line here (and errors when that line is shorter). Hand it the active overload without
    -- parameters so it draws none, the highlight is added on the right line below.
    local shown = vim.tbl_extend('force', {}, active)
    shown.parameters = nil
    ordered[#ordered] = shown
    open(context, { signatures = ordered, activeSignature = #ordered - 1, _full = help })
    if not window.win:is_open() then return end

    local buf = window.win:get_buf()
    local ns = require('blink.cmp.config').appearance.highlight_ns
    local seen, active_row = {}, 0
    for _, s in ipairs(ordered) do
      if s == shown then break end
      if not seen[s.label] then
        seen[s.label] = true
        active_row = active_row + #vim.split(s.label, '\n')
      end
    end
    local detail_rows = active_row + #vim.split(active.label, '\n')
    for _, mark in ipairs(vim.api.nvim_buf_get_extmarks(buf, ns, 0, -1, { details = true })) do
      if mark[2] < detail_rows and type(mark[4].hl_group) == 'string' and mark[4].hl_group:sub(1, 1) == '@' then
        -- blink parses all overloads as one block of code, which colours them inconsistently
        vim.api.nvim_buf_del_extmark(buf, ns, mark[1])
      end
    end
    -- syntax highlight only the active overload and dim the others
    vim.api.nvim_buf_clear_namespace(buf, sig_ns, 0, -1)
    for row = 0, active_row - 1 do
      local line = vim.api.nvim_buf_get_lines(buf, row, row + 1, false)[1] or ''
      vim.api.nvim_buf_set_extmark(buf, sig_ns, row, 0, { end_col = #line, hl_group = 'Comment' })
    end
    pcall(function()
      local lang = vim.treesitter.language.get_lang(vim.bo.filetype)
      local query = vim.treesitter.query.get(lang, 'highlights')
      local root = vim.treesitter.get_string_parser(active.label, lang):parse()[1]:root()
      for id, node in query:iter_captures(root, active.label) do
        local srow, scol, erow, ecol = node:range()
        vim.api.nvim_buf_set_extmark(buf, sig_ns, active_row + srow, scol, {
          end_row = active_row + erow,
          end_col = ecol,
          hl_group = '@' .. query.captures[id] .. '.' .. lang,
          priority = vim.hl.priorities.treesitter,
        })
      end
    end)

    -- highlight the active parameter of the active overload
    pcall(function()
      local mode = require('blink.cmp.completion.trigger.context').get_mode()
      local triggers = require('blink.cmp.sources.lib').get_signature_help_trigger_characters(mode).trigger_characters
      local _, hl = vim.lsp.util.convert_signature_help_to_markdown_lines({
        signatures = { active },
        activeSignature = 0,
        activeParameter = active.activeParameter or help.activeParameter,
      }, vim.bo.filetype, triggers)
      if not hl then return end
      vim.api.nvim_buf_set_extmark(buf, sig_ns, active_row + hl[1] - 1, hl[2], {
        end_row = active_row + hl[3] - 1,
        end_col = hl[4],
        hl_group = 'BlinkCmpSignatureHelpActiveParameter',
      })
    end)

    -- keep the active overload in view when the list is taller than the window
    pcall(function() window.win:set_cursor({ active_row + 1, 0 }) end)

    -- overload counter, only possible when the window has a border
    pcall(function()
      window.win:set_win_config({
        title = #sigs > 1 and (' %d/%d '):format(index, #sigs) or '',
        title_pos = 'right',
      })
    end)
  end
end

--- Toggle between listing every overload and only the selected one (<C-k>)
local function toggle_all_signatures()
  local window = require('blink.cmp.signature.window')
  if not window.win:is_open() or not sig.help or not window.context then return false end

  sig.show_all = not sig.show_all
  window.shown_signature = nil -- force blink to redraw the list
  window.open_with_signature_help(window.context, sig.help)
  return true
end

--- Show the signature window, or cycle to the next overload when it's already open
local function cycle_signature(cmp)
  local window = require('blink.cmp.signature.window')
  if not window.win:is_open() or not sig.help or not window.context then
    cmp.show_signature()
    return true
  end

  local sigs = sig.help.signatures
  if #sigs > 1 then
    sig.label = sigs[sig.index % #sigs + 1].label
    window.open_with_signature_help(window.context, sig.help)
  end
  return true
end

function M.setup()
  vim.pack.add({ { src = 'https://github.com/saghen/blink.lib' } })
  vim.pack.add({ { src = 'https://github.com/saghen/blink.cmp' } })
  require("blink.cmp").build():pwait()
  require("blink.cmp").setup({
    keymap = {
      ['<C-space>'] = { 'show', 'show_documentation', 'hide_documentation' },
      ['<C-e>'] = { 'hide', 'fallback' },
      ['<Tab>'] = {
        'accept',
        'fallback'
      },
      -- ['<S-Tab>'] = { 'snippet_backward', 'fallback' },
      ['<C-y>'] = {'accept', 'fallback'},
      ['<CR>'] = { 'snippet_forward', function() return require('autopairs').enter() end, 'fallback' },
      ['<S-CR>'] = {'snippet_backward', 'fallback'},
      ['<Up>'] = { 'select_prev', 'fallback' },
      ['<Down>'] = { 'select_next', 'fallback' },
      ['<C-p>'] = { 'select_prev', 'fallback_to_mappings' },
      ['<C-n>'] = { function (cmp)
        cmp.show()
      end, 'select_next', 'fallback_to_mappings' },
      ['<C-b>'] = { 'scroll_documentation_up', 'fallback' },
      ['<C-f>'] = { 'scroll_documentation_down', 'fallback' },
      ['<C-k>'] = { toggle_all_signatures, 'show_signature', 'fallback' },
      ['<C-s>'] = { cycle_signature },
    },
    signature = { enabled = true },
    fuzzy = { implementation = 'prefer_rust_with_warning' },
    sources = {
      default = { 'lsp', 'path', 'snippets', 'buffer' },
      providers = {
        lsp = {
          transform_items = function(ctx, items) return rank_for_context(ctx, collapse_overloads(ctx, items)) end,
          override = { get_completions = get_lsp_completions },
        },
        buffer = {
          score_offset = -95,
        },
      },
    },
    completion = {
      menu = { auto_show = true },
      ghost_text = { enabled = false },
    },
  })
  setup_signature_cycling()

  require('blink.cmp.completion.list').accept_emitter:on(function(ev)
    reindent_accepted_label()
  end)

  -- show the signature window whenever the cursor is inside a call, not just after typing `(`
  vim.api.nvim_create_autocmd({ 'InsertEnter', 'CursorMovedI' }, {
    group = vim.api.nvim_create_augroup('BlinkSignatureInsideCall', { clear = true }),
    callback = function()
      local trigger = require('blink.cmp.signature.trigger')
      if trigger.context == nil and require('blink.cmp').is_enabled() then trigger.show() end
    end,
  })
end

M.setup()

return M
