#
Bash script to get average bandwidth of interface for recent 10 seconds. No dependencies.
# Usage

```bash
source  get_bandwith.sh wlan0 15
```

# Require
- python3
- awk
- Enabled in Linux Kernel: CONFIG_PROC_FS, CONFIG_NET, CONFIG_NETDEVICES
This enabled everywhere by default.