# My Termux setup for mobile git / ssh client

After [Termux](https://termux.dev) installed:

```bash
termux-setup-storage
mv ~/storage/downloads/sec ~/.sec.key
curl -OL 'https://raw.githubusercontent.com/eggplants/termux-setup.sh/refs/heads/master/termux-setup.sh'
chmod +x termux-setup.sh
./termux-setup.sh
# > Done. Please run `exit` and relaunch app.
rm ./termux-setup.sh
exit
```

![1000000073](https://github.com/user-attachments/assets/f7552932-629c-49f8-a989-7ac5ed82f5c5)
