#!/usr/bin/env python3
from pathlib import Path

REG = {f'x{i}': i for i in range(32)}

def r_type(f7, rs2, rs1, f3, rd, opc=0x33):
    return ((f7 & 0x7f)<<25)|((rs2&31)<<20)|((rs1&31)<<15)|((f3&7)<<12)|((rd&31)<<7)|(opc&0x7f)

def i_type(imm, rs1, f3, rd, opc):
    return ((imm & 0xfff)<<20)|((rs1&31)<<15)|((f3&7)<<12)|((rd&31)<<7)|(opc&0x7f)

def s_type(imm, rs2, rs1, f3, opc=0x23):
    imm &= 0xfff
    return (((imm>>5)&0x7f)<<25)|((rs2&31)<<20)|((rs1&31)<<15)|((f3&7)<<12)|((imm&0x1f)<<7)|(opc&0x7f)

def b_type(off, rs2, rs1, f3, opc=0x63):
    assert off % 2 == 0
    imm = off & 0x1fff
    return (((imm>>12)&1)<<31)|(((imm>>5)&0x3f)<<25)|((rs2&31)<<20)|((rs1&31)<<15)|((f3&7)<<12)|(((imm>>1)&0xf)<<8)|(((imm>>11)&1)<<7)|(opc&0x7f)

def u_type(imm20, rd, opc):
    return ((imm20 & 0xfffff)<<12)|((rd&31)<<7)|(opc&0x7f)

def j_type(off, rd, opc=0x6f):
    assert off % 2 == 0
    imm = off & 0x1fffff
    return (((imm>>20)&1)<<31)|(((imm>>1)&0x3ff)<<21)|(((imm>>11)&1)<<20)|(((imm>>12)&0xff)<<12)|((rd&31)<<7)|(opc&0x7f)

prog=[]
labels={}
fixups=[]

def emit(word, text=''):
    prog.append([word,text])

def label(name): labels[name]=len(prog)*4

def branch(f3, rs1, rs2, target, text):
    fixups.append((len(prog), 'B', f3, rs1, rs2, target, text)); emit(0,text)

def jal(rd, target, text):
    fixups.append((len(prog), 'J', rd, target, text)); emit(0,text)

# Base integer ALU
emit(i_type(10,0,0,1,0x13),'addi x1,x0,10')
emit(i_type(3,0,0,2,0x13),'addi x2,x0,3')
emit(r_type(0,2,1,0,3),'add x3,x1,x2')
emit(r_type(0x20,2,1,0,4),'sub x4,x1,x2')
emit(r_type(0,2,2,1,5),'sll x5,x2,x2')
emit(r_type(0,1,2,2,6),'slt x6,x2,x1')
emit(r_type(0,1,2,3,7),'sltu x7,x2,x1')
emit(r_type(0,2,1,4,8),'xor x8,x1,x2')
emit(r_type(0,2,1,5,9),'srl x9,x1,x2')
emit(r_type(0,2,1,6,10),'or x10,x1,x2')
emit(r_type(0,2,1,7,11),'and x11,x1,x2')
emit(i_type(-1,0,0,12,0x13),'addi x12,x0,-1')
emit(i_type((0x20<<5)|1,12,5,13,0x13),'srai x13,x12,1')

# RV32M multiplication and division
emit(r_type(1,2,1,0,14),'mul x14,x1,x2')
emit(r_type(1,2,12,1,15),'mulh x15,x12,x2')
emit(r_type(1,2,12,2,16),'mulhsu x16,x12,x2')
emit(r_type(1,2,12,3,17),'mulhu x17,x12,x2')
emit(r_type(1,2,1,4,18),'div x18,x1,x2')
emit(r_type(1,2,1,5,19),'divu x19,x1,x2')
emit(r_type(1,2,1,6,20),'rem x20,x1,x2')
emit(r_type(1,2,1,7,21),'remu x21,x1,x2')

# Byte/half/word memory accesses
emit(i_type(256,0,0,22,0x13),'addi x22,x0,256')
emit(s_type(0,3,22,2),'sw x3,0(x22)')
emit(i_type(0,22,2,23,0x03),'lw x23,0(x22)')
emit(s_type(4,1,22,0),'sb x1,4(x22)')
emit(i_type(4,22,0,24,0x03),'lb x24,4(x22)')
emit(i_type(4,22,4,25,0x03),'lbu x25,4(x22)')
emit(i_type(-2,0,0,26,0x13),'addi x26,x0,-2')
emit(s_type(6,26,22,1),'sh x26,6(x22)')
emit(i_type(6,22,1,27,0x03),'lh x27,6(x22)')
emit(i_type(6,22,5,28,0x03),'lhu x28,6(x22)')

# All six branch conditions. Each taken branch skips a poison write.
emit(i_type(0,0,0,29,0x13),'addi x29,x0,0')
for name,f3,rs1,rs2 in [
    ('blt_ok',4,12,2), ('bge_ok',5,2,12), ('bltu_ok',6,2,12), ('bgeu_ok',7,12,2)]:
    branch(f3,rs1,rs2,name,'branch taken')
    emit(i_type(99,0,0,29,0x13),'poison x29=99')
    label(name)
    emit(i_type(1,29,0,29,0x13),'addi x29,x29,1')

emit(i_type(0,0,0,30,0x13),'addi x30,x0,0')
branch(0,1,1,'beq_ok','beq x1,x1')
emit(i_type(99,0,0,30,0x13),'poison x30=99')
label('beq_ok'); emit(i_type(1,30,0,30,0x13),'addi x30,x30,1')
branch(1,1,2,'bne_ok','bne x1,x2')
emit(i_type(99,0,0,30,0x13),'poison x30=99')
label('bne_ok'); emit(i_type(1,30,0,30,0x13),'addi x30,x30,1')

# JAL and JALR flow
jal(31,'jal_target','jal x31,jal_target')
emit(i_type(99,0,0,5,0x13),'poison x5=99')
label('jal_target'); emit(i_type(5,0,0,5,0x13),'addi x5,x0,5')
# x6 gets address of the AUIPC itself, then add offset to jalr_target.
auipc_index=len(prog); emit(u_type(0,6,0x17),'auipc x6,0')
# patch addi after label positions are known later
addi_target_index=len(prog); emit(0,'addi x6,x6,jalr_target-auipc_pc')
emit(i_type(0,6,0,7,0x67),'jalr x7,0(x6)')
emit(i_type(99,0,0,8,0x13),'poison x8=99')
label('jalr_target'); emit(i_type(8,0,0,8,0x13),'addi x8,x0,8')

# EBREAK halts the stand-alone test environment.
emit(0x00100073,'ebreak')

# Resolve branches/jumps.
for item in fixups:
    idx=item[0]; pc=idx*4
    if item[1]=='B':
        _,_,f3,rs1,rs2,target,text=item
        prog[idx][0]=b_type(labels[target]-pc, rs2, rs1, f3)
    else:
        _,_,rd,target,text=item
        prog[idx][0]=j_type(labels[target]-pc, rd)

auipc_pc=auipc_index*4
imm=labels['jalr_target']-auipc_pc
prog[addi_target_index][0]=i_type(imm,6,0,6,0x13)

root=Path(__file__).resolve().parents[1]
encoded=[f'{w:08x}' for w,_ in prog]
encoded += ['00000013'] * (2048-len(encoded))
out=root/'sim'/'program.mem'
out.write_text('\n'.join(encoded)+'\n')
(root/'program.mem').write_text('\n'.join(encoded)+'\n')
listing=root/'sim'/'program.lst'
listing.write_text('\n'.join(f'{i*4:04x}: {w:08x}  {t}' for i,(w,t) in enumerate(prog))+'\n')
print(f'wrote {len(prog)} test instructions + NOP padding ({len(encoded)} words)')
