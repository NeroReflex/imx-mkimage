#!/bin/sh

cnt=0
fcb_sz=0
crc_sz=0

fspi_calc_crc() {
    local crc_tmp=0
    while read -r line; do
        data=$(echo "$line" | cut -c 1-8)
        crc_tmp=$((0x$data ^ $crc_tmp))
    done < $1
    echo "`printf "%x" $crc_tmp`"
}

for fcbfile in $*
do
    awk '{s="00000000"$1;l=length(s);if(!((NR-1)%4))printf "%08x ",(NR-1)*4;for(i=7;i>0;i-=2)printf " %s",substr(s,l-i,2);if(!(NR%4))printf "\n";}' $fcbfile > qspi-tmp
    xxd -r qspi-tmp qspi-header
    fcb_sz=$(expr $(wc -l $fcbfile | awk '{print $1}') \* 4)
    crc_sz=$(expr $fcb_sz - 4)
    dd if=qspi-header of=qspi-header-crc bs=1 count=$crc_sz
    crc_value=$(fspi_calc_crc $fcbfile)
    echo $crc_value | xxd -r -ps >> qspi-header-crc
    dd if=qspi-header-crc of=fcb.bin bs=$fcb_sz seek=$cnt
    cnt=$((cnt+1))
    rm -f qspi-tmp qspi-header qspi-header-crc
done

while [ $cnt -lt 4 ]
do
    dd if=/dev/zero of=fcb.bin bs=$fcb_sz seek=$cnt count=1
    cnt=$((cnt+1))
done
echo "fcb.bin is generated"
