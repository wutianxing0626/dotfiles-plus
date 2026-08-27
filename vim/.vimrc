" ============================================================
" ~/.vimrc —— Vim 学习期配置
" 原则:只留看得懂的配置;想加新选项先 :help 看懂再加
" 生成:2026-08-14(vim 8.2,未编译 +clipboard)
" ============================================================

" ===== 显示 =====
syntax on                 " 语法高亮
set number                " 显示行号
set relativenumber        " 混合模式:当前行显示绝对行号,其他行显示相对行号
set showcmd               " 右下角实时显示正在输入的命令
" set cursorline            " 高亮当前行,方便定位
" set cursorlineopt=number
set laststatus=2
set statusline=%<%F%r\ %h%m%r%=%14.(%l,%c%V%)\ %P\ %{strftime(\"%H:%M\")}

" ===== 缩进 =====
" set expandtab             " 按 Tab 键插入空格
set tabstop=4             " 一个 Tab 显示为 4 个空格宽
set shiftwidth=4          " >> / << 和自动缩进的步长
filetype plugin indent on " 按文件类型应用缩进规则
set noexpandtab

" ===== 搜索 =====
set ignorecase            " 搜索忽略大小写
set smartcase             " 搜索词含大写字母时,改为区分大小写
set incsearch             " 边输入边高亮
set hlsearch              " 高亮所有匹配处

" ===== 编辑体验 =====
set scrolloff=5           " 光标距上下边缘 5 行内才开始滚动
set wildmenu              " 命令行 Tab 补全显示菜单
set showmatch             " 输入右括号时短暂高亮对应左括号(配合 % 练习)
set backspace=indent,eol,start  " 退格键可以删缩进、换行符、行首的内容
set noeb " 去除输入错误提示

" ===== 中文编码 =====
set fileencodings=utf-8,gb18030,gbk  " 打开文件按此顺序尝试编码,GBK 中文不乱码

" ===== 系统剪贴板 =====
" 本机 vim 未编译 +clipboard,先注释掉;想要可用 vim-gtk3 或改用 nvim
" set clipboard=unnamedplus
