local vault = vim.fs.normalize(vim.fn.expand '~/zettelkasten')
local note_template = vault .. '/templates/note.md'
local meeting_template = vault .. '/templates/meeting.md'
local ticket_template = vault .. '/templates/ticket.md'

local function render_template(template, replacements)
    if vim.fn.filereadable(template) ~= 1 then
        vim.notify('Telekasten note template not found: ' .. template, vim.log.levels.ERROR)
        return
    end

    return vim.tbl_map(function(line)
        for name, value in pairs(replacements) do
            line = line:gsub('{{' .. name .. '}}', function()
                return value
            end)
        end
        return line
    end, vim.fn.readfile(template))
end

local function write_note(filepath, template, replacements)
    if vim.fn.filereadable(filepath) == 1 then
        vim.cmd.edit(vim.fn.fnameescape(filepath))
        return true
    end

    local lines = render_template(template, replacements)
    if lines == nil then
        return false
    end

    vim.fn.mkdir(vim.fs.dirname(filepath), 'p')
    if vim.fn.writefile(lines, filepath) ~= 0 then
        vim.notify('Could not create note: ' .. filepath, vim.log.levels.ERROR)
        return false
    end

    vim.cmd.edit(vim.fn.fnameescape(filepath))
    return true
end

local function yaml_escape(value)
    return value:gsub('\\', '\\\\'):gsub('"', '\\"')
end

local function create_note_in(directory, options)
    directory = vim.fs.normalize(directory)
    options = options or {}

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

        local date = os.date '%Y-%m-%d'
        local filename = options.filename and options.filename(title, date) or title
        local filepath = vim.fs.normalize(directory .. '/' .. filename .. '.md')
        if not vim.startswith(filepath, directory .. '/') then
            vim.notify('Note title cannot leave the target directory', vim.log.levels.ERROR)
            return
        end

        local shorttitle = vim.fn.fnamemodify(title, ':t')
        if shorttitle == '' or shorttitle == '.' or shorttitle == '..' then
            vim.notify('Note title must include a filename', vim.log.levels.ERROR)
            return
        end

        write_note(filepath, options.template or note_template, {
            title = title,
            shorttitle = shorttitle,
            yaml_title = yaml_escape(shorttitle),
            date = date,
        })
    end)
end

local function create_meeting_note()
    create_note_in(vault .. '/meeting', {
        template = meeting_template,
        filename = function(title, date)
            return date .. ' ' .. title
        end,
    })
end

local function create_ticket_note()
    local jira_base_url = vim.trim(vim.env.JIRA_BASE_URL or ''):gsub('/+$', '')
    if jira_base_url == '' then
        vim.notify('JIRA_BASE_URL is not set', vim.log.levels.ERROR)
        return
    end

    vim.ui.input({ prompt = 'Jira ticket: ' }, function(input)
        if input == nil then
            return
        end

        local ticket = vim.trim(input):upper()
        if ticket == '' then
            return
        end

        if not ticket:match '^[A-Z][A-Z0-9_]*%-%d+$' then
            vim.notify('Invalid Jira ticket key: ' .. ticket, vim.log.levels.ERROR)
            return
        end

        local filepath = vault .. '/tickets/' .. ticket .. '.md'
        if vim.fn.filereadable(filepath) == 1 then
            vim.cmd.edit(vim.fn.fnameescape(filepath))
            return
        end

        vim.ui.input({ prompt = 'Summary: ' }, function(summary_input)
            if summary_input == nil then
                return
            end

            local summary = vim.trim(summary_input)
            if summary == '' then
                return
            end

            local jira_url = jira_base_url .. '/browse/' .. ticket
            write_note(filepath, ticket_template, {
                title = yaml_escape(ticket .. ': ' .. summary),
                ticket = ticket,
                summary = summary,
                yaml_summary = yaml_escape(summary),
                jira_url = jira_url,
                date = os.date '%Y-%m-%d',
            })
        end)
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
        { '<leader>zj', create_ticket_note, desc = '[Z]ettelkasten new [J]ira ticket' },
        { '<leader>zm', create_meeting_note, desc = '[Z]ettelkasten new [M]eeting' },
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
