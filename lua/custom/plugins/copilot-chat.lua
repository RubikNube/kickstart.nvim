return {
    'CopilotC-Nvim/CopilotChat.nvim',
    dependencies = {
        { 'github/copilot.vim' }, -- or zbirenbaum/copilot.lua
        { 'nvim-lua/plenary.nvim', branch = 'master' }, -- for curl, log and async functions
    },
    build = 'make tiktoken', -- Only on MacOS or Linux
    opts = {
        model = 'gpt-5.2',
    },
    vim.keymap.set('n', '<leader>cc', '<cmd>CopilotChatToggle<CR>', { desc = '[C]opilot [C]hat Toggle' }),
    vim.keymap.set('n', '<leader>cm', '<cmd>CopilotChatModel<CR>', { desc = '[C]opilot [M]odel' }),
    vim.keymap.set('n', '<leader>cg', '<cmd>CopilotChatCommit<CR>', { desc = '[C]opilot [G]it Commit' }),
    vim.keymap.set('v', '<leader>cf', '<cmd>CopilotChatFix<CR>', { desc = '[C]opilot [F]ix' }),
    vim.keymap.set('v', '<leader>ce', ':CopilotChatExplain<CR>', { desc = '[C]opilot [E]xplain (visual)' }),
    vim.keymap.set('v', '<leader>co', '<cmd>CopilotChatOptimize<CR>', { desc = '[C]opilot [O]ptimize' }),
    vim.keymap.set('v', '<leader>cp', '<cmd>CopilotChatPrompt<CR>', { desc = '[C]opilot [P]rompt' }),
    vim.keymap.set('v', '<leader>ct', '<cmd>CopilotChatTest<CR>', { desc = '[C]opilot [T]est' }),
}
