#!/usr/bin/env bash

set -eux

cd ~
mkdir -p .config
mkdir -p .gnupg
mkdir -p prog
mkdir -p _setup
pushd _setup

if ! [[ -f ~/.sec.key ]]; then
  echo "need: ~/.sec.key"
  exit 1
fi

# pkg
pkg update -y
pkg upgrade -y
pkg install -y \
  curl ca-certificates ffmpeg git \
  imagemagick jq \
  pinentry-tty pkg-config unar w3m wget zsh

# import key
gpg --list-keys | grep -q 8117 || {
  export GPG_TTY="$(tty)"
  echo "pinentry-program $(which pinentry-tty)" > ~/.gnupg/gpg-agent.conf
  chmod 600 ~/.gnupg/*
  chmod 700 ~/.gnupg
  gpgconf --kill gpg-agent
  sleep 3s
  cat ~/.sec.key | gpg --allow-secret-key --import
  pass init "$(gpg --with-colons --list-keys | awk -F: '$1=="fpr"{print$10;exit}')"
}

# nanorc
[[ -d ~/.nano ]] || {
  git clone --depth 1 --single-branch 'https://github.com/serialhex/nano-highlight' ~/.nano
}
cat <<'A'>~/.nanorc
include "~/.nano/*.nanorc"

set autoindent
set constantshow
set linenumbers
set tabsize 4
set softwrap

# Color
set titlecolor white,red
set numbercolor white,blue
set selectedcolor white,green
set statuscolor white,green
A

# mise
curl https://mise.run | sh
echo 'eval "$(/usr/local/bin/mise activate bash)"' >>~/.bashrc
echo 'eval "$(/usr/local/bin/mise activate zsh)"' >>~/.zshrc
eval "$(/usr/local/bin/mise activate zsh)"

# python
[[ -d ~/.pyenv ]] || {
  mise use --global python@latest
  pip install pipx
  pipx ensurepath
  export PATH="$HOME/.local/bin:$PATH"
  pipx install getjump poetry yt-dlp
  poetry self add poetry-version-plugin
}

# ruby
[[ -d ~/.rbenv ]] || {
  mise use --global ruby@latest
}

# node
command -v node 2>/dev/null || {
  mise use --global node@latest
}

# rust
curl 'https://sh.rustup.rs' | sh -s -- -y
source ~/.cargo/env

# starship
[[ -f ~/.config/starship.toml ]] || {
  curl -sS 'https://starship.rs/install.sh' | sh -s -- -y
  echo 'eval "$(starship init bash)"' >> ~/.bashrc
  echo 'eval "$(starship init zsh)"' >> ~/.zshrc
  cat <<'A'>>~/.config/starship.toml
"$schema" = 'https://starship.rs/config-schema.json'

add_newline = false

format = '''\[\[\[${username}@${hostname}:\(${time}\):${directory}:${memory_usage}\]\]\] $package
->>> '''

right_format = '$git_status$git_branch$git_commit$git_state'

[character]
success_symbol = "[>](bold green)"
error_symbol = "[✗](bold red)"

[username]
disabled = false
style_user = "red bold"
style_root = "red bold"
format = '[$user]($style)'
show_always = true

[hostname]
disabled = false
ssh_only = false
style = "bold blue"
format = '[$hostname]($style)'

[time]
disabled = false
format = '[$time]($style)'

[directory]
# truncation_length = 10
truncation_symbol = '…/'
format = '[$path]($style)[$read_only]($read_only_style)'
# truncate_to_repo = false

[memory_usage]
disabled = false
threshold = -1
style = "bold dimmed green"
format = "[$ram_pct]($style)"

[package]
disabled = false
format = '[$symbol$version]($style)'
A
}

# go
command -v go 2>/dev/null || {
  mise use --global go@latest
}

# clisp
command -v ros 2>/dev/null || {
  curl -s 'https://api.github.com/repos/roswell/roswell/releases/latest' |
    grep -oEm1 'https://.*_amd64.deb' | xargs wget
  sudo apt install ./roswell_*_amd64.deb
  ros install sbcl-bin
}

# git
[[ -f ~/.gitconfig ]] || {
  echo -n "github token?> "
  # Copy generated fine-grained PAT and paste.
  # Required permission: Gist, Contents
  # https://github.com/settings/tokens
  read -s -r token
  cat <<A >>~/.netrc
machine github.com
login eggplants
password ${token}
machine gist.github.com
login eggplants
password ${token}
A
  netrc_helper_path="$(
    readlink /usr/local/bin/git -f | sed 's;/bin/git;;'
  )/share/git-core/contrib/credential/netrc/git-credential-netrc.perl"
  git_email="$(
    gpg --list-keys | grep -Em1 '^uid' |
      rev | cut -f1 -d ' ' | tr -d '<>' | rev
  )"
  # gpg -e -r "$git_email" ~/.netrc
  # rm ~/.netrc
  sudo chmod +x "$netrc_helper_path"
  git config --global commit.gpgsign true
  git config --global core.editor nano
  git config --global credential.helper "$netrc_helper_path"
  git config --global gpg.program "$(which gpg)"
  git config --global help.autocorrect 1
  git config --global pull.rebase false
  git config --global push.autoSetupRemote true
  git config --global rebase.autosquash true
  git config --global user.email "$git_email"
  git config --global user.name eggplants
  git config --global user.signingkey "$(
    gpg --list-secret-keys | tac | grep -m1 -B1 '^sec' | head -1 | awk '$0=$1'
  )"
}

# zinit
curl -s https://raw.githubusercontent.com/zdharma-continuum/zinit/HEAD/scripts/install.sh | bash
cat <<'A' >>~/.zshrc
zinit light zdharma-continuum/fast-syntax-highlighting
zinit light zdharma-continuum/history-search-multi-word
zinit light zsh-users/zsh-autosuggestions
zinit light zsh-users/zsh-completions

# if (which zprof > /dev/null) ;then
#   zprof | less
# fi
A

# zsh
[[ "$SHELL" = "$(which zsh)" ]] || chsh -s "$(which zsh)"
cat <<'A' >.zshrc.tmp
#!/usr/bin/env zsh

# load zprofile
[[ -f ~/.zprofile ]] && source ~/.zprofile

# completion
autoload -U compinit
if [ "$(find ~/.zcompdump -mtime 1)" ] ; then
    compinit -u
fi
compinit -uC
zstyle ':completion:*' menu select

# enable opts
setopt correct
setopt autocd
setopt nolistbeep
setopt aliasfuncdef
setopt appendhistory
setopt histignoredups
setopt sharehistory
setopt extendedglob
setopt incappendhistory
setopt interactivecomments
setopt prompt_subst

unsetopt nomatch

# alias
alias ll='ls -lGF --color=auto'
alias ls='ls -GF --color=auto'

# save cmd history up to 100k
HISTFILE="$HOME/.zsh_history"
HISTSIZE=100000
SAVEHIST=100000
HISTFILESIZE=2000
bindkey '^[[A' up-line-or-search
bindkey '^[[B' down-line-or-search

# enable less to show bin
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# enable colorized prompt
case "$TERM" in
  xterm-color | *-256color) color_prompt=yes ;;
esac

# enable colorized ls
export LSCOLORS=gxfxcxdxbxegedabagacag
export LS_COLORS='di=36;40:ln=35;40:so=32;40:pi=33;40:ex=31;40:bd=34;46:cd=34;43:su=30;41:sg=30;46:tw=30;42:ow=30;46'
zstyle ':completion:*:default' list-colors "${(s.:.)LS_COLORS}"

export PATH="$PATH:$HOME/.local/bin"

export GPG_TTY="$(tty)"

A

cat ~/.zshrc >>.zshrc.tmp
mv .zshrc.tmp ~/.zshrc

cat <<'A' >.zshenv.tmp
#!/usr/bin/env zsh

# zmodload zsh/zprof && zprof
A
cat ~/.zshenv >>.zshenv.tmp
mv .zshenv.tmp ~/.zshenv

rm ~/.sec.key
popd
rm -rf _setup

termux-setup-storage

reboot
