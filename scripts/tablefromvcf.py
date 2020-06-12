#This is a script to read annotated VCF files from lofreq and from ivar and extract the variants from them into a nice joint table

import sys
import os

varcallsdir = sys.argv[1]
infiles = os.listdir(varcallsdir)
fileout = open(sys.argv[2], "w")

basicpassreads = 100
basicpassproportion = 0.05

#ivar vcf has lines like:
#NC_045512.2     45      .       G       A       .       FALSE   IVAR_DP=245;IVAR_GFF=NA;IVAR_REFAA=NA;IVAR_ALTAA=NA;ANN=A|intergenic_region|MODIFIER|CHR_START-ORF1ab|CHR_START-GU280_gp01|intergenic_region|CHR_START-GU280_gp01|||n.45G>A||||||       GT:PVAL:AQ:DP:AF        G/A:0.482283:37,32:244,1:0.00408163
#lofreq has lines like:
#NC_045512.2     241     .       C       T       49314.0 PASS    DP=5101;AF=0.993923;SB=46;DP4=0,21,2067,3003;ANN=T|intergenic_region|MODIFIER|CHR_START-ORF1ab|CHR_START-GU280_gp01|intergenic_region|CHR_START-GU280_gp01|||n.241C>T||||||

fileout.write("Sample,Caller,Region,Position,Ref,Alt,Depth,Proportion,Basic_Pass,Gene\n")

for infile in infiles:
    if "_lofreq_raw_anno.vcf" in infile:
        filein = open(varcallsdir+"/"+infile)
        caller = "lofreq"
        samplename = infile.replace("_lofreq_raw_anno.vcf","")
        for line in filein:
            if line[0] == "#":
                continue
            collect = line.rstrip().split("\t")
            chromosome = collect[0]
            position = collect[1]
            ref = collect[3]
            alt = collect[4]
            depth = collect[7].split("DP=")[1].split(";")[0]
            proportion = collect[7].split(";AF=")[1].split(";")[0]
            basicpass = (int(depth) >= basicpassreads) and (float(proportion) >= basicpassproportion)
            gene = collect[7].split(";ANN=")[1].split("|")[3]
            fileout.write(",".join([samplename,caller,chromosome,position,ref,alt,str(depth),str(proportion),str(basicpass),gene])+"\n")
        filein.close()
    if "_ivar_raw_anno.vcf" in infile:
        filein = open(varcallsdir+"/"+infile)
        caller = "ivar"
        samplename = infile.replace("_ivar_raw_anno.vcf","")
        for line in filein:
            if line[0] == "#":
                continue
            collect = line.rstrip().split("\t")
            chromosome = collect[0]
            position = collect[1]
            ref = collect[3]
            alt = collect[4]
            depth = int(collect[9].split(":")[3].split(",")[0]) + int(collect[9].split(":")[3].split(",")[1])
            proportion = collect[9].split(":")[4]
            basicpass = (int(depth) >= basicpassreads) and (float(proportion) >= basicpassproportion)
            gene = collect[7].split(";ANN=")[1].split("|")[3]
            fileout.write(",".join([samplename,caller,chromosome,position,ref,alt,str(depth),str(proportion),str(basicpass),gene])+"\n")
        filein.close()

fileout.close()
