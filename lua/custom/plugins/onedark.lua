return {
    'navarasu/onedark.nvim',
    priority = 1002,
    config = function()
        require('onedark').setup {
            style = 'darker',
        }
    end,
    init = function()
        vim.cmd.colorscheme 'onedark'
    end,
}
