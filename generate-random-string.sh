#!/bin/bash

: <<'COMMENT'
##
## Example:
## generate 10 strings, each 30 characters in length
##
$ ./generate-random-string.sh 10 30
#####     without special characters     #####
aY61nRsdxwg52TVHYz2LFhD6tKW[ia
yHexwnw4NtlejjSL9]A12G3GIjYgLE
antQ[Tj0m20]TmCaLaAj1qK6aP0qkL
MjpOENiU3TsJJI79w6]LJenjWP5gU1
3[qZByWcLwSG2TcJiHN38TKjQ[Mw0E
rOFXjvtDcHFcCsA[OkVYjPeuCMsiC8
rXbymXRE3eJmciJ4bGm6X4GYU6o[7i
muSi2qtg[jaGYgCpc2]GF5RMpwtSvg
3DPZI4VZhTUCOo1V3Ea9apijVv4cjL
qF0HP[WuBm1jkoYcIqR2DldOnCHiXG

#####     with special characters     #####
,VtA.0jc!rl94},vY,8L.QTOxTU6{-
HOmQ*@&uom/l5W(qMozMn#K>$E}c7k
uanx}zSo^2j5AL=EXk'2$f`TBW9&Tx
y"w'#Pk`xAEaYA-7(dPR]Fo_[k<cx?
@PyB:.V/x5/9~F?_J?qv&G?~:w~8Zs
w=k8c!'ha~>>j@q$i'DXGj.jY=raOa
&h)z[OOBK}8Z8N9hl-E'UuhFoh6f(&
eP,ARPIC(g2XAWdw2Lbwl7X;q%M8@K
O2lQc)GDMgH#L4Jh?1[*rRs4aZ&!BE
}F/Yzsh%2/ou^|PM(iZ'41X%{X-iEE
$

COMMENT



string_count=$1
string_length=$2

printf "%-10s" "#####"
printf "without special characters"
printf "%10s" "#####"
printf "\n"
for i in $(seq 1 ${string_count})
do
   tr -dc "[[:alnum:]]" </dev/urandom | head -c ${string_length} ; echo ''
done

printf "\n"
printf "%-10s" "#####"
printf "with special characters"
printf "%10s" "#####"
printf "\n"
for i in $(seq 1 ${string_count})
do
   tr -dc "[[:alnum:]][[:punct:]]" </dev/urandom | head -c ${string_length} ; echo ''
done

###
