local dap = require 'dap'
dap.configurations.go = {
    {
        type = 'go',
        name = 'Debug',
        request = 'launch',
        program = '${file}',
        console = 'internalConsole',
        args = {},
    },
}
