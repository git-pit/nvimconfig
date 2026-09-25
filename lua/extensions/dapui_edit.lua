local M = {}

function M.setup()
  if M.installed then return end
  M.installed = true
  local canvas = require("dapui.render.canvas")
  local canvas_mt = getmetatable(canvas.new())
  local render_buffer = canvas_mt.render_buffer
  local pending = {}

  function canvas_mt:render_buffer(buffer, action_keys)
    local prompt = self.prompt
    if not prompt or prompt.fill == nil then
      return render_buffer(self, buffer, action_keys)
    end

    -- DAP UI's inline edit turns the panel into a prompt buffer. Keep the
    -- panel read-only and collect edits through vim.ui.input instead.
    self.prompt = nil
    local rendered = render_buffer(self, buffer, action_keys)
    if rendered and not pending[buffer] then
      pending[buffer] = true
      vim.schedule(function()
        vim.ui.input({ prompt = "Edit: ", default = prompt.fill }, function(value)
          pending[buffer] = nil
          -- Calling back with the original value also clears DAP UI's edit
          -- state when the input is cancelled.
          prompt.callback(value == nil and prompt.fill or value)
        end)
      end)
    end
    return rendered
  end
end

return M
