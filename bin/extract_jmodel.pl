#!/usr/bin/env perl

use warnings;
use Getopt::Long;
use IO::File;
use Data::Dumper;

#Pick up script name automatically for usage message
my $script=substr($0, 1+rindex($0,'/'));

#Set usage message
my $usage="Usage: $script -jmodel jmodel_out_file -aictree aic_besttree_name -bictree bic_besttree_name\nPlease try again.\n\n\n";

#Declare all variables needed by GetOpt
my ($jmodel, $aictree, $bictree);

#Get command-line parameters with GetOptions, and check that all needed are there, otherwise die with usage message
die $usage unless
	&GetOptions(
					'jmodel:s' => \$jmodel,
					'aictree:s' => \$aictree,
					'bictree:s' => \$bictree
				)
	&& $jmodel && $aictree && $bictree;


print STDERR "the script is writing the tree into the files $aictree and $bictree\n\n";

open (FILE, $jmodel);

my @models;


while(<FILE>){

	if ($_=~/Tree for the best/) {
		push @models, $_;
	}
	else {
		next;
	}
}



foreach my $model_line (@models){

	my ($model_name, $tree_data) =  ($model_line =~ m/Tree\sfor\sthe\sbest\s(\w+)\smodel\s\=\s(.*)/);

	print STDERR "printing tree for $model_name model\n";

	if ($model_name eq "AIC"){
		open (AICTREE, ">$aictree");
		print AICTREE $tree_data;
		close (AICTREE);
	}
	else {
		open (BICTREE, ">$bictree");
		print BICTREE $tree_data;
		close (BICTREE);
	}


}

close (FILE);
