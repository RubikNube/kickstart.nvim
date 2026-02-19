return {
    'RubikNube/loglens.nvim',
    event = 'BufRead',
    config = function()
        require('loglens').setup {
            patterns = {
                { regex = 'ERROR', fg = '#ffffff', bg = '#ff0000' },
                { regex = 'WARN', fg = '#000000', bg = '#ffff00' },
                { regex = 'INFO', fg = '#ffffff', bg = '#0000ff' },
                { regex = 'DEBUG', fg = '#000000', bg = '#00ffff' },
                { regex = 'timeout', fg = '#ffffff', bg = '#ff8800' },
                { regex = '^%s*//.*', fg = '#00ff00', bg = '#ffffff' }, -- Commented out lines
            },
        }
        -- Keybindings for LogLens commands
        vim.keymap.set('n', '<leader>lo', ':LogLensOpen<CR>', { desc = 'LogLens: Open analysis window' })
        vim.keymap.set('n', '<leader>lc', ':LogLensClose<CR>', { desc = 'LogLens: Close window' })
        vim.keymap.set('n', '<leader>lC', ':LogLensConfigure<Space>', { desc = 'LogLens: Configure pattern' })
        vim.keymap.set('n', '<leader>le', ':LogLensConfigureOpen<CR>', { desc = 'LogLens: Edit patterns (JSON)' })
        vim.keymap.set('n', '<leader>lE', ':LogLensConfigureClose<CR>', { desc = 'LogLens: Close pattern editor' })
        vim.keymap.set('n', '<leader>ll', ':LogLensLoad<CR>', { desc = 'LogLens: Load pattern config' })
        vim.keymap.set('n', '<leader>ls', ':LogLensSave<CR>', { desc = 'LogLens: Save pattern config' })
    end,
}
