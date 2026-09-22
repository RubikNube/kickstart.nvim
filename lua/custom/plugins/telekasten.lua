local vault = vim.fs.normalize(vim.fn.expand '~/zettelkasten')
local note_template = vault .. '/templates/note.md'

local function create_note_in(directory)
    directory = vim.fs.normalize(directory)

    vim.ui.input({ prompt = 'Title: ', completion = 'file' }, function(input)
        if input == nil then
            return
        end

        local title = vim.trim(input):gsub('%.md$', '')
        if title == '' then
            return
        end

        if title:match '^[/~]' or title:match '^%a:[/\\]' then
            vim.notify('Note title must be relative to the target directory', vim.log.levels.ERROR)
            return
        end

        local filepath = vim.fs.normalize(directory .. '/' .. title .. '.md')
        if not vim.startswith(filepath, directory .. '/') then
            vim.notify('Note title cannot leave the target directory', vim.log.levels.ERROR)
            return
        end

        if vim.fn.filereadable(filepath) == 1 then
            vim.cmd.edit(vim.fn.fnameescape(filepath))
            return
        end

        if vim.fn.filereadable(note_template) ~= 1 then
            vim.notify('Telekasten note template not found: ' .. note_template, vim.log.levels.ERROR)
            return
        end

        local shorttitle = vim.fn.fnamemodify(title, ':t')
        if shorttitle == '' or shorttitle == '.' or shorttitle == '..' then
            vim.notify('Note title must include a filename', vim.log.levels.ERROR)
            return
        end

        local date = os.date '%Y-%m-%d'
        local lines = vim.tbl_map(function(line)
            return line
                :gsub('{{title}}', function()
                    return title
                end)
                :gsub('{{shorttitle}}', function()
                    return shorttitle
                end)
                :gsub('{{date}}', function()
                    return date
                end)
        end, vim.fn.readfile(note_template))

        vim.fn.mkdir(vim.fs.dirname(filepath), 'p')
        if vim.fn.writefile(lines, filepath) ~= 0 then
            vim.notify('Could not create note: ' .. filepath, vim.log.levels.ERROR)
            return
        end

        vim.cmd.edit(vim.fn.fnameescape(filepath))
    end)
end

return {
    'nvim-telekasten/telekasten.nvim',
    cmd = 'Telekasten',
    dependencies = { 'nvim-telescope/telescope.nvim' },
    init = function()
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
                create_note_in(vault .. '/inbox')
            end,
            desc = '[Z]ettelkasten new i[N]box note',
        },
        {
            '<leader>zp',
            function()
                create_note_in(vault .. '/projects')
            end,
            desc = '[Z]ettelkasten new [P]roject note',
        },
        { '[[', '<cmd>Telekasten insert_link<CR>', mode = 'i', desc = 'Insert Telekasten link' },
    },
    opts = function()
        return {
            home = vault,
            dailies = vault .. '/journal/daily',
            templates = vault .. '/templates',
            template_new_note = note_template,
            template_new_daily = vault .. '/templates/daily.md',
            image_subdir = 'attachments',
            new_note_filename = 'title',
        }
    end,
}
