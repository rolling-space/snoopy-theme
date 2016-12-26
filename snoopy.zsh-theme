# Eriner's Theme - fork of agnoster
# A Powerline-inspired theme for ZSH
#
# # README
#
# In order for this theme to render correctly, you will need a
# font with powerline symbols. A simple way to add the powerline
# symbols is to follow the instructions here:
# https://simplyian.com/2014/03/28/using-powerline-symbols-with-your-current-font/
#
# # Goals
#
# The aim of this theme is to only show you *relevant* information. Like most
# prompts, it will only show git information when in a git working directory.
# However, it goes a step further: everything from the current user and
# hostname to whether the last call exited with an error to whether background
# jobs are running in this shell will all be displayed automatically when
# appropriate.

### Segment drawing
# A few utility functions to make it easy and re-usable to draw segmented prompts

CURRENT_BG='NONE'
PRIMARY_FG=black

# NVM
if [ ! -n "${BULLETTRAIN_NVM_SHOW+1}" ]; then
  BULLETTRAIN_NVM_SHOW=true
fi
if [ ! -n "${BULLETTRAIN_NVM_BG+1}" ]; then
  BULLETTRAIN_NVM_BG=green
fi
if [ ! -n "${BULLETTRAIN_NVM_FG+1}" ]; then
  BULLETTRAIN_NVM_FG=white
fi
if [ ! -n "${BULLETTRAIN_NVM_PREFIX+1}" ]; then
  BULLETTRAIN_NVM_PREFIX="⬡ "
fi

# RUBY
if [ ! -n "${BULLETTRAIN_RUBY_SHOW+1}" ]; then
  BULLETTRAIN_RUBY_SHOW=true
fi
if [ ! -n "${BULLETTRAIN_RUBY_BG+1}" ]; then
  BULLETTRAIN_RUBY_BG=magenta
fi
if [ ! -n "${BULLETTRAIN_RUBY_FG+1}" ]; then
  BULLETTRAIN_RUBY_FG=white
fi
if [ ! -n "${BULLETTRAIN_RUBY_PREFIX+1}" ]; then
  BULLETTRAIN_RUBY_PREFIX=♦️
fi

# Characters
function {
  local LC_ALL="" LC_CTYPE="en_US.UTF-8"
  SEGMENT_SEPARATOR="\ue0b0"
  RSEGMENT_SEPARATOR="\ue0b2"
  PLUSMINUS="\u00b1"
  BRANCH="\ue0a0"
  DETACHED="\u27a6"
  CROSS="\u2718"
  LIGHTNING="\u26a1"
  GEAR="\u2699"
}

short_pwd() {
  # shortens the pwd for use in prompt

  local current_dir="${1:-${PWD}}"
  local return_dir='~'

  current_dir="${current_dir/#${HOME}/~}"

# if we aren't in ~
  if [[ ${current_dir} != '~' ]]; then
    return_dir="${${${${(@j:/:M)${(@s:/:)current_dir}##.#?}:h}%/}//\%/%%}/${${current_dir:t}//\%/%%}"
  fi

  print ${return_dir}

}

# Begin a segment
# Takes two arguments, background and foreground. Both can be omitted,
# rendering default background/foreground.
prompt_segment() {
  local bg fg
  [[ -n ${1} ]] && bg="%K{${1}}" || bg="%k"
  [[ -n ${2} ]] && fg="%F{${2}}" || fg="%f"
  if [[ $CURRENT_BG != 'NONE' && ${1} != $CURRENT_BG ]]; then
    print -n "%{${bg}%F{${CURRENT_BG}}%}${SEGMENT_SEPARATOR}%{${fg}%}"
  else
    print -n "%{${bg}%}%{${fg}%}"
  fi
  CURRENT_BG=${1}
  [[ -n ${3} ]] && print -n ${3}
}

right_prompt_segment() {
  local bg fg
  [[ -n ${1} ]] && bg="%K{${1}}" || bg="%k"
  [[ -n ${2} ]] && fg="%F{${2}}" || fg="%f"
  if [[ $CURRENT_BG != 'NONE' && ${1} != $CURRENT_BG ]]; then
    print -n "%{${bg}%F{${CURRENT_BG}}%}${RSEGMENT_SEPARATOR}%{${fg}%}"
  else
    print -n "%{${bg}%}%{${fg}%}"
  fi
  CURRENT_BG=${1}
  [[ -n ${3} ]] && print -n ${3}
}

right_prompt_end() {
  if [[ -n $CURRENT_BG ]]; then
    print -n "%{%k%F{${CURRENT_BG}}%}${RSEGMENT_SEPARATOR}"
  else
    print -n "%{%k%}"
  fi
  print -n "%{%f%}"
  CURRENT_BG=''
}

# End the prompt, closing any open segments
prompt_end() {
  if [[ -n $CURRENT_BG ]]; then
    print -n "%{%k%F{${CURRENT_BG}}%}${SEGMENT_SEPARATOR}"
  else
    print -n "%{%k%}"
  fi
  print -n "%{%f%}"
  CURRENT_BG=''
}

### Prompt components
# Each component will draw itself, and hide itself if no information needs to be shown

# Context: user@hostname (who am I and where am I)
prompt_context() {
  if [[ ${USER} != ${DEFAULT_USER} || -n ${SSH_CONNECTION} ]]; then
    prompt_segment ${PRIMARY_FG} default " %(!.%{%F{yellow}%}.)${USER}@%m "
  fi
}

# Ranger: <https://github.com/ranger/ranger>, which can spawn ${SHELL}
# under its own process
prompt_ranger() {
  if [[ $((RANGER_LEVEL)) -ne 0 ]]; then
    local color=blue
    prompt_segment ${color} ${PRIMARY_FG}
    print -Pn " r"
  fi
}

# Git: branch/detached head, dirty status
prompt_git() {
  local color ref
  is_dirty() {
    test -n "$(command git status --porcelain --ignore-submodules)"
  }
  ref=${vcs_info_msg_0_}
  if [[ -n ${ref} ]]; then
    if is_dirty; then
      color=yellow
      ref="${ref} ${PLUSMINUS}"
    else
      color=green
      ref="${ref} "
    fi
    if [[ "${ref/.../}" == ${ref} ]]; then
      ref="${BRANCH} ${ref}"
    else
      ref="$DETACHED ${ref/.../}"
    fi
    prompt_segment ${color} ${PRIMARY_FG}
    print -Pn " ${ref}"
  fi
}

# Dir: current working directory
prompt_dir() {
  prompt_segment cyan ${PRIMARY_FG}
  print -Pn " $(short_pwd) "
}

# Status:
# - was there an error
# - am I root
# - are there background jobs?
prompt_status() {
  local symbols
  symbols=()
  [[ ${RETVAL} -ne 0 ]] && symbols+="%{%F{red}%}${CROSS}"
  [[ ${UID} -eq 0 ]] && symbols+="%{%F{yellow}%}${LIGHTNING}"
  [[ $(jobs -l | wc -l) -gt 0 ]] && symbols+="%{%F{cyan}%}${GEAR}"

  [[ -n ${symbols} ]] && prompt_segment ${PRIMARY_FG} default " ${symbols} "
}

prompt_git_super_status() {
  prompt_segment white green " $(git_super_status)"
}

right_prompt_ruby() {
  right_prompt_segment $BULLETTRAIN_RUBY_BG $BULLETTRAIN_RUBY_FG $BULLETTRAIN_RUBY_PREFIX" $(rbenv version-name) "
}

prompt_ruby() {
  prompt_segment $BULLETTRAIN_RUBY_BG $BULLETTRAIN_RUBY_FG $BULLETTRAIN_RUBY_PREFIX" $(rbenv version-name) "
}

right_prompt_nvm() {
  # if [[ $BULLETTRAIN_NVM_SHOW == false ]]; then
  #   return
  # fi
  # local nvm_prompt
  #
  # nvm_prompt=$(nvm current 2>/dev/null)
  # [[ "${nvm_prompt}x" == "x" ]] && return

  # nvm_prompt="${nvm_prompt}"
  right_prompt_segment $BULLETTRAIN_NVM_BG $BULLETTRAIN_NVM_FG $BULLETTRAIN_NVM_PREFIX"$(nvm current)"
}

prompt_nvm() {
  prompt_segment $BULLETTRAIN_NVM_BG $BULLETTRAIN_NVM_FG $BULLETTRAIN_NVM_PREFIX"$(nvm current)"
}

## Main prompt
prompt_eriner_main() {
  RETVAL=$?
  CURRENT_BG='NONE'
  prompt_status
  prompt_context
  prompt_ranger
  prompt_dir
  prompt_ruby
  # prompt_nvm
  prompt_git_super_status
  # prompt_git
  prompt_end
}

right_prompt_eriner_main() {
  RETVAL=$?
  CURRENT_BG='NONE'
  right_prompt_end
  prompt_ruby
  prompt_nvm
}

prompt_eriner_precmd() {
  PROMPT='%{%f%b%k%}$(prompt_eriner_main) '
  # RPROMPT='$(right_prompt_eriner_main)'
}

prompt_eriner_setup() {
  autoload -Uz add-zsh-hook
  # autoload -Uz vcs_info
  autoload -Uz git_super_status

  prompt_opts=(cr subst percent)

  add-zsh-hook precmd prompt_eriner_precmd

  # zstyle ':vcs_info:*' enable git
  # zstyle ':vcs_info:*' check-for-changes false
  # zstyle ':vcs_info:git*' formats '%b'
  # zstyle ':vcs_info:git*' actionformats '%b (%a)'
}

prompt_eriner_setup "$@"
