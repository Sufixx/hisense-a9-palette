#!/usr/bin/env python3
"""Dump the colour entries of fabricated overlay (.frro) files: frro_dump.py FILE...

Pull them first (root): cp /data/resource-cache/*.frro /data/local/tmp/ && adb pull ...
Prints "<overlay> <type>/<name> #aarrggbb". The protobuf starts at offset 0x30 on Android 14.
"""
import sys
def varint(b,i):
    r=s=0
    while True:
        c=b[i];i+=1;r|=(c&0x7f)<<s;s+=7
        if c<0x80:return r,i
def fields(b):
    i=0;out=[]
    while i<len(b):
        k,i=varint(b,i);f,t=k>>3,k&7
        if t==0: v,i=varint(b,i)
        elif t==2: l,i=varint(b,i);v=b[i:i+l];i+=l
        elif t==5: v=b[i:i+4];i+=4
        elif t==1: v=b[i:i+8];i+=8
        out.append((f,v))
    return out
for fn in sys.argv[1:]:
    b=open(fn,'rb').read(); b=b[0x30:]
    for f,pkg in fields(b):
        if f!=1: continue
        for f2,typ in fields(pkg):
            if f2!=2: continue
            tf=dict(fields(typ)); tname=tf[1].decode()
            for f3,e in fields(typ):
                if f3!=2: continue
                ef=fields(e); name=[v for k,v in ef if k==1][0].decode()
                val=dict(fields([v for k,v in ef if k==2][0]))
                print(fn.split('-')[1], f"{tname}/{name}", '#%08x'%val.get(2,0))
