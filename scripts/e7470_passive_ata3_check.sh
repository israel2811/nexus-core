#!/usr/bin/env bash
set -euo pipefail

# Preservation-only diagnostics for Dell Latitude E7470 / SystemRescue.
# NEVER resets ATA, rescans buses, writes media, mounts filesystems, TRIMs,
# repairs filesystems, changes SControl/PCS, or powers the SSD.

echo '=== E7470 ATA3 PASSIVE CHECK ==='
date -Is
hostname

echo
echo '--- block devices (report only) ---'
lsblk -o NAME,PATH,TYPE,SIZE,RO,RM,TRAN,MODEL,SERIAL,FSTYPE,MOUNTPOINTS

echo
echo '--- ata3/link3 sysfs ---'
readlink -f /sys/class/ata_port/ata3 2>/dev/null || true
for f in /sys/class/ata_link/link3/sata_spd /sys/class/ata_link/link3/sata_spd_limit; do
  [ -r "$f" ] && printf '%s = %s\n' "$f" "$(cat "$f")"
done

echo
echo '--- recent kernel evidence ---'
dmesg --color=never | grep -E 'ata3|link3|ahci' | tail -n 80 || true

echo
echo '--- AHCI port 2 registers (READ ONLY) ---'
python3 - <<'PY'
import os, struct
p='/sys/bus/pci/devices/0000:00:17.0/resource0'
# AHCI ports start at 0x100, stride 0x80; ata3 is AHCI port index 2.
base=0x100 + 2*0x80
regs={'TFD':0x20,'SIG':0x24,'SSTS':0x28,'SERR':0x30,'SACT':0x34,'CI':0x38}
try:
    fd=os.open(p, os.O_RDONLY)
except OSError as e:
    print('resource0 unavailable:', e)
    raise SystemExit(0)
try:
    for name,off in regs.items():
        raw=os.pread(fd,4,base+off)
        if len(raw)==4:
            print(f'{name}=0x{struct.unpack("<I",raw)[0]:08x}')
finally:
    os.close(fd)
PY

echo
echo 'NO RESET / NO RESCAN / NO WRITE performed.'