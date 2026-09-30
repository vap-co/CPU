#!/usr/bin/env python3
"""Convert a little-endian raw binary into 32-bit words for $readmemh."""
import argparse
from pathlib import Path

ap=argparse.ArgumentParser()
ap.add_argument('binary')
ap.add_argument('output')
ap.add_argument('--words',type=int,default=2048,help='memory depth in 32-bit words (output is zero-padded to this depth)')
a=ap.parse_args()
data=bytearray(Path(a.binary).read_bytes())
if len(data)>a.words*4:
    raise SystemExit(f'{len(data)} bytes exceed {a.words*4}-byte memory')
data.extend(b'\x00' * ((4-len(data)%4)%4))
data.extend(b'\x00' * (a.words*4-len(data)))
words=[]
for i in range(0,len(data),4):
    w=int.from_bytes(data[i:i+4],'little')
    words.append(f'{w:08x}')
Path(a.output).write_text('\n'.join(words)+'\n')
print(f'wrote {len(words)} words to {a.output}')
