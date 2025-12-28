-- Clear highlights on search when pressing <Esc> in normal mode
--  See `:help hlsearch`
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

-- Diagnostic keymaps
vim.keymap.set('n', '<leader>ql', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix [L]ist' })

vim.keymap.set('n', '<leader>pv', vim.cmd.Ex)
vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, { desc = '[C]ode [A]ction' })
-- Exit terminal mode in the builtin terminal with a shortcut that is a bit easier
-- for people to discover. Otherwise, you normally need to press <C-\><C-n>, which
-- is not what someone will guess without a bit more experience.
--
-- NOTE: This won't work in all terminal emulators/tmux/etc. Try your own mapping
-- or just use <C-\><C-n> to exit terminal mode
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

-- TIP: Disable arrow keys in normal mode
vim.keymap.set('n', '<left>', '<cmd>echo "Use h to move!!"<CR>')
vim.keymap.set('n', '<right>', '<cmd>echo "Use l to move!!"<CR>')
vim.keymap.set('n', '<up>', '<cmd>echo "Use k to move!!"<CR>')
vim.keymap.set('n', '<down>', '<cmd>echo "Use j to move!!"<CR>')

-- Basic tab navigation
vim.keymap.set('n', '<leader>tt', '<cmd>tabnew<CR>', { desc = '[T]ab [T]abnew' })
vim.keymap.set('n', '<leader>to', '<cmd>tabonly<CR>', { desc = '[T]ab [O]nly' })
vim.keymap.set('n', '<leader>tc', '<cmd>tabclose<CR>', { desc = '[T]ab [C]lose' })
vim.keymap.set('n', '<leader>tp', '<cmd>tabprevious<CR>', { desc = '[T]ab [P]revious' })
vim.keymap.set('n', '<leader>tP', '<cmd>tabnext<CR>', { desc = '[T]ab [P]revious (reverse)' })
vim.keymap.set('n', '<leader>tn', '<cmd>tabnext<CR>', { desc = '[T]ab [N]ext' })
vim.keymap.set('n', '<leader>tN', '<cmd>tabprevious<CR>', { desc = '[T]ab [N]ext (revserse)' })
vim.keymap.set('n', '<leader>th', '<cmd>tabmove -1<CR>', { desc = '[T]ab Move Left (H)' })
vim.keymap.set('n', '<leader>tl', '<cmd>tabmove +1<CR>', { desc = '[T]ab Move Right (L)' })
vim.keymap.set('n', '<leader>t1', '<cmd>tabfirst<CR>', { desc = '[T]ab [1] First' })
vim.keymap.set('n', '<leader>t2', '<cmd>tabnext 2<CR>', { desc = '[T]ab [2] Next' })
vim.keymap.set('n', '<leader>t3', '<cmd>tabnext 3<CR>', { desc = '[T]ab [3] Next' })
vim.keymap.set('n', '<leader>t4', '<cmd>tabnext 4<CR>', { desc = '[T]ab [4] Next' })
vim.keymap.set('n', '<leader>t5', '<cmd>tabnext 5<CR>', { desc = '[T]ab [5] Next' })
vim.keymap.set('n', '<leader>t6', '<cmd>tabnext 6<CR>', { desc = '[T]ab [6] Next' })
vim.keymap.set('n', '<leader>t7', '<cmd>tabnext 7<CR>', { desc = '[T]ab [7] Next' })
vim.keymap.set('n', '<leader>t8', '<cmd>tabnext 8<CR>', { desc = '[T]ab [8] Next' })
vim.keymap.set('n', '<leader>t9', '<cmd>tablast<CR>', { desc = '[T]ab [9] Last' })

-- Basic path navigation
vim.keymap.set('n', '<leader>cdg', function()
    local dir = vim.fn.expand '%:p:h'
    vim.cmd.cd(dir)
    vim.notify('Changed directory to: ' .. dir)
end, { desc = '[C]hange [D]irectory [G]lobal to current file path' })
vim.keymap.set('n', '<leader>cdt', function()
    local dir = vim.fn.expand '%:p:h'
    vim.cmd.tcd(dir)
    vim.notify('Changed terminal directory to: ' .. dir)
end, { desc = '[C]hange [D]irectory of [T]ab to current file path' })

-- Keybinds to make split navigation easier.
--  Use CTRL+<hjkl> to switch between windows
--
--  See `:help wincmd` for a list of all window commands
vim.keymap.set('n', '<C-h>', '<C-w><C-h>', { desc = 'Move focus to the left window' })
vim.keymap.set('n', '<C-l>', '<C-w><C-l>', { desc = 'Move focus to the right window' })
vim.keymap.set('n', '<C-j>', '<C-w><C-j>', { desc = 'Move focus to the lower window' })
vim.keymap.set('n', '<C-k>', '<C-w><C-k>', { desc = 'Move focus to the upper window' })

vim.keymap.set('n', '[b', '<cmd>:bprevious<CR>', { desc = 'Switch to previous buffer.' })
vim.keymap.set('n', ']b', '<cmd>:bnext<CR>', { desc = 'Switch to next buffer.' })
vim.keymap.set('n', '[B', '<cmd>:bfirst<CR>', { desc = 'Switch to first buffer.' })
vim.keymap.set('n', ']B', '<cmd>:blast<CR>', { desc = 'Switch to last buffer.' })
-- Copy the quickfix list to the default buffer
vim.keymap.set('n', '<leader>qc', function()
    local qflist = vim.fn.getqflist()
    if #qflist == 0 then
        vim.notify 'Quickfix list is empty.'
        return
    end
    vim.fn.setreg('+', vim.fn.join(vim.fn.map(qflist, 'v:val.text'), '\n'))
    vim.notify 'Copied quickfix list to clipboard.'
end, { desc = '[Q]uickfix [C]opy to clipboard' })
vim.keymap.set('n', '<leader>cp', function()
    local path = vim.fn.expand '%:p'
    vim.fn.setreg('+', path)
    vim.notify('Copied path: ' .. path)
end, { desc = '[C]opy current [P]ath to clipboard' })
