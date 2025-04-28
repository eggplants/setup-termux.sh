#!/usr/bin/env bash

set -eux

[[ -d ~/storage ]] || termux-setup-storage

touch .hushlogin

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
  android-tools \
  ca-certificates curl \
  ffmpeg \
  git gnupg golang gh \
  imagemagick \
  jq \
  pinentry pkg-config \
  rust \
  sheldon \
  termux-api \
  unar \
  which wget w3m \
  zsh

# termscp
# cargo install \
#   --locked --no-default-features \
#   --features with-keyring termscp

# import key
if ! gpg --list-keys | grep -qE '^ *EE3A'; then
  export GPG_TTY="$(tty)"
  export SSH_AUTH_SOCK="$(gpgconf --list-dirs agent-ssh-socket)"
  echo "pinentry-program $(which pinentry-tty)" > ~/.gnupg/gpg-agent.conf
  echo enable-ssh-support >> ~/.gnupg/gpg-agent.conf
  touch ~/.gnupg/sshcontrol
  chmod 600 ~/.gnupg/*
  chmod 700 ~/.gnupg
  gpgconf --kill gpg-agent
  sleep 3s
  gpg --allow-secret-key --import ~/.sec.key
  gpg --list-key --with-keygrip | grep -FA1 '[SA]' | awk -F 'Keygrip = ' '$0=$2' > ~/.gnupg/sshcontrol
  gpg-connect-agent updatestartuptty /bye
fi

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

# git
[[ -f ~/.gitconfig ]] || {
  gh auth login -p https -h gitHub.com -w <<<y
  git config --global commit.gpgsign true
  git config --global core.editor nano
  git config --global gpg.program "$(which gpg)"
  git config --global help.autocorrect 1
  git config --global pull.rebase false
  git config --global push.autoSetupRemote true
  git config --global rebase.autosquash true
  git config --global user.email "w10776e8w@yahoo.co.jp"
  git config --global user.name eggplants
  git config --global user.signingkey "$(
    gpg --list-secret-keys | tac | grep -m1 -B1 '^sec' | head -1 | awk '$0=$1'
  )"
  cb_prefix="url.git@codeberg.org:"
  git config --global --remove-section "$cb_prefix" || :
  git config --global "$cb_prefix".pushInsteadOf "git://codeberg.org/"
  git config --global --add "$cb_prefix".pushInsteadOf "https://codeberg.org/"
}

# sheldon
sheldon init --shell zsh <<<y
sheldon add --github zdharma/fast-syntax-highlighting fast-syntax-highlighting
sheldon add --github zdharma-continuum/history-search-multi-word history-search-multi-word
sheldon add --github zsh-users/zsh-autosuggestions zsh-autosuggestions
sheldon add --github zsh-users/zsh-completions zsh-completions
sheldon add --use async.zsh pure.zsh --github sindresorhus/pure pure 

cat <<'A' >>~/.zshrc
eval "$(sheldon source)"

# if (which zprof > /dev/null) ;then
#   zprof | less
# fi
A

# zsh
[[ "$SHELL" =~ 'zsh$' ]] || chsh -s zsh
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
export PATH="$PATH:$HOME/go/bin"
export PATH="$PATH:$HOME/.cargo/bin"

unset SSH_AGENT_PID
if [ "${gnupg_SSH_AUTH_SOCK_by:-0}" -ne $$ ]; then
  export SSH_AUTH_SOCK="$(gpgconf --list-dirs agent-ssh-socket)"
fi
export GPG_TTY=$(tty)
gpg-connect-agent updatestartuptty /bye >/dev/null

A

[[ -f ~/.zshrc ]] && cat ~/.zshrc >>.zshrc.tmp
mv .zshrc.tmp ~/.zshrc

cat <<'A' >.zshenv.tmp
#!/usr/bin/env zsh

# zmodload zsh/zprof && zprof
A
[[ -f ~/.zshenv ]] && cat ~/.zshenv >>.zshenv.tmp
mv .zshenv.tmp ~/.zshenv

rm ~/.sec.key
popd
rm -rf _setup

echo 'Done. Please run `exit` and relaunch app.'
