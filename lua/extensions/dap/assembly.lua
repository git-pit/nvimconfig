local M = {}

local state = {
  enabled = false,
  generation = 0,
  instructions = {},
  registers = {},
  function_registers = {},
  function_addresses = {},
}

local function address_key(address)
  if not address then return nil end
  return tostring(address):lower():gsub("^0x0*", "")
end

local function explain(instruction)
  local mnemonic, operands = instruction:lower():match("^%s*([%w%.]+)%s*(.-)%s*$")
  if not mnemonic then return nil end
  operands = vim.trim(operands)
  local first, second, third = operands:match("^%s*([^,]+),%s*([^,]+),%s*(.+)$")
  if not first then first, second = operands:match("^%s*([^,]+),%s*(.+)$") end
  if first then first = vim.trim(first) end
  if second then second = vim.trim(second) end
  if third then third = vim.trim(third) end
  if mnemonic == "stp" and operands:match("^x29,%s*x30,") then
    return "save the frame pointer and return address"
  end
  if mnemonic == "ldp" and operands:match("^x29,%s*x30,") then
    return "restore the frame pointer and return address"
  end
  if mnemonic == "mov" and operands == "x29, sp" then return "set up this function's frame pointer" end
  if mnemonic == "sub" and operands:match("^sp,%s*sp,") then return "reserve stack space" end
  if mnemonic == "add" and operands:match("^sp,%s*sp,") then return "release stack space" end
  if mnemonic == "mov" and first and second then
    if operands:find("%%") then return second .. " gets " .. first end
    return first .. " gets " .. second
  end
  if mnemonic == "movz" then return "load an immediate value, clearing other bits" end
  if mnemonic == "movk" then return "replace part of the destination register" end
  if mnemonic == "adr" then return "compute a nearby address" end
  if mnemonic == "adrp" then return "compute a page address" end
  if mnemonic == "ldp" then return "load two registers from memory" end
  if mnemonic == "stp" then return "store two registers to memory" end
  if mnemonic:match("^ld[ru]?[rbshw]?") then return "load value from memory" end
  if mnemonic:match("^st[ru]?[rbh]?") then return "store value to memory" end
  if mnemonic == "lea" then return "compute an address without reading memory" end
  if mnemonic == "add" and first and second and third then
    return first .. " gets " .. second .. " plus " .. third
  end
  if mnemonic == "sub" and first and second and third then
    return first .. " gets " .. second .. " minus " .. third
  end
  if mnemonic == "add" then return "add values" end
  if mnemonic == "adds" then return "add values and set condition flags" end
  if mnemonic == "sub" then return "subtract values" end
  if mnemonic == "subs" then return "subtract values and set condition flags" end
  if mnemonic == "cmp" or mnemonic == "cmn" then return "compare values and set condition flags" end
  if mnemonic == "test" or mnemonic == "tst" then return "test bits and set condition flags" end
  if mnemonic == "and" then return "bitwise AND" end
  if mnemonic == "orr" or mnemonic == "or" then return "bitwise OR" end
  if mnemonic == "eor" or mnemonic == "xor" then return "bitwise exclusive OR" end
  if mnemonic == "lsl" or mnemonic == "shl" then return "shift bits left" end
  if mnemonic == "lsr" or mnemonic == "shr" then return "shift bits right" end
  if mnemonic == "asr" or mnemonic == "sar" then return "arithmetic shift right" end
  if mnemonic == "mul" or mnemonic == "imul" then return "multiply values" end
  if mnemonic == "sdiv" or mnemonic == "udiv" or mnemonic == "idiv" then return "divide values" end
  if mnemonic == "bl" or mnemonic == "blr" or mnemonic == "call" or mnemonic == "callq" then
    return "call " .. operands
  end
  if mnemonic == "ret" or mnemonic == "retq" then return "return to the caller" end
  if mnemonic == "b" or mnemonic == "br" or mnemonic == "jmp" then return "jump to " .. operands end
  if mnemonic:match("^b%.") or mnemonic:match("^j[%a]+$") then
    return "jump if the condition is met"
  end
  if mnemonic == "cbz" then return "jump if the register is zero" end
  if mnemonic == "cbnz" then return "jump if the register is not zero" end
  if mnemonic == "tbz" then return "jump if the selected bit is zero" end
  if mnemonic == "tbnz" then return "jump if the selected bit is not zero" end
  if mnemonic == "push" then return "push a value onto the stack" end
  if mnemonic == "pop" then return "pop a value from the stack" end
  if mnemonic == "nop" then return "do nothing" end
  return nil
end

local x86_aliases = {
  eax = "rax", ax = "rax", ah = "rax", al = "rax",
  ebx = "rbx", bx = "rbx", bh = "rbx", bl = "rbx",
  ecx = "rcx", cx = "rcx", ch = "rcx", cl = "rcx",
  edx = "rdx", dx = "rdx", dh = "rdx", dl = "rdx",
  esi = "rsi", si = "rsi", sil = "rsi",
  edi = "rdi", di = "rdi", dil = "rdi",
  ebp = "rbp", bp = "rbp", bpl = "rbp",
  esp = "rsp", spl = "rsp",
  eip = "rip", ip = "rip",
}

local function register_name(word)
  local name = word:lower()
  if name == "fp" then return "x29" end
  if name == "lr" then return "x30" end
  if name == "wsp" then return "sp" end
  if name == "wzr" then return "xzr" end
  if name:match("^w%d+$") then return "x" .. name:sub(2) end
  local vector = name:match("^[qdshb](%d+)$")
  if vector then return "v" .. vector end
  if x86_aliases[name] then return x86_aliases[name] end
  local rnum = name:match("^(r%d+)[dwb]$")
  if rnum then return rnum end
  if name:match("^[xvqdshb]%d+$") or name:match("^r%d+$")
      or name:match("^[xyz]mm%d+$") then return name end
  if name:match("^r[a-d]x$") or name:match("^r[bs]p$")
      or name == "rsi" or name == "rdi" or name == "rip" or name == "rflags"
      or name == "eflags" or name == "sp" or name == "pc" or name == "nzcv"
      or name == "xzr" then return name end
  return nil
end

local function instruction_registers(instruction)
  local names, seen = {}, {}
  local function add(word)
    local name = register_name(word)
    if name and not seen[name] then
      names[#names + 1] = name
      seen[name] = true
    end
  end
  local mnemonic, operands = instruction:lower():match("^%s*([%w%.]+)%s*(.-)%s*$")
  mnemonic, operands = mnemonic or "", operands or ""
  operands = operands:gsub("0x[%x]+", "")
  for word in operands:gmatch("[%a_][%w_]*") do add(word) end
  if mnemonic == "cmp" or mnemonic == "cmn" or mnemonic == "tst" or mnemonic == "test"
      or mnemonic == "adds" or mnemonic == "subs" or mnemonic:match("^b%.")
      or (mnemonic:match("^j[%a]+$") and mnemonic ~= "jmp") then
    add("nzcv")
    add("rflags")
  end
  return names
end

local function register_value(name)
  if name == "xzr" then return "0" end
  return state.registers[name] or "unavailable"
end

local function render_registers()
  local buf = state.register_buf
  if not buf or not vim.api.nvim_buf_is_valid(buf) then return end
  local current_instruction
  for _, item in ipairs(state.instructions) do
    if address_key(item.address) == address_key(state.pc) then
      current_instruction = (item.instruction or ""):match("^(.-)%s*;") or item.instruction or ""
      break
    end
  end
  local lines = { "Current instruction" }
  local current_names = instruction_registers(current_instruction or "")
  current_names[#current_names + 1] = state.registers.pc and "pc" or "rip"
  current_names[#current_names + 1] = state.registers.sp and "sp" or "rsp"
  local shown = {}
  local count = 0
  for _, name in ipairs(current_names) do
    if not shown[name] and (state.registers[name] or name == "xzr") then
      lines[#lines + 1] = string.format("  %-7s %s", name, register_value(name))
      shown[name] = true
      count = count + 1
    end
  end
  if count == 0 then lines[#lines + 1] = state.register_status or "Registers: loading…" end
  lines[#lines + 1] = ""
  lines[#lines + 1] = "Current function: " .. (state.function_name or "loading…")
  if #state.function_registers == 0 then
    lines[#lines + 1] = state.function_status or "Scanning function…"
  else
    for _, name in ipairs(state.function_registers) do
      lines[#lines + 1] = string.format("  %-7s %s", name, register_value(name))
    end
  end
  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
end

local function render()
  local buf = state.buf
  if not buf or not vim.api.nvim_buf_is_valid(buf) then return end
  render_registers()
  local lines = { "Assembly — current frame", "" }
  local current_line
  for _, item in ipairs(state.instructions) do
    local current = address_key(item.address) == address_key(state.pc)
    local asm = item.instruction or ""
    local code, lldb_note = asm:match("^(.-)%s*;%s*(.*)$")
    code = vim.trim(code or asm)
    local line = string.format("%s %-18s %s", current and "=>" or "  ", item.address or "", code)
    local comment = explain(code)
    if comment then line = line .. "    ; " .. comment end
    if lldb_note and lldb_note ~= "" then line = line .. " (" .. vim.trim(lldb_note) .. ")" end
    if item.location and item.location.path and item.line then
      line = line .. string.format("  [%s:%s]", vim.fn.fnamemodify(item.location.path, ":t"), item.line)
    end
    lines[#lines + 1] = line
    if current then current_line = #lines end
  end
  if #state.instructions == 0 then
    lines[#lines + 1] = state.message or "Waiting for a stopped LLDB frame…"
  end
  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  vim.api.nvim_buf_clear_namespace(buf, state.namespace, 0, -1)
  if current_line then
    vim.api.nvim_buf_set_extmark(buf, state.namespace, current_line - 1, 0,
      { line_hl_group = "CursorLine" })
    if state.win and vim.api.nvim_win_is_valid(state.win) then
      vim.api.nvim_win_set_cursor(state.win, { current_line, 0 })
    end
  end
end

local function open_view()
  if state.win and vim.api.nvim_win_is_valid(state.win) then return end
  state.source_win = vim.api.nvim_get_current_win()
  state.buf = vim.api.nvim_create_buf(false, true)
  vim.bo[state.buf].buftype = "nofile"
  vim.bo[state.buf].bufhidden = "wipe"
  vim.bo[state.buf].swapfile = false
  vim.bo[state.buf].filetype = "asm"
  vim.cmd("rightbelow vsplit")
  state.win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(state.win, state.buf)
  vim.api.nvim_win_set_width(state.win, math.min(110, math.max(50, math.floor(vim.o.columns * 0.55))))
  vim.wo[state.win].number = false
  vim.wo[state.win].relativenumber = false
  vim.wo[state.win].wrap = false
  state.register_buf = vim.api.nvim_create_buf(false, true)
  vim.bo[state.register_buf].buftype = "nofile"
  vim.bo[state.register_buf].bufhidden = "wipe"
  vim.bo[state.register_buf].swapfile = false
  vim.cmd("aboveleft split")
  state.register_win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(state.register_win, state.register_buf)
  vim.api.nvim_win_set_height(state.register_win, 14)
  vim.wo[state.register_win].number = false
  vim.wo[state.register_win].relativenumber = false
  vim.wo[state.register_win].wrap = false
  vim.wo[state.register_win].winfixheight = true
  render()
  if vim.api.nvim_win_is_valid(state.source_win) then
    vim.api.nvim_set_current_win(state.source_win)
  end
end

local function close_view()
  if state.register_win and vim.api.nvim_win_is_valid(state.register_win) then
    vim.api.nvim_win_close(state.register_win, true)
  end
  if state.win and vim.api.nvim_win_is_valid(state.win) then
    vim.api.nvim_win_close(state.win, true)
  end
  state.win, state.buf, state.register_win, state.register_buf = nil, nil, nil, nil
  if state.source_win and vim.api.nvim_win_is_valid(state.source_win) then
    vim.api.nvim_set_current_win(state.source_win)
  end
  state.source_win = nil
end

local function valid_request(session, generation)
  return state.enabled and state.session == session and state.generation == generation
end

local function scan_function(session, frame, generation)
  if state.function_name == frame.name and state.function_addresses[address_key(state.pc)] then
    return
  end
  state.function_name = frame.name
  state.function_registers = {}
  state.function_addresses = {}
  state.function_status = "Scanning function…"
  render()
  local prefix = session.config.commandEscapePrefix
  if prefix == nil then prefix = "`" end
  session:request("evaluate", {
    expression = prefix .. "disassemble --frame",
    context = "repl",
    frameId = frame.id,
  }, function(err, response)
    if not valid_request(session, generation) then return end
    if err or not response or not response.result then
      state.function_status = "Function disassembly unavailable"
      render()
      return
    end
    local names, seen, addresses = {}, {}, {}
    for line in response.result:gmatch("[^\r\n]+") do
      local address, instruction = line:match("(0[xX][%x]+)%s*<[^>]+>:%s*(.+)$")
      if not address then address, instruction = line:match("(0[xX][%x]+):%s*(.+)$") end
      if address and instruction then
        addresses[address_key(address)] = true
        local code = instruction:match("^(.-)%s*;") or instruction
        for _, name in ipairs(instruction_registers(code)) do
          if not seen[name] then
            names[#names + 1] = name
            seen[name] = true
          end
        end
      end
    end
    state.function_addresses = addresses
    state.function_registers = names
    state.function_status = next(addresses) and "No named registers in this function"
        or "Could not read function instructions"
    render()
  end)
end

local function fetch_registers(session, frame, generation)
  local scope
  for _, candidate in ipairs(frame.scopes or {}) do
    if candidate.presentationHint == "registers" or candidate.name:lower() == "registers" then
      scope = candidate
      break
    end
  end
  if not scope or not scope.variablesReference or scope.variablesReference == 0 then
    state.register_status = "Registers: unavailable"
    render()
    return
  end

  local values, pending = {}, 0
  local function finish()
    pending = pending - 1
    if pending ~= 0 or not valid_request(session, generation) then return end
    state.registers = values
    state.register_status = "Registers: unavailable"
    render()
  end
  local function load(reference, depth)
    pending = pending + 1
    session:request("variables", { variablesReference = reference }, function(err, response)
      if valid_request(session, generation) and not err then
        for _, variable in ipairs((response or {}).variables or {}) do
          if variable.variablesReference and variable.variablesReference > 0 and depth < 2 then
            load(variable.variablesReference, depth + 1)
          elseif variable.name and variable.value then
            values[variable.name:lower()] = variable.value
          end
        end
      end
      finish()
    end)
  end
  load(scope.variablesReference, 0)
end

local function refresh(session)
  if not state.enabled or not session or not session.current_frame then return end
  local frame = session.current_frame
  state.session = session
  state.frame_id = frame.id
  state.generation = state.generation + 1
  local generation = state.generation
  state.pc = frame.instructionPointerReference
  state.instructions = {}
  state.registers = {}
  state.register_status = "Registers: loading…"
  state.message = "Loading disassembly…"
  render()

  if not state.pc then
    state.message = "LLDB did not provide an instruction pointer for this frame."
    render()
    return
  end
  if session.capabilities and session.capabilities.supportsDisassembleRequest == false then
    state.message = "This LLDB adapter does not support disassembly."
    render()
    return
  end
  scan_function(session, frame, generation)
  session:request("disassemble", {
    memoryReference = state.pc,
    instructionOffset = -12,
    instructionCount = 36,
    resolveSymbols = true,
  }, function(err, response)
    if not valid_request(session, generation) then return end
    if err then
      state.message = "Disassembly failed: " .. tostring(err.message or err)
    else
      state.instructions = (response or {}).instructions or {}
      state.message = "No instructions returned by LLDB."
    end
    render()
  end)
  if frame.scopes then fetch_registers(session, frame, generation) end
end

function M.setup(dap)
  state.namespace = vim.api.nvim_create_namespace("dap-assembly-current")
  vim.keymap.set("n", "<leader>da", function()
    if state.enabled then
      state.enabled = false
      state.generation = state.generation + 1
      dap.defaults.lldb.stepping_granularity = "statement"
      dap.defaults["lldb-dap"].stepping_granularity = "statement"
      close_view()
      vim.notify("Debug stepping: source")
      return
    end
    local session = dap.session()
    if not session or (session.config.type ~= "lldb" and session.config.type ~= "lldb-dap") then
      vim.notify("Start an LLDB debug session to show assembly", vim.log.levels.INFO)
      return
    end
    state.enabled = true
    state.session = session
    dap.defaults.lldb.stepping_granularity = "instruction"
    dap.defaults["lldb-dap"].stepping_granularity = "instruction"
    open_view()
    refresh(session)
    vim.notify("Debug stepping: assembly")
  end, { desc = "Debug: toggle source/assembly stepping and view" })
  vim.keymap.set("n", "<leader>dg", function()
    if state.register_win and vim.api.nvim_win_is_valid(state.register_win) then
      vim.api.nvim_set_current_win(state.register_win)
    else
      vim.notify("Open the assembly view with <leader>da first", vim.log.levels.INFO)
    end
  end, { desc = "Debug: focus assembly registers" })

  dap.listeners.after.stackTrace.assembly_view = function(session)
    if state.enabled and session == state.session and session.current_frame then refresh(session) end
  end
  dap.listeners.after.scopes.assembly_view = function(session)
    if not state.enabled or session ~= state.session or not session.current_frame then return end
    local frame = session.current_frame
    if frame.id ~= state.frame_id then
      refresh(session)
    elseif frame.scopes then
      fetch_registers(session, frame, state.generation)
    end
  end
  local function stop_view(session)
    if session ~= state.session then return end
    state.enabled = false
    state.generation = state.generation + 1
    dap.defaults.lldb.stepping_granularity = "statement"
    dap.defaults["lldb-dap"].stepping_granularity = "statement"
    close_view()
    state.session = nil
  end
  dap.listeners.before.event_terminated.assembly_view = stop_view
  dap.listeners.before.event_exited.assembly_view = stop_view
  dap.listeners.after.disconnect.assembly_view = stop_view
end

return M
