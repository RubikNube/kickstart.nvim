return {
    'CopilotC-Nvim/CopilotChat.nvim',
    dependencies = {
        { 'github/copilot.vim' }, -- or zbirenbaum/copilot.lua
        { 'nvim-lua/plenary.nvim', branch = 'master' }, -- for curl, log and async functions
    },
    build = 'make tiktoken', -- Only on MacOS or Linux
    opts = {
        -- See Configuration section for options
    },
    vim.keymap.set('n', '<leader>cc', '<cmd>CopilotChatToggle<CR>', { desc = '[C]opilot [C]hat Toggle' }),
    vim.keymap.set('v', '<leader>ce', ':CopilotChatExplain<CR>', { desc = '[C]opilot [E]xplain (visual)' }),
    vim.keymap.set('n', '<leader>cq', '<cmd>CopilotChatQuick<CR>', { desc = '[C]opilot [Q]uick Chat' }),
    vim.keymap.set('n', '<leader>c?', '<cmd>CopilotChat<CR>', { desc = '[C]opilot [C]hat' }),
    vim.keymap.set('n', '<leader>cf', '<cmd>CopilotChatFix<CR>', { desc = '[C]opilot [F]ix' }),
}
