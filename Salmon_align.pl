#!/usr/bin/perl -w
use strict;
use File::Basename;
use Data::Dumper;
use Getopt::Long qw(:config no_ignore_case no_auto_abbrev pass_through);


#use constant Salmon    => ('Beta-0.6.1'  => '~/SalmonBeta-0.6.1/bin/');

# remember to remove this
#report_input_stack();

my (@file_query, $database_path, $user_database_path, $annotation_path, 
$user_annotation_path, $file_names, $root_names, @file_query2,$file_type);


GetOptions( "file_query=s"      => \@file_query,
	    "file_query2=s"     => \@file_query2,
	    "database=s"        => \$database_path,
	    "user_database=s"   => \$user_database_path,
            "annotation=s"      => \$annotation_path,
            "user_annotation=s" => \$user_annotation_path,
	    "file_names=s"      => \$file_names,
	    "root_names=s"      => \$root_names,
	    "file_type=s"	=> \$file_type,
	    );

# sanity check for input data
if (@file_query2) {
    @file_query && @file_query2 || die "Error: At least one file for each paired-end is required\n"; 
    @file_query == @file_query2 || die "Error: Unequal number of files for paired ends\n";
}

if (!($user_database_path || $database_path)) {
    die "No reference set of transcripts was supplied\n";
}
if (@file_query < 1) {
    die "No FASTQ files were supplied\n";
}

my $salmon  = "salmon";

if ($user_database_path) {
  $database_path = $user_database_path;
  unless (`grep \\> $database_path`) {
      die "Error: $database_path  the user supplied file is not a FASTA file";
  }
  my $name = basename($database_path, qw/.fa .fas .fasta .fna/);
  print STDERR "sailfish-indexing $name\n";
  system $salmon . " index -t $database_path -i index -p 16";
  if ($database_path !~ /$name\.fa$/) {
      my $new_path = $database_path;
      $new_path =~ s/$name\.\S+$/$name\.fa/;
      system "cp $database_path $new_path";
  }
  $database_path = $name;
}


my $success = undef;

system "mkdir output";
for my $query_file (@file_query) {
    # Grab any flags or options we don't recognize and pass them as plain text
    # Need to filter out options that are handled by the GetOptions call
    my @args_to_reject = qw(-xxxx);
    my $second_file = shift @file_query2 if @file_query2;

    my $SALMON_ARGS = join(" ", @ARGV);
    foreach my $a (@args_to_reject) {
	if ($SALMON_ARGS =~ /$a/) {
	    report("Most TopHat arguments are legal for use with this script, but $a is not. Please omit it and submit again");
	    exit 1;
	}
    }
chomp(my $basename = `basename $query_file`);
    $basename =~ s/\.\S+$//;
 
 if ($file_type eq "PE"){
          my $align_command = "$salmon quant -i index -1 $query_file -2 $second_file -o $basename $SALMON_ARGS";
	  system $align_command;
	  system "mv $basename output";
	}
 else{
	  my $align_command = "$salmon quant -i index -r $query_file -o $basename $SALMON_ARGS";
	  system $align_command;
	  system "mv $basename output";
	}

}


sub report {
    print STDERR "$_[0]\n";
}

sub report_input_stack {
    my @stack = @ARGV;
    report(Dumper \@stack);
}
