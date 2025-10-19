# --------------------------------------------------------------------
#               CORRECTED AND REORGANIZED .zshrc
# --------------------------------------------------------------------

# --- ZSH/OMZ Configuration (Keep this at the top) ---
# Path to your oh-my-zsh installation.
export ZSH=/Users/asnead/.oh-my-zsh

# Set name of the theme to load.
ZSH_THEME="robbyrussell"

# CORRECTED PLUGINS: You were overwriting the plugins array.
# Combine all desired plugins into a single line.
plugins=(
  git
  osx
  terminalapp
)

# --- Exports & PATH settings (Group these for clarity) ---
export PATH="/opt/homebrew/opt/openjdk/bin:$PATH"
export PATH="$PATH:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/sbin:/Users/asnead/.composer/vendor/bin"
export ANDROID_HOME=$HOME/Library/Android/sdk
export PATH=$PATH:$ANDROID_HOME/tools
export PATH=$PATH:$ANDROID_HOME/tools/bin
export PATH=$PATH:$ANDROID_HOME/platform-tools
export PYTHON_HOME=$HOME/Library/Python/3.7
export PATH=$PATH:$PYTHON_HOME/bin
export PATH="/usr/local/bin:/usr/local/sbin:$PATH"
export PATH="/usr/local/opt/ruby/bin:$PATH"
export PATH="/usr/local/lib/ruby/gems/2.6.0/bin:$PATH"
export PATH=$HOME/bin:/opt/homebrew/bin:/usr/local/bin:$PATH

export TERMINFO='/usr/share/terminfo/'
export TERM=xterm-256color
export EDITOR='vim'
export JWT_SECRET=example
export NVM_DIR="$HOME/.nvm"
export PNPM_HOME="/Users/asnead/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac

# --- Load Custom Functions and Completions *BEFORE* OMZ ---
# This is the most important change. We load your custom files and
# configure fpath before OMZ runs compinit.

# 1. Add homebrew zsh site functions to fpath
fpath=(/opt/homebrew/share/zsh/site-functions $fpath)

# 2. Source your custom git helper functions
if [ -f "$HOME/.zsh_functions/git_worktree_helpers.sh" ]; then
  source "$HOME/.zsh_functions/git_worktree_helpers.sh"
fi

if [ -f "$HOME/.zsh_functions/dotfiles_helpers.sh" ]; then
  source "$HOME/.zsh_functions/dotfiles_helpers.sh"
fi

# --- Source Oh My Zsh (This runs compinit and must be near the end) ---
# It will automatically initialize the completion system using the fpath
# and functions we defined above.
source $ZSH/oh-my-zsh.sh


# --- Post-OMZ settings & Completions (NVM, GCloud, etc.) ---
# These tools often need to be initialized after the main shell is ready.

# NVM
. "/usr/local/opt/nvm/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# Google Cloud SDK
if [ -f '/Users/asnead/google-cloud-sdk/path.zsh.inc' ]; then . '/Users/asnead/google-cloud-sdk/path.zsh.inc'; fi
if [ -f '/Users/asnead/google-cloud-sdk/completion.zsh.inc' ]; then . '/Users/asnead/google-cloud-sdk/completion.zsh.inc'; fi

# Tabtab completions for Serverless
[[ -f /Users/asnead/.nvm/versions/node/v8.11.4/lib/node_modules/serverless/node_modules/tabtab/.completions/serverless.zsh ]] && . /Users/asnead/.nvm/versions/node/v8.11.4/lib/node_modules/serverless/node_modules/tabtab/.completions/serverless.zsh
[[ -f /Users/asnead/.nvm/versions/node/v8.11.4/lib/node_modules/serverless/node_modules/tabtab/.completions/sls.zsh ]] && . /Users/asnead/.nvm/versions/node/v8.11.4/lib/node_modules/serverless/node_modules/tabtab/.completions/sls.zsh
[[ -f /Users/asnead/.nvm/versions/node/v8.11.4/lib/node_modules/serverless/node_modules/tabtab/.completions/slss.zsh ]] && . /Users/asnead/.nvm/versions/node/v8.11.4/lib/node_modules/serverless/node_modules/tabtab/.completions/slss.zsh

# --- Aliases (can go anywhere, but end is fine) ---
alias python='python3'
alias vim='nvim'
alias mvim='/Applications/MacVim.app/Contents/MacOS/Vim'
alias fnd='grep -iR --exclude-dir=node_modules'
alias hg='history | grep'
alias dotfiles='/usr/local/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'

# uv
export PATH="/Users/asnead/.local/bin:$PATH"
