# direnv changes XDG_DATA_DIRS after Fish has initialized its search paths.
function __update_direnv_completions --on-variable XDG_DATA_DIRS
    for directory in $__direnv_completion_dirs
        set -l index (contains --index -- $directory $fish_complete_path)
        if test -n "$index"
            set -e fish_complete_path[$index]
        end
    end
    set -g __direnv_completion_dirs
    for directory in (string split : -- $XDG_DATA_DIRS)
        set -l completions "$directory/fish/vendor_completions.d"
        if test -d "$completions"; and not contains -- $completions $fish_complete_path
            set -ga __direnv_completion_dirs $completions
        end
    end
    set -p fish_complete_path $__direnv_completion_dirs
end
__update_direnv_completions
