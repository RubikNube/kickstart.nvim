return {
    'CopilotC-Nvim/CopilotChat.nvim',
    dependencies = {
        { 'github/copilot.vim' }, -- or zbirenbaum/copilot.lua
        { 'nvim-lua/plenary.nvim', branch = 'master' }, -- for curl, log and async functions
    },
    build = 'make tiktoken', -- Only on MacOS or Linux
    opts = {
        model = 'gpt-5.4',
    },
    vim.keymap.set('n', '<leader>cc', '<cmd>CopilotChatToggle<CR>', { desc = '[C]opilot [C]hat Toggle' }),
    vim.keymap.set('n', '<leader>cm', '<cmd>CopilotChatModel<CR>', { desc = '[C]opilot [M]odel' }),
    vim.keymap.set('n', '<leader>cg', '<cmd>CopilotChatCommit<CR>', { desc = '[C]opilot [G]it Commit' }),
    vim.keymap.set('v', '<leader>cf', '<cmd>CopilotChatFix<CR>', { desc = '[C]opilot [F]ix' }),
    vim.keymap.set('v', '<leader>ce', ':CopilotChatExplain<CR>', { desc = '[C]opilot [E]xplain (visual)' }),
    vim.keymap.set('v', '<leader>co', '<cmd>CopilotChatOptimize<CR>', { desc = '[C]opilot [O]ptimize' }),
    vim.keymap.set('v', '<leader>cp', '<cmd>CopilotChatPrompt<CR>', { desc = '[C]opilot [P]rompt' }),
    vim.keymap.set('v', '<leader>ct', '<cmd>CopilotChatTest<CR>', { desc = '[C]opilot [T]est' }),
    vim.keymap.set(
        'n',
        '<leader>cD',
        '<cmd>CopilotChat #buffers:visible Create a data flow diagram in mermaid syntax for the current opened file<CR>',
        { desc = '[C]opilot Create [D]ata flow diagram (mermaid)' }
    ),
    vim.keymap.set(
        'n',
        '<leader>cR',
        '<cmd>CopilotChat #buffers:listed ##git://diff/staged Review the staged changes and provide feedback on potential issues or improvements. Focus on: correctness, edge cases, security, performance, readability, maintainability. Call out potential bugs and suggest concrete improvements.<CR>',
        { desc = '[C]opilot [R]eview staged changes' }
    ),
}
