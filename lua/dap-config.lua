vim.fn.sign_define('DapBreakpoint', { text = '🛑', texthl = '', linehl = '', numhl = '' })

local dap, dapui = require 'dap', require 'dapui'
local dapgo = require 'dap-go'
dapui.setup()
dapgo.setup()
dap.listeners.before.attach.dapui_config = function()
    dapui.open()
end
dap.listeners.before.launch.dapui_config = function()
    dapui.open()
end

dap.listeners.before.event_terminated.dapui_config = function()
    dapui.close()
end
dap.listeners.before.event_exited.dapui_config = function()
    dapui.close()
end

-- Debug key mappings:
-- <leader>dc : Continue/start debugging
vim.keymap.set('n', '<leader>dc', function()
    require('dap').continue()
end, { desc = '[D]ebug [C]ontinue' })

-- <leader>dn : Step over
vim.keymap.set('n', '<leader>dn', function()
    require('dap').step_over()
end, { desc = '[D]ebug Step [N]ext (Over)' })

-- <leader>di : Step into
vim.keymap.set('n', '<leader>di', function()
    require('dap').step_into()
end, { desc = '[D]ebug Step [I]nto' })

-- <leader>do : Step out
vim.keymap.set('n', '<leader>do', function()
    require('dap').step_out()
end, { desc = '[D]ebug Step [O]ut' })

-- <leader>db : Toggle breakpoint
vim.keymap.set('n', '<leader>db', function()
    require('dap').toggle_breakpoint()
end, { desc = '[D]ebug Toggle [B]reakpoint' })

-- <leader>dB : Set breakpoint with condition
vim.keymap.set('n', '<leader>dB', function()
    require('dap').set_breakpoint()
end, { desc = '[D]ebug Set [B]reakpoint (conditional)' })

-- <leader>dp : Open REPL
vim.keymap.set('n', '<leader>dp', function()
    require('dap').repl.open()
end, { desc = '[D]ebug [P]rompt (REPL)' })

-- <leader>dl : Run last debug session
vim.keymap.set('n', '<leader>dl', function()
    require('dap').run_last()
end, { desc = '[D]ebug [L]ast run' })

-- <leader>du : Open DAP UI
vim.keymap.set('n', '<leader>du', function()
    dapui.open()
end, { desc = '[D]ebug [U]I Open' })

-- <leader>dU : Close DAP UI
vim.keymap.set('n', '<leader>dU', function()
    dapui.close()
end, { desc = '[D]ebug [U]I Close' })
