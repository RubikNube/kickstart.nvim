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

local function replace_note_links(lines, old_target, new_target)
    local changed = false
    local old_pattern = vim.pesc(old_target)
    local replacements = vim.tbl_map(function(line)
        local updated = line:gsub('%[%[' .. old_pattern .. '([#|][^%]]*)%]%]', '[[' .. new_target .. '%1]]')
        updated = updated:gsub('%[%[' .. old_pattern .. '%]%]', '[[' .. new_target .. ']]')
        changed = changed or updated ~= line
        return updated
    end, lines)

    return replacements, changed
end

local function update_note_links(old_target, new_target)
    local updated_files = 0
    local pending_buffers = 0
    local errors = {}

    for _, filepath in ipairs(vim.fn.globpath(vault, '**/*.md', false, true)) do
        filepath = vim.fs.normalize(filepath)
        local bufnr = vim.fn.bufnr(filepath)
        local loaded = bufnr ~= -1 and vim.api.nvim_buf_is_loaded(bufnr)
        local was_modified = loaded and vim.bo[bufnr].modified
        local ok, lines

        if loaded then
            ok = true
            lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
        else
            ok, lines = pcall(vim.fn.readfile, filepath)
        end

        if not ok then
            table.insert(errors, 'Could not read ' .. filepath)
        else
            local replacements, changed = replace_note_links(lines, old_target, new_target)
            if changed then
                if loaded then
                    local replace_ok, replace_error = pcall(vim.api.nvim_buf_set_lines, bufnr, 0, -1, false, replacements)
                    if not replace_ok then
                        table.insert(errors, 'Could not update ' .. filepath .. ': ' .. tostring(replace_error))
                    elseif was_modified then
                        pending_buffers = pending_buffers + 1
                    else
                        local write_ok, write_error = pcall(vim.api.nvim_buf_call, bufnr, function()
                            vim.cmd 'silent write'
                        end)
                        if write_ok then
                            updated_files = updated_files + 1
                        else
                            table.insert(errors, 'Could not update ' .. filepath .. ': ' .. tostring(write_error))
                        end
                    end
                else
                    local write_ok, write_result = pcall(vim.fn.writefile, replacements, filepath)
                    if write_ok and write_result == 0 then
                        updated_files = updated_files + 1
                    else
                        table.insert(errors, 'Could not update ' .. filepath)
                    end
                end
            end
        end
    end

    return updated_files, pending_buffers, errors
end

local function archive_current_note()
    local bufnr = vim.api.nvim_get_current_buf()
    local source = vim.fs.normalize(vim.api.nvim_buf_get_name(bufnr))
    local vault_prefix = vault .. '/'

    if source == '' or vim.bo[bufnr].buftype ~= '' or not source:match '%.md$' then
        vim.notify('Current buffer is not a Markdown note', vim.log.levels.ERROR)
        return
    end

    if not vim.startswith(source, vault_prefix) then
        vim.notify('Current note is outside the Zettelkasten vault', vim.log.levels.ERROR)
        return
    end

    local relative = source:sub(#vault_prefix + 1)
    if vim.startswith(relative, 'templates/') then
        vim.notify('Templates cannot be archived', vim.log.levels.ERROR)
        return
    end
    if vim.startswith(relative, 'archive/') then
        vim.notify('This note is already archived', vim.log.levels.WARN)
        return
    end

    local archive_directory = vault .. '/archive'
    local destination = archive_directory .. '/' .. vim.fs.basename(source)
    if vim.uv.fs_stat(destination) ~= nil or vim.fn.bufnr(destination) ~= -1 then
        vim.notify('Archive destination already exists: ' .. destination, vim.log.levels.ERROR)
        return
    end

    local old_target = relative:gsub('%.md$', '')
    local new_target = 'archive/' .. vim.fs.basename(source):gsub('%.md$', '')
    local prompt = string.format('Archive %s as %s?', relative, new_target .. '.md')

    vim.ui.select({ 'Archive', 'Cancel' }, { prompt = prompt }, function(choice)
        if choice ~= 'Archive' then
            return
        end

        if not vim.api.nvim_buf_is_valid(bufnr) or vim.fs.normalize(vim.api.nvim_buf_get_name(bufnr)) ~= source then
            vim.notify('The note changed before it could be archived', vim.log.levels.ERROR)
            return
        end
        if vim.uv.fs_stat(destination) ~= nil or vim.fn.bufnr(destination) ~= -1 then
            vim.notify('Archive destination already exists: ' .. destination, vim.log.levels.ERROR)
            return
        end

        local save_ok, save_error = pcall(vim.api.nvim_buf_call, bufnr, function()
            vim.cmd.write()
        end)
        if not save_ok then
            vim.notify('Could not save note before archiving: ' .. tostring(save_error), vim.log.levels.ERROR)
            return
        end

        vim.fn.mkdir(archive_directory, 'p')
        if vim.fn.isdirectory(archive_directory) ~= 1 then
            vim.notify('Could not create archive directory: ' .. archive_directory, vim.log.levels.ERROR)
            return
        end

        local moved, move_error = vim.uv.fs_rename(source, destination)
        if not moved then
            vim.notify('Could not archive note: ' .. tostring(move_error), vim.log.levels.ERROR)
            return
        end

        local rename_ok, rename_error = pcall(vim.api.nvim_buf_set_name, bufnr, destination)
        if not rename_ok then
            local rolled_back, rollback_error = vim.uv.fs_rename(destination, source)
            local message = 'Could not rename note buffer: ' .. tostring(rename_error)
            if not rolled_back then
                message = message .. '; rollback failed: ' .. tostring(rollback_error)
            end
            vim.notify(message, vim.log.levels.ERROR)
            return
        end

        local updated_files, pending_buffers, errors = update_note_links(old_target, new_target)
        local message = string.format('Archived %s (%d linked file%s updated)', relative, updated_files, updated_files == 1 and '' or 's')
        if pending_buffers > 0 then
            message = message .. string.format('; %d modified buffer%s left unsaved', pending_buffers, pending_buffers == 1 and '' or 's')
        end
        vim.notify(message, #errors == 0 and vim.log.levels.INFO or vim.log.levels.WARN)
        if #errors > 0 then
            vim.notify(table.concat(errors, '\n'), vim.log.levels.WARN)
        end
    end)
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
    dependencies = {
        'nvim-telescope/telescope.nvim',
        'renerocksai/calendar-vim',
    },
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
        { '<leader>zc', '<cmd>Telekasten show_calendar<CR>', desc = '[Z]ettelkasten [C]alendar' },
        { '<leader>zz', '<cmd>Telekasten follow_link<CR>', desc = '[Z]ettelkasten follow link' },
        { '<leader>zn', '<cmd>Telekasten new_note<CR>', desc = '[Z]ettelkasten [N]ew note' },
        { '<leader>zb', '<cmd>Telekasten show_backlinks<CR>', desc = '[Z]ettelkasten [B]acklinks' },
        { '<leader>zt', '<cmd>Telekasten show_tags<CR>', desc = '[Z]ettelkasten [T]ags' },
        { '<leader>zj', create_ticket_note, desc = '[Z]ettelkasten new [J]ira ticket' },
        { '<leader>zm', create_meeting_note, desc = '[Z]ettelkasten new [M]eeting' },
        { '<leader>za', archive_current_note, desc = '[Z]ettelkasten [A]rchive current note' },
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
            plug_into_calendar = true,
            calendar_opts = {
                weeknm = 4,
                calendar_monday = 1,
                calendar_mark = 'left-fit',
            },
        }
    end,
}
