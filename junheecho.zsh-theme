# vim:ft=zsh ts=2 sw=2 sts=2
#
# Junhee Cho's Theme
# An agnoster-inspired theme for ZSH
#
# # README
#
# In order for this theme to render correctly, you will need a
# [Powerline-patched font](https://gist.github.com/1595572).
#
# In addition, I recommend the
# [Solarized theme](https://github.com/altercation/solarized/) and, if you're
# using it on Mac OS X, [iTerm 2](http://www.iterm2.com/) over Terminal.app -
# it has significantly better color fidelity.
#
# # Goals
#
# The aim of this theme is to add useful features to agnoster's theme.

### Segment drawing
# A few utility functions to make it easy and re-usable to draw segmented prompts

CURRENT_BG='NONE'
if [[ -z "$PRIMARY_FG" ]]; then
	PRIMARY_FG=black
fi

# Characters
SEGMENT_SEPARATOR="\ue0b0"
REVERSE_SEGMENT_SEPARATOR="\ue0b2"
PLUSMINUS="\u00b1"
BRANCH="\ue0a0"
DETACHED="\u27a6"
CROSS="\u2718"
LIGHTNING="\u26a1"
GEAR="\u2699"

# Begin a segment
# Takes two arguments, background and foreground. Both can be omitted,
# rendering default background/foreground.
prompt_segment() {
  local bg fg rg
  [[ -n $1 ]] && bg="%K{$1}" || bg="%k"
  [[ -n $2 ]] && fg="%F{$2}" || fg="%f"
  [[ -n $1 ]] && rg="%F{$1}" || rg="%f"
  if [[ -z $REVERSE ]]; then
    if [[ $CURRENT_BG != 'NONE' && $CURRENT_BG != default && $1 != $CURRENT_BG ]]; then
      print -n "%{$bg%F{$CURRENT_BG}%}$SEGMENT_SEPARATOR%{$fg%}"
    else
      print -n "%{$bg%}%{$fg%}"
    fi
  else
    if [[ $1 != default && $1 != $CURRENT_BG ]]; then
      print -n "%{$rg%K{$CURRENT_BG}%}$REVERSE_SEGMENT_SEPARATOR%{$bg$fg%}"
    else
      print -n "%{$bg%}%{$fg%}"
    fi
  fi
  CURRENT_BG=$1
  [[ -n $3 ]] && print -n $3
}

# End the prompt, closing any open segments
prompt_end() {
  if [[ -n $CURRENT_BG && $CURRENT_BG != 'NONE' && $CURRENT_BG != default ]]; then
    print -n "%{%k%F{$CURRENT_BG}%}$SEGMENT_SEPARATOR"
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
  local user=`whoami`

  if [[ "$user" != "$DEFAULT_USER" || -n "$SSH_CONNECTION" ]]; then
    prompt_segment $PRIMARY_FG default " %(!.%{%F{yellow}%}.)$user@%m "
  fi
}

# Git: branch/detached head, dirty status
prompt_git() {
  local color ref
  is_dirty() {
    test -n "$(git status --porcelain --ignore-submodules)"
  }
  ref="$vcs_info_msg_0_"
  if [[ -n "$ref" ]]; then
    if is_dirty; then
      color=yellow
      ref="${ref} $PLUSMINUS"
    else
      color=green
      ref="${ref} "
    fi
    if [[ "${ref/.../}" == "$ref" ]]; then
      ref="$BRANCH $ref"
    else
      ref="$DETACHED ${ref/.../}"
    fi
    prompt_segment $color $PRIMARY_FG
    print -n " $ref"
  fi
}

# Dir: current working directory
prompt_dir() {
  prompt_segment blue $PRIMARY_FG ' %~ '
}

# Status:
# - was there an error
# - am I root
# - are there background jobs?
prompt_status() {
  local symbols
  symbols=()
  [[ $RETVAL -ne 0 ]] && symbols+="%{%F{red}%}$CROSS"
  [[ $UID -eq 0 ]] && symbols+="%{%F{yellow}%}$LIGHTNING"
  [[ $(jobs -l | wc -l) -gt 0 ]] && symbols+="%{%F{cyan}%}$GEAR"

  [[ -n "$symbols" ]] && prompt_segment $PRIMARY_FG default " $symbols "
}

# Display current virtual environment
prompt_virtualenv() {
  if [[ -n $VIRTUAL_ENV ]]; then
    color=cyan
    prompt_segment $color $PRIMARY_FG
    print -Pn " $(basename $VIRTUAL_ENV) "
  fi
}

# Display current time
prompt_time() {
  prompt_segment default white
  print -Pn " %D{%H:%M:%S} "
}

# Display running time of last command
prompt_runtime() {
  if [ -n "$TTY" ] && [ -z $prompt_repeated ] && [ $timer ]; then
    runtime=$(($SECONDS - $timer))
    prompt_segment green $PRIMARY_FG
    printf " "
    h=$(($runtime / 3600))
    m=$(($runtime % 3600 / 60))
    s=$(($runtime % 60))
    [[ $h -gt 0 ]] && f=1 && printf "%d hr. " h
    [[ $m -gt 0 || $f ]] && f=1 && printf "%d min. " m
    [[ $s -gt 0 || $f || $runtime -eq 0 ]] && printf "%d sec. " s
  fi
}

# Preprompt
prompt_junheecho_result() {
  prompt_runtime
  prompt_end
}

## Main prompt
prompt_junheecho_main() {
  RETVAL=$?
  CURRENT_BG='NONE'
  if [ -z $1 ]; then
    prompt_status
  fi
  prompt_context
  prompt_virtualenv
  prompt_dir
  prompt_git
  prompt_end
}

prompt_junheecho_right() {
  REVERSE=1
  prompt_time
}

prompt_junheecho_preexec() {
  timer=$SECONDS
  unset prompt_repeated
}

prompt_junheecho_precmd() {
  vcs_info
  PROMPT='%{%f%b%k%}'$(prompt_junheecho_result)$'\n''$(prompt_junheecho_main "'$prompt_repeated'") '
  RPROMPT='%{%f%b%k%}'$(prompt_junheecho_right)''
  prompt_repeated=1
}

prompt_junheecho_setup() {
  autoload -Uz add-zsh-hook
  autoload -Uz vcs_info

  prompt_opts=(cr subst percent)

  add-zsh-hook precmd prompt_junheecho_precmd
  add-zsh-hook preexec prompt_junheecho_preexec

  zstyle ':vcs_info:*' enable git
  zstyle ':vcs_info:*' check-for-changes false
  zstyle ':vcs_info:git*' formats '%b'
  zstyle ':vcs_info:git*' actionformats '%b (%a)'
}

prompt_junheecho_setup "$@"
