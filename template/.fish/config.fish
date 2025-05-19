# Source the user's global config.fish if it exists
if test -f ~/.config/fish/config.fish
    source ~/.config/fish/config.fish
end

# Now add/override project-specific settings below
# e.g.
set -gx PROJECT_NAME "your_project"
source (dirname (status --current-filename))/aliases.fish
