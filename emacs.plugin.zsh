#MIT License

#Copyright (c) 2009-2021 Robby Russell and contributors (https://github.com/ohmyzsh/ohmyzsh/contributors)

#Permission is hereby granted, free of charge, to any person obtaining a copy
#of this software and associated documentation files (the "Software"), to deal
#in the Software without restriction, including without limitation the rights
#to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#copies of the Software, and to permit persons to whom the Software is
#furnished to do so, subject to the following conditions:

#The above copyright notice and this permission notice shall be included in all
#copies or substantial portions of the Software.

#THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
#SOFTWARE.
#
#
# ==========================================================================================
# Emacs 23 daemon capability is a killing feature.
# One emacs process handles all your frames whether
# you use a frame opened in a terminal via a ssh connection or X frames
# opened on the same host.

# Benefits are multiple
# - You don't have the cost of starting Emacs all the time anymore
# - Opening a file is as fast as Emacs does not have anything else to do.
# - You can share opened buffers across opened frames.
# - Configuration changes made at runtime are applied to all frames.

# Require emacs version to be minimum 24
autoload -Uz is-at-least
is-at-least 24 "${${(Az)"$(emacsclient --version 2>/dev/null)"}[2]}" || return 0

# Handle $0 according to the standard:
# https://zdharma-continuum.github.io/Zsh-100-Commits-Club/Zsh-Plugin-Standard.html
0="${${ZERO:-${0:#$ZSH_ARGZERO}}:-${(%):-%N}}"
0="${${(M)0:#/*}:-$PWD/$0}"

# Path to custom emacsclient launcher
export EMACS_PLUGIN_LAUNCHER="${0:A:h}/emacsclient.sh"

# set EDITOR if not already defined.
export EDITOR="${EDITOR:-${EMACS_PLUGIN_LAUNCHER}}"

alias emacs="$EMACS_PLUGIN_LAUNCHER --no-wait"
alias e=emacs
# open terminal emacsclient
alias te="$EMACS_PLUGIN_LAUNCHER -nw"

# same than M-x eval but from outside Emacs.
alias eeval="$EMACS_PLUGIN_LAUNCHER --eval"
# create a new X frame
alias eframe='emacsclient --alternate-editor="" --create-frame'

# Emacs ANSI Term tracking
local excluded_terms=(vterm ghostel)
local current_term="${INSIDE_EMACS%%,*}"
if [[ -n "$INSIDE_EMACS" ]] && (( ! ${excluded_terms[(Ie)$current_term]} )); then
  chpwd_emacs() { print -P "\033AnSiTc %d"; }
  print -P "\033AnSiTc %d"    # Track current working directory
  print -P "\033AnSiTu %n"    # Track username

  # add chpwd hook
  autoload -Uz add-zsh-hook
  add-zsh-hook chpwd chpwd_emacs
fi

# Write to standard output the path to the file
# opened in the current buffer.
function efile {
  local cmd="(buffer-file-name (window-buffer))"
  local file="$("$EMACS_PLUGIN_LAUNCHER" --eval "$cmd" | tr -d \")"

  if [[ -z "$file" ]]; then
    echo "Can't deduce current buffer filename." >&2
    return 1
  fi

  echo "$file"
}

# Write to standard output the directory of the file
# opened in the current buffer
function ecd {
  local file
  file="$(efile)" || return $?
  echo "${file:h}"
}

# Change the shell's working directory to the directory of the file
# opened in the current buffer.
function cde {
  local dir
  dir="$(ecd)" || return $?
  cd "$dir"
}

# Compare two files with Emacs ediff. Paths are made absolute because
# the daemon's working directory may differ from the shell's.
function ediff {
  if [[ $# -ne 2 ]]; then
    echo "Usage: ediff FILE1 FILE2" >&2
    return 1
  fi

  # Escape for the Emacs Lisp string literal.
  local a="${1:a}" b="${2:a}"
  a="${a//\\/\\\\}"; a="${a//\"/\\\"}"
  b="${b//\\/\\\\}"; b="${b//\"/\\\"}"

  # Run in a fresh frame: reusing the selected window can fail with
  # "window too small for splitting" when it is already heavily split.
  "$EMACS_PLUGIN_LAUNCHER" --create-frame --eval "(ediff-files \"$a\" \"$b\")"
}

# Open magit-status for DIR (default: the current directory) in a
# terminal frame. The directory is passed to Emacs instead of cd-ing
# the shell.
function magit {
  local dir="${1:-$PWD}"
  dir="${dir:a}"
  # Escape for the Emacs Lisp string literal.
  dir="${dir//\\/\\\\}"
  dir="${dir//\"/\\\"}"

  "$EMACS_PLUGIN_LAUNCHER" -nw --eval "(magit-status \"$dir\")"
}
