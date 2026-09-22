return {
    'nvim-telekasten/telekasten.nvim',
    cmd = 'Telekasten',
    dependencies = { 'nvim-telescope/telescope.nvim' },
    init = function()
        local vault = vim.fs.normalize(vim.fn.expand '~/zettelkasten')
        local templates = vault .. '/templates/'

        local group = vim.api.nvim_create_augroup('telekasten_updated_date', { clear = true })
        vim.api.nvim_create_autocmd('BufWritePre', {
            group = group,
            pattern = '*.md',
            desc = 'Update Zettelkasten frontmatter date',
            callback = function(args)
                local filename = vim.fs.normalize(vim.api.nvim_buf_get_name(args.buf))
                if not vim.startswith(filename, vault .. '/') or vim.startswith(filename, templates) then
                    return
                end

                local lines = vim.api.nvim_buf_get_lines(args.buf, 0, -1, false)
                if lines[1] ~= '---' then
                    return
                end

                for index = 2, #lines do
                    if lines[index] == '---' then
                        return
                    end

                    if lines[index]:match '^updated:%s*' then
                        local updated = 'updated: ' .. os.date '%Y-%m-%d'
                        if lines[index] ~= updated then
                            vim.api.nvim_buf_set_lines(args.buf, index - 1, index, false, { updated })
                        end
                        return
                    end
                end
            end,
        })
    end,
    keys = {
        { '<leader>z', '<cmd>Telekasten panel<CR>', desc = '[Z]ettelkasten command panel' },
        { '<leader>zf', '<cmd>Telekasten find_notes<CR>', desc = '[Z]ettelkasten [F]ind notes' },
        { '<leader>zg', '<cmd>Telekasten search_notes<CR>', desc = '[Z]ettelkasten [G]rep notes' },
        { '<leader>zd', '<cmd>Telekasten goto_today<CR>', desc = '[Z]ettelkasten to[D]ay' },
        { '<leader>zz', '<cmd>Telekasten follow_link<CR>', desc = '[Z]ettelkasten follow link' },
        { '<leader>zn', '<cmd>Telekasten new_note<CR>', desc = '[Z]ettelkasten [N]ew note' },
        { '<leader>zb', '<cmd>Telekasten show_backlinks<CR>', desc = '[Z]ettelkasten [B]acklinks' },
        { '<leader>zt', '<cmd>Telekasten show_tags<CR>', desc = '[Z]ettelkasten [T]ags' },
        { '<leader>zi', '<cmd>Telekasten insert_link<CR>', desc = '[Z]ettelkasten [I]nsert link' },
        { '<leader>zy', '<cmd>Telekasten yank_notelink<CR>', desc = '[Z]ettelkasten [Y]ank note link' },
        { '<leader>zr', '<cmd>Telekasten rename_note<CR>', desc = '[Z]ettelkasten [R]ename note' },
        { '<leader>zx', '<cmd>Telekasten toggle_todo<CR>', desc = '[Z]ettelkasten toggle todo' },
        {
            '<leader>zN',
            function()
                require('telekasten').new_note { home = vim.fn.expand '~/zettelkasten/inbox' }
            end,
            desc = '[Z]ettelkasten new i[N]box note',
        },
        {
            '<leader>zp',
            function()
                require('telekasten').new_note { home = vim.fn.expand '~/zettelkasten/projects' }
            end,
            desc = '[Z]ettelkasten new [P]roject note',
        },
        { '[[', '<cmd>Telekasten insert_link<CR>', mode = 'i', desc = 'Insert Telekasten link' },
    },
    opts = function()
        local home = vim.fn.expand '~/zettelkasten'

        return {
            home = home,
            dailies = home .. '/journal/daily',
            templates = home .. '/templates',
            template_new_note = home .. '/templates/note.md',
            template_new_daily = home .. '/templates/daily.md',
            image_subdir = 'attachments',
            new_note_filename = 'title',
        }
    end,
}
