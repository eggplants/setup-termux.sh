# My Termux setup

## Run

After [Termux](https://termux.dev) installed:

```bash
# select `Single mirror` > `default` to make `pkg` faster
termux-change-repo

# enable to access local storage
termux-setup-storage

# locate my.gpg key
mv ~/storage/downloads/sec ~/.sec.key

# setup
bash <(curl -fsSL 'https://raw.githubusercontent.com/eggplants/setup-termux.sh/refs/heads/master/bootstrap.sh')
```

## Update

```bash
mise bootstrap --dry-run
mise bootstrap
mise bootstrap --update
mise bootstrap status
```

## Family

- [eggplants/setup-macos.sh](https://github.com/eggplants/setup-macos.sh)
- [eggplants/setup-termux.sh](https://github.com/eggplants/setup-termux.sh) <- here
- [eggplants/setup-ubuntu.sh](https://github.com/eggplants/setup-ubuntu.sh)
- [eggplants/SetupWindows.ps1](https://github.com/eggplants/SetupWindows.ps1)
