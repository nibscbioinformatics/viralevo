use warnings;
use Getopt::Long;
use IO::File;

#Pick up script name automatically for usage message
my $script=substr($0, 1+rindex($0,'/'));

#Set usage message
my $usage="Usage: $script -fasta sequence_multi.fasta -out output_multi.fasta\nPlease try again.\n\n\n";

#Declare all variables needed by GetOpt
my ($fasta, $out);

#Get command-line parameters with GetOptions, and check that all needed are there, otherwise die with usage message
die $usage unless
	&GetOptions(
					'fasta:s' => \$fasta,
          'out:s' => \$out
				)
	&& $fasta;

$out ||= $fasta."_trimmed.fasta";

open(FILE,$fasta) or die "Can't open $fasta: $!";
open(OUT, ">$out") or die "Can't write on $out: $!";
open(TABLE, ">names_conversion_table.txt") or die "Can't write on conversion table: $!";

print TABLE "original\trenamed\n";

my $count=1;
my %namesCheck;

while(<FILE>){
  chomp($_);
  if ($_=~/>/){
    my $name = $_;
    $name =~ s/>//;
    my $newName = str($name, 0, 10);

    if(exists($namesCheck{$newName})){
      $newName = str($newName, 0, 7);
      $newName = $newName."_".$counter;
      $counter++;
    }
    else {
      $namesCheck{$newName} = 1;
    }

    print OUT ">".$newName."\n";
    print TABLE "$name\t$newName\n";

  }
  else {
    print OUT $_."\n";
  }
}
close FILE;
close OUT;
close TABLE;
