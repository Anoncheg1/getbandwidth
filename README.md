#
Bash script to get average bandwidth of interface for recent 10 seconds. No dependencies.

Output:

`1225MB 15.70 KB/s RX:########_______ TX:##_____________`

# Usage

```bash
# $ source get_bandwith.sh [interface] [interval] [max_bandwith]
# Example:
source  get_bandwith.sh wlan0 15 400
```

# Require
- python3
- awk
- Available /proc/net/dev file. That enabled in Linux Kernel: CONFIG_PROC_FS, CONFIG_NET, CONFIG_NETDEVICES

Those enabled at all major distrubutives by default.