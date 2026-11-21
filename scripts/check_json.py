#!/usr/bin/env python3
"""Gate JSON (P0-6): every CLI JSON output must be parseable and safe.

Builds a FIT whose string field contains a 0x08 control byte and a TCX whose
Sport is 'a&quot;b' and DistanceMeters is NaN, then asserts `moonfit dump` /
`moonfit tcx` emit valid JSON (control char escaped, quote escaped, NaN->null).
On the pre-P0-6 code these outputs were invalid JSON.
"""
import json, struct, subprocess, sys, os
from pathlib import Path
ROOT = Path(__file__).resolve().parent.parent
BUILD = ROOT/"_build"/"native"/"release"/"build"/"cmd"/"moonfit"
T=[0x0000,0xCC01,0xD801,0x1400,0xF001,0x3C00,0x2800,0xE401,0xA001,0x6C00,0x7800,0xB401,0x5000,0x9C01,0x8801,0x4400]
def crc(b):
    c=0
    for x in b:
        t=T[c&0xF]; c=((c>>4)&0x0FFF)^t^T[x&0xF]
        t=T[c&0xF]; c=((c>>4)&0x0FFF)^t^T[(x>>4)&0xF]
    return c&0xFFFF
def u32(v): return struct.pack('<I',v)
def u16(v): return struct.pack('<H',v)
def fit_with_control_string():
    body=bytearray()
    body+=bytes([0x40,0,0,0,0,1,8,8,0x07])          # def local0 global0 string field def8 size8
    body+=bytes([0x00])+b'AB\x08CD\x00\x00\x00'      # data with 0x08
    hdr=bytearray([14,0x10,0xEA,0x07])+u32(len(body))+b'.FIT'
    hdr+=u16(crc(hdr))
    full=hdr+body; full+=u16(crc(full))
    return bytes(full)
TCX='<?xml version="1.0"?><TrainingCenterDatabase xmlns="http://www.garmin.com/xmlschemas/TrainingCenterDatabase/v2"><Activities><Activity Sport="a&quot;b"><Lap StartTime="2026-01-01T00:00:00Z"><TotalTimeSeconds>1</TotalTimeSeconds><DistanceMeters>NaN</DistanceMeters><Track><Trackpoint><Time>2026-01-01T00:00:00Z</Time><Position><LatitudeDegrees>1.0</LatitudeDegrees><LongitudeDegrees>2.0</LongitudeDegrees></Position></Trackpoint></Track></Lap></Activity></Activities></TrainingCenterDatabase>'
def locate():
    for n in ("moonfit.exe","moonfit"):
        p=BUILD/n
        if p.exists(): return p
    f=sorted(BUILD.glob("moonfit*")); return f[0] if f else None
def main():
    exe=locate()
    if exe is None: print("::error::CLI not built"); return 1
    if os.name!="nt" and not os.access(exe,os.X_OK): exe.chmod(exe.stat().st_mode|0o111)
    import tempfile
    fails=[]
    with tempfile.TemporaryDirectory() as td:
        f=Path(td)/"c.fit"; f.write_bytes(fit_with_control_string())
        p=subprocess.run([str(exe),"dump",str(f)],capture_output=True,text=True)
        try:
            d=json.loads(p.stdout.splitlines()[0])
            txt=d["f"][0]["v"]
            if "\x08" not in txt: fails.append("control char not round-tripped")
        except Exception as e:
            fails.append(f"dump invalid JSON: {e}")
        t=Path(td)/"c.tcx"; t.write_text(TCX)
        p=subprocess.run([str(exe),"tcx",str(t)],capture_output=True,text=True)
        try:
            d=json.loads(p.stdout)
            if d["sport_raw"]!='a"b': fails.append(f"sport_raw {d['sport_raw']!r}")
            if d["device_distance_m"] is not None: fails.append("NaN not null")
        except Exception as e:
            fails.append(f"tcx invalid JSON: {e}")
    if fails:
        print("JSON gate FAILED:"); [print("  -",x) for x in fails]; return 1
    print("JSON gate OK: dump/tcx outputs are valid JSON (control/quote escaped, NaN->null).")
    return 0
if __name__=="__main__":
    sys.exit(main())
