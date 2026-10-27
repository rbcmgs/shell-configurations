# Shell configuration (bash)
# Only customise interactive shells
case $- in
  *i*) ;;
  *) return ;;
esac

# History: large, deduplicated, shared across sessions
HISTSIZE=10000
HISTFILESIZE=20000
HISTCONTROL=ignoreboth:erasedups
shopt -s histappend checkwinsize globstar 2>/dev/null

# Starship prompt (init last so it wraps PROMPT_COMMAND)
if command -v starship >/dev/null 2>&1; then
  export STARSHIP_CONFIG="${STARSHIP_CONFIG:-$HOME/.config/starship.toml}"
  eval "$(starship init bash)"
fi

# GitHub Copilot CLI completion
if command -v copilot >/dev/null 2>&1; then
  _copilot_cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/copilot"
  _copilot_completion_file="${_copilot_cache_dir}/completion.bash"
  mkdir -p "$_copilot_cache_dir"

  if [ ! -s "$_copilot_completion_file" ] || [ "$(command -v copilot)" -nt "$_copilot_completion_file" ]; then
    copilot completion bash > "$_copilot_completion_file" 2>/dev/null || true
  fi

  [ -s "$_copilot_completion_file" ] && . "$_copilot_completion_file"
fi

# Machine-specific overrides (not tracked in git)
[ -f "$HOME/.bashrc.local" ] && . "$HOME/.bashrc.local"
