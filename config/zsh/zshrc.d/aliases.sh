# vim:fileencoding=utf-8:ft=bash:foldmethod=marker
alias g=git
alias gst='git status'
alias gp='git push'
alias gl='git pull'
alias gf='git fetch'
alias glog='git log --oneline --decorate'
alias gd='git diff -w --minimal'
alias gds='git diff -w --staged --minimal'
alias gc='git commit'
alias amend='git commit --amend'
alias gca='git add -A && git commit'
# ls aliases
alias ls='ls -G'
alias ll='ls -lagh'
alias la='ls -a1'
alias l='ls -a1'
alias t='tree -L 3'
# other
alias prof='PS4='"'"'$(date "+%s.%N ($LINENO) + ")'"'"' bash -x '
alias vi=nvim
alias vvi='command vi'
alias viu='nvim -u NONE'
alias todo=todo.sh
alias rm-nvim-history='rm ~/.local/state/nvim/swap/*'
alias mkidr='mkdir -p'
alias n='npm run'
alias run='npx tsx'
# not in vim but who cares
alias :q='exit'
alias :qa='exit'
alias :x='exit'
alias :xa='exit'
# source entry file
alias zs='source ~/.zshrc'
alias bs='source ~/.bashrc'
# opencode
alias oc="opencode"
alias gpt4mini='oc run -m openrouter/openai/gpt-4.1-mini --agent build "$@"'
alias gpt5codex='oc run -m openrouter/openai/gpt-5-codex --agent build "$@"'
alias claudeopus41='oc run -m openrouter/anthropic/claude-opus-4.1 --agent build "$@"'
alias gemini25flash='oc run -m openrouter/google/gemini-2.5-flash --agent build "$@"'
