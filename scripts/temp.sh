variants=$1
genome=$2
name=${variants%.tsv}
perl -nae 'if($_=~/REGION/){print "#CHR\tSTART\tEND\tGFF\n"; next;} $indel="no"; if($F[3]=~/\+|-/){$indel="yes";} $ref=$F[3]; $ref=~s/\+|-//; $size=length($ref); $add=0; if($size >1){$add = $size - 1;} $start=$F[1]-1; $end=$F[1]+$add; print "$F[0]\t$start\t$end\t$F[14]\n";' ${variants} >${name}.bed
snpEff -i bed -ud 1 ${genome} ${name}.bed >${name}.anno
