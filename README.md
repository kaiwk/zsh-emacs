# Emacs plugin

**NOTE:** This plugin is forked from [ohmyzsh](https://github.com/ohmyzsh/ohmyzsh), made plugin-manager agnostic and added few more features.

This plugin utilizes the Emacs daemon capability, allowing the user to quickly open frames, whether they are opened in a terminal via a ssh connection, or X frames opened on the same host. The plugin also provides some aliases for such operations.

- You don't have the cost of starting Emacs all the time anymore
- Opening a file is as fast as Emacs does not have anything else to do.
- You can share opened buffers across opened frames.
- Configuration changes made at runtime are applied to all frames.

**NOTE:** requires Emacs 24 and newer.

To Install:

```zsh
# Zplugin
zplugin load flinner/zsh-emacs

# Antigen (not tested)
antigen bundle flinner/zsh-emacs
```

## Aliases

The plugin uses a custom launcher (which we'll call here `$EMACS_LAUNCHER`) that is just a wrapper around [`emacsclient`](https://www.emacswiki.org/emacs/EmacsClient).

| Alias  | Command                                            | Description                               |
| ------ | -------------------------------------------------- | ----------------------------------------- |
| emacs  | `$EMACS_LAUNCHER --no-wait`                        | Opens a temporary emacsclient frame       |
| e      | `emacs`                                            | Same as emacs alias                       |
| te     | `$EMACS_LAUNCHER -nw`                              | Open terminal emacsclient                 |
| eeval  | `$EMACS_LAUNCHER --eval`                           | Same as `M-x eval` but from outside Emacs |
| eframe | `emacsclient --alternate-editor "" --create-frame` | Create new X frame                        |

## Functions

| Function | Description                                                          |
| -------- | -------------------------------------------------------------------- |
| efile    | Print the path to the file open in the current buffer                |
| ecd      | Print the directory of the file open in the current buffer           |
| cde      | cd to the directory of the file open in the current buffer           |
| ediff    | Compare two files with Emacs ediff                                   |
| magit    | Open magit-status for DIR (default: current directory) in a terminal frame |

These query the running Emacs daemon, so the "current buffer" is the
selected window of whichever frame was last active. `cde` is just
`cd "$(ecd)"`, jumping the shell to the directory of the file you're
editing.

## Reading from stdin

Pipe anything into `e -` (or `te -` for a terminal frame) and the
launcher writes it to a temporary file and opens that in Emacs:

```zsh
grep -rn TODO src/ | e -
```
