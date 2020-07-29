#!/usr/bin/env perl
use warnings FATAL => 'all';
use strict;

use lib '/script';
use SiteSpecificRecombination qw( apply_cre apply_flp apply_flp_cre );

use Bio::SeqIO;
use IO::Handle;
use Getopt::Long;
use Pod::Usage;

GetOptions(
    'help'        => sub { pod2usage( -verbose   => 1 ) },
    apply_cre     => \my $apply_cre,
    apply_flp     => \my $apply_flp,
    apply_flp_cre => \my $apply_flp_cre,
) or pod2usage(2);

my $stream = Bio::SeqIO->newFh( -fh => \*ARGV, -format => 'genbank' );

while (  my $seq = <$stream> ) {
    my $modified_seq;
    if ( $apply_cre ) {
        $modified_seq = apply_cre( $seq );
    }
    elsif ( $apply_flp ) {
        $modified_seq = apply_flp( $seq );
    }
    elsif ( $apply_flp_cre ) {
        $modified_seq = apply_flp_cre( $seq );
    }
    else {
        pod2usage( 'Must specify a recombinse to apply' );
    }

    my $ofh = IO::Handle->new->fdopen( fileno(STDOUT), 'w' );
    my $seq_out = Bio::SeqIO->new( -fh => $ofh, -format => 'genbank' );
    $seq_out->write_seq( $modified_seq );
}