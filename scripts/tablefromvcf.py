#This is a script to read a LoFreq VCF file and extract a CSV table with Sample,Chromosome,Position,Ref,Alt,Ref_Reads,Alt_Reads,Proportion,Basic_Pass

import sys
import os

varcallsdir = sys.argv[1]
infiles = os.listdir(varcallsdir)
fileout = open(sys.argv[2], "w")

basicpassreads = 100
basicpassproportion = 0.05

#VCF files have lines like:
###CHROM  POS     ID      REF     ALT     QUAL    FILTER  INFO
#7       55259288        .       TC      T       152     PASS    DP=32327;AF=0.000588;SB=0;DP4=32308,0,19,0;INDEL;HRUN=1
#7       55259290        .       GC      G       239     PASS    DP=32327;AF=0.000804;SB=0;DP4=32300,0,26,0;INDEL;HRUN=2
#7       55259293        .       A       AG      58      PASS    DP=32327;AF=0.000309;SB=0;DP4=32315,0,10,0;INDEL;HRUN=1
#7       55259294        .       GC      G       463     PASS    DP=32327;AF=0.001299;SB=0;DP4=32284,0,42,0;INDEL;HRUN=2
#7       55259294        .       G       T       12517   PASS    DP=32327;AF=0.045040;SB=0;DP4=30838,0,1456,0

#IVAR TSV files have lines like:
#REGION  POS     REF     ALT     REF_DP  REF_RV  REF_QUAL        ALT_DP  ALT_RV  ALT_QUAL        ALT_FREQ        TOTAL_DP        PVAL    PASS    GFF_FEATURE     REF_CODON       REF_AA  ALT_CODON       ALT_AA
#NC_045512.2     241     C       T       1       1       36      2976    1170    50      0.999664        2977    0       TRUE    NA      NA      NA      NA      NA
#NC_045512.2     285     G       T       2717    1985    43      323     236     43      0.106076        3045    1.08305e-119    TRUE    cds-YP_009724389.1      GGT     G       GTT     V
#NC_045512.2     285     G       T       2717    1985    43      323     236     43      0.106076        3045    1.08305e-119    TRUE    cds-YP_009725295.1      GGT     G       GTT     V

fileout.write("Sample,Caller,Region,Position,Ref,Alt,Ref_Reads,Alt_Reads,Proportion,Basic_Pass\n")

for infile in infiles:
    if "_lofreq.vcf" in infile:
        filein = open(varcallsdir+"/"+infile)
        caller = "lofreq"
        samplename = infile.replace("_lofreq.vcf","")
        for line in filein:
            if line[0] == "#":
                continue
            collect = line.rstrip().split("\t")
            chromosome = collect[0]
            position = collect[1]
            ref = collect[3]
            alt = collect[4]
            infofield = collect[7].split(";")
            proportion = infofield[1].split("=")[1]
            refreads = int(infofield[3].split("=")[1].split(",")[0]) + int(infofield[3].split("=")[1].split(",")[1])
            altreads = int(infofield[3].split("=")[1].split(",")[2]) + int(infofield[3].split("=")[1].split(",")[3])
            basicpass = altreads >= basicpassreads and float(proportion) >= basicpassproportion
            fileout.write(",".join([samplename,caller,chromosome,position,ref,alt,str(refreads),str(altreads),proportion,str(basicpass),"\n"]))
        filein.close()
    if "_variants.tsv" in infile:
        filein = open(varcallsdir+"/"+infile)
        samplename = infile.replace("_variants.tsv","")
        caller = "ivar"
        header = filein.readline()
        for line in filein:
            collect = line.rstrip().split("\t")
            chromosome = collect[0]
            position = collect[1]
            ref = collect[2]
            alt = collect[3]
            refreads = int(collect[4])
            altreads = int(collect[7])
            proportion = float(altreads) / (float(altreads)+float(refreads))
            basicpass = bool(collect[13]) and (altreads >= basicpassreads and float(proportion) >= basicpassproportion)
            fileout.write((",".join([samplename,caller,chromosome,position,ref,alt,str(refreads),str(altreads),str(proportion),str(basicpass)])+"\n"))
        filein.close()

fileout.close()
