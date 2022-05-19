#!/usr/bin/env python

# Synopsis: substitute fasta header in file[1] with string[2] and write output to file[3]. For mutlifasta file, numeric character used to append
# Author: Martin Gordon
# Date: 18-05-22


import os
import sys

# script takes 3 arguments; input fasta, string to substitute and output file

fasta_in = open(sys.argv[1], "r")
sub_fa = sys.argv[2]
fasta_out = open(sys.argv[3], "w")


# for multifasta file, add a unique id to 
counter=0

for line in fasta_in:
	if line.startswith('>'):
		counter = counter + 1
		print(counter)
		print(line)
		newname=('>' + str(sub_fa) + '.' + str(counter)) 
		print(newname)	
		fasta_out.write(newname + "\n")
	else:
		fasta_out.write(line)