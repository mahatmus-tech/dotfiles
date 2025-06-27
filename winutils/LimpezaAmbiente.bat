P:
DEL /S *.dcp
DEL /S *.dcu
DEL /S *.bpl
DEL = /S *.~*,  
dcc32 -b cotab.dpk

M: 
DEL /S sa_*.bpl
DEL /S sa_*.~bpl
DEL /S sa_*.map
DEL /S sapiens*.exe
DEL /S sapiens*.map