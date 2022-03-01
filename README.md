```
██╗     ██╗████████╗███████╗███████╗   ███╗   ██╗██╗   ██╗██╗███╗   ███╗
██║     ██║╚══██╔══╝██╔════╝██╔════╝   ████╗  ██║██║   ██║██║████╗ ████║ Lightweight
██║     ██║   ██║   █████╗  █████╗     ██╔██╗ ██║██║   ██║██║██╔████╔██║ Integrated
██║     ██║   ██║   ██╔══╝  ██╔══╝     ██║╚██╗██║╚██╗ ██╔╝██║██║╚██╔╝██║ Text
███████╗██║   ██║   ███████╗███████╗██╗██║ ╚████║ ╚████╔╝ ██║██║ ╚═╝ ██║ Editing
╚══════╝╚═╝   ╚═╝   ╚══════╝╚══════╝╚═╝╚═╝  ╚═══╝  ╚═══╝  ╚═╝╚═╝     ╚═╝ Environment
====================================================================================
```

![litee screenshot](./contrib/litee-screenshot.png)

# litee-bookmarks

litee-bookmarks utilizes the [litee.nvim](https://github.com/ldelossa/litee.nvim) library to 
implement plugin for creating and saving bookmarks for a project.

In `litee-bookmarks` `Bookmarks` are organized into `Notebooks`. 

Notebooks are tied to a source code repository. Therefore, when listing notebooks
you will only see notebooks created for the current source code root.

This means that to use this plugin correctly it expects you to open `neovim` at 
the root of your source code repository when working on that code.

It also means if you have a complex sub-directory in a source code repository which
you work on as an isolated entity, you can open `neovim` to this dir and create its
own isolated set of notebooks.

`Notebooks' can be created with the "LTCreateNotebook" command. 

You can open notebooks with the "LTOpenNotebook" command. 

Without any arguments this will list all notebooks associated with the currently
opened source code repository.

You can then use the `LTListNotebooks` to get a `vim.ui.select` promp which lists 
all created `Notebooks` for the currently opened source code repository.

Once a `Notebook` has been opened you can begin creating `Bookmarks` with the 
`LTCreateBookmark` command. 

You can remove a `Bookmark` by placing your cursor over it and issuing the 
`LTDeleteBookmark` command.

If you move a souce code repository to a new location you can use `LTMigrateNotebooks`
to move the associated notebooks as well.

Like all `litee.nvim` backed plugins the UI will work with other `litee.nvim` plugins, 
keeping its appropriate place in a collapsible panel.

# Usage

## Get it

Plug:
```
 Plug 'ldelossa/litee.nvim'
 Plug 'ldelossa/litee-bookmarks.nvim'
```

## Set it

Call the setup function from anywhere you configure your plugins from.

Configuration dictionary is explained in ./doc/litee-bookmarks.txt (:h litee-bookmarks-config)

```
-- configure the litee.nvim library 
require('litee.lib').setup({})
-- configure litee-bookmarks.nvim
require('litee.bookmarks').setup({})
```
