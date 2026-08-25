# bashmix: bash 配色 + agnoster 色块（无箭头），两行式 prompt
# 第一行: user@host(绿) 路径(蓝底白字) git 分支(黄底黑字)
# 第二行: $ (root 时为 #)
#
# 安装: 复制到 ~/.oh-my-zsh/custom/themes/bashmix.zsh-theme
#       然后在 ~/.zshrc 中设置 ZSH_THEME="bashmix"

autoload -Uz vcs_info add-zsh-hook
setopt prompt_subst

zstyle ':vcs_info:*' formats '%b'
zstyle ':vcs_info:*' actionformats '%b (%a)'

_bashmix_precmd() {
  vcs_info
  local branch=''
  if [[ -n ${vcs_info_msg_0_} ]]; then
    branch="%K{yellow}%F{black} ${vcs_info_msg_0_} %k%f"
  fi
  local conda_env=''
  if [[ -n ${CONDA_DEFAULT_ENV} ]]; then
    conda_env="(${CONDA_DEFAULT_ENV})%f "
  fi
  PROMPT="${conda_env}%F{green}%n@%m%f:%K{blue}%F{white} %~ %k%f${branch}
%(!.%F{red}#.$) "
}
add-zsh-hook precmd _bashmix_precmd
