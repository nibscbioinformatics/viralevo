#This is a script to take VCF files from either lofreq or ivar and filter by depth and allele fraction
#run with a command like:
#python $baseDir/scripts/filterandtable.py ${sampleID}_${caller}_raw_anno.vcf $caller ${sampleID}_${caller}_anno.vcf

import sys
import os

filein = open(sys.argv[1])
caller = sys.argv[2]
fileout = open(sys.argv[3], "w")

depththreshold = 100
proportionthreshold = 0.05

#ivar vcf has lines like:
#NC_045512.2     45      .       G       A       .       FALSE   IVAR_DP=245;IVAR_GFF=NA;IVAR_REFAA=NA;IVAR_ALTAA=NA;ANN=A|intergenic_region|MODIFIER|CHR_START-ORF1ab|CHR_START-GU280_gp01|intergenic_region|CHR_START-GU280_gp01|||n.45G>A||||||       GT:PVAL:AQ:DP:AF        G/A:0.482283:37,32:244,1:0.00408163
#lofreq has lines like:
#NC_045512.2     241     .       C       T       49314.0 PASS    DP=5101;AF=0.993923;SB=46;DP4=0,21,2067,3003;ANN=T|intergenic_region|MODIFIER|CHR_START-ORF1ab|CHR_START-GU280_gp01|intergenic_region|CHR_START-GU280_gp01|||n.241C>T||||||

if caller == "ivar":
    for line in filein:
        if line[0] == "#":
            fileout.write(line)
        else:
            collect = line.rstrip().split("\t")
            truevar = (collect[6]=="TRUE")
            proportion = float(collect[-1].split(":")[-1])
            depth = int(collect[-1].split(":")[3].split(",")[0]) +  int(collect[-1].split(":")[3].split(",")[1])
            if (proportion >= proportionthreshold) and (depth >= depththreshold) and (truevar):
                fileout.write(line)
if caller == "lofreq":
    for line in filein:
        if line[0] == "#":
            fileout.write(line)
        else:
            collect = line.rstrip().split("\t")
            proportion = float(collect[-1].split(";AF=")[1].split(";")[0])
            truevar = (collect[6]=="PASS")
            depth = int(collect[-1].split("DP=")[1].split(";")[0])
            if (proportion >= proportionthreshold) and (depth >= depththreshold) and (truevar):
                fileout.write(line)
filein.close()
fileout.close()
