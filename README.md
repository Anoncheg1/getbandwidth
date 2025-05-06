#
Bash script to get average bandwidth of interface for recent 10 seconds. No dependencies.
# Usage

```bash
source  get_bandwith.sh wlan0 15
```

# Require
- python3
- awk
- Available /proc/net/dev file. That enabled in Linux Kernel: CONFIG_PROC_FS, CONFIG_NET, CONFIG_NETDEVICES

Those enabled at all major distrubutives by default.