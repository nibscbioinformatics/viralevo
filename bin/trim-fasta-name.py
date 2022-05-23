#!/usr/bin/env python

# Shorten fastq header names and use first 10 elements. If duplicates are found take first 7 elements and unique numeric identifier. Write conversion table to file
# Two arguments: input file name and ouput filename
# Author: Martin Gordon
# Date: 20-05-22


import os
import sys


fasta_in = open(sys.argv[1], "r")
name_table = open('names_conversion_table.txt', "w")
fasta_out = open(sys.argv[2], "w")


# variables
counter=1 # unique id
names_dict={} #hold full names (k) and shortened names (v)

# write pairs to file
name_table.write('original' + "\t" + 'renamed\n')

for line in fasta_in:
    if line.startswith('>'):
        newname=line[:11].strip('\n') #take first 11 characters of string (including >) as shortname

        # if short name not unique, loop to generate unique id, write to output, break loop
        while newname in names_dict.values():            
            newname=(line[:8] + '_' + str(counter))
            counter=counter+1
            
            if newname not in names_dict.values():
                counter = 1 #reset id no
                names_dict[line]=newname #update dictionary
                fasta_out.write(newname+'\n')
                name_table.write(line[1:].strip() + "\t" + newname[1:] + '\n')    
                break

        # if name unique write to output
        else:
            names_dict[line]=newname
            fasta_out.write(newname+'\n')
            name_table.write(line[1:].strip() + "\t" + newname[1:] + '\n')

    #write sequence to file
    else:
        fasta_out.write(line)
