#!/bin/sh

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
#!/bin/sh

emacsfun() {
  local cmd frames arg tty

  # Build the Emacs Lisp command to check for suitable frames
  # See https://www.gnu.org/software/emacs/manual/html_node/elisp/Frames.html#index-framep
  for arg in "$@"; do
    case "$arg" in
    -t|--tty|-nw) tty=1; break ;;
    esac
  done

  if [ -n "$tty" ]; then
    cmd="(memq 't (mapcar 'framep (frame-list)))" # if != nil, there are tty frames
  else
    cmd="(delete 't (mapcar 'framep (frame-list)))" # if != nil, there are graphical terminals (x, w32, ns)
  fi

  # A tty frame needs the client to stay attached, so drop the --no-wait the
  # `emacs` alias adds. Otherwise emacsclient returns at once and nothing opens.
  if [ -n "$tty" ]; then
    for arg do
      shift
      case "$arg" in
      --no-wait) continue ;;
      esac
      set -- "$@" "$arg"
    done
  fi

  # Check if there are suitable frames
  frames="$(emacsclient -a '' -n -e "$cmd" 2>/dev/null |sed 's/.*\x07//g' )"

  # A bare emacs/e passes only --no-wait, so it still needs --create-frame.
  if [ -z "$frames" ] || [ "$frames" = nil ] || [ "$#" -eq 0 ] \
    || { [ "$#" -eq 1 ] && [ "$1" = --no-wait ]; }; then
    emacsclient --alternate-editor="" --create-frame "$@"
    return $?
  fi

  emacsclient --alternate-editor="" "$@"
}

# Adapted from https://github.com/davidshepherd7/emacs-read-stdin/blob/master/emacs-read-stdin.sh
# If the second argument is - then write stdin to a tempfile and open the
# tempfile. (first argument will be `--no-wait` passed in by the plugin.zsh)
if [ $# -ge 2 -a "$2" = "-" ]; then
  # Create a tempfile to hold stdin
  tempfile="$(mktemp --tmpdir emacs-stdin-$USERNAME.XXXXXXX 2>/dev/null \
    || mktemp -t emacs-stdin-$USERNAME)" # support BSD mktemp
  # Redirect stdin to the tempfile
  cat - > "$tempfile"
  # Reset $2 to the tempfile so that "$@" works as expected
  set -- "$1" "$tempfile" "${@:3}"
fi

emacsfun "$@"
