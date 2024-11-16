# My Termux setup for mobile git / ssh client

After [Termux](https://termux.dev) installed:

```bash
# select `Single mirror` > `default` to make `pkg` faster
termux-change-mirror

# enable to access local storage
termux-setup-storage

# locate my.gpg key
mv ~/storage/downloads/sec ~/.sec.key

# setup
curl -sL 'https://raw.githubusercontent.com/eggplants/setup-termux.sh/refs/heads/master/setup-termux.sh' | bash
```

![1000000073](https://github.com/user-attachments/assets/f7552932-629c-49f8-a989-7ac5ed82f5c5)

## Family

- [eggplants/setup-macos.zsh](https://github.com/eggplants/setup-macos.zsh)
- [eggplants/setup-termux.sh](https://github.com/eggplants/setup-termux.sh) <- here
- [eggplants/setup-ubuntu.sh](https://github.com/eggplants/setup-ubuntu.sh)
- [eggplants/SetupWindows.ps1](https://github.com/eggplants/SetupWindows.ps1)
