#!/usr/bin/env perl
use strict;
use warnings FATAL => 'all';

use HTGT::QC::Util::CrisprDamageVEP;
use HTGT::QC::Util::SCFVariationSeq;
use Getopt::Long;
use Log::Log4perl ':easy';
use IPC::Run 'run';
use Bio::SeqIO;
use Pod::Usage;
use Path::Class;
use Const::Fast;
use Data::UUID;
use Try::Tiny;

const my $EXTRACT_SEQ_CMD => $ENV{EXTRACT_SEQ_CMD}
    // '/software/badger/bin/extract_seq';

const my $DEFAULT_QC_DIR => $ENV{ DEFAULT_CRISPR_DAMAGE_QC_DIR }
    // '/lustre/scratch109/sanger/team87/imits_crispr_damage_qc';

my $log_level = $INFO;

my ($seq_filename,  $scf_filename, $het_scf_filename,
    $target_start,  $target_end,   $target_chr,
    $target_strand, $species,      $dir
);
GetOptions(
    'help'            => sub { pod2usage( -verbose => 1 ) },
    'man'             => sub { pod2usage( -verbose => 2 ) },
    'debug'           => sub { $log_level = $DEBUG },
    'sequence-file=s' => \$seq_filename,
    'scf-file=s'      => \$scf_filename,
    'het-scf-file=s'  => \$het_scf_filename,
    'target-start=i'  => \$target_start,
    'target-end=i'    => \$target_end,
    'target-chr=s'    => \$target_chr,
    'target-strand=s' => \$target_strand,
    'species=s'       => \$species,
) or pod2usage(2);

pod2usage('Must provide target location information')
    if !$target_start || !$target_end || !$target_chr || !$species || !$target_strand;

Log::Log4perl->easy_init( { level => $log_level, layout => '%p %m%n' } );

my $work_dir = dir( $DEFAULT_QC_DIR )->subdir( Data::UUID->new->create_str );
$work_dir->mkpath;
INFO( "Created work directory $work_dir" );

my $seq_file;
if ( $scf_filename ) {
    my $scf_file = file( $scf_filename )->absolute;
    $seq_file = scf_to_fasta( $scf_file );
}
elsif( $het_scf_filename ) {
    my $scf_file = file( $het_scf_filename )->absolute;
    $seq_file = variant_scf_to_fasta( $scf_file );
}
elsif ( $seq_filename ) {
    $seq_file = file( $seq_filename )->absolute;
}
else {
    pod2usage( 'Must provide a sequence file or scf file' );
}

my $seq_io = Bio::SeqIO->new( -fh => $seq_file->openr, -format => 'Fasta' );
my $bio_seq = $seq_io->next_seq;

my %params = (
    species             => $species,
    dir                 => $work_dir,
    target_start        => $target_start,
    target_end          => $target_end,
    target_chr          => $target_chr,
    forward_primer_read => $bio_seq,
);

INFO('Running crispr damage analysis');
my $qc = HTGT::QC::Util::CrisprDamageVEP->new( %params );

$qc->analyse;

#TODO
# Return more information, possibly in JSON string
print $qc->dir->stringify . "\n";

exit 0;

=head2 variant_scf_to_fasta

Take SCF file with heterozygous trace and return fasta file
containing the variant sequence.

=cut
sub variant_scf_to_fasta {
    my $scf_file = shift;

    my %params = (
        scf_file      => $scf_file,
        species       => $species,
        base_dir      => $work_dir,
        target_start  => $target_start,
        target_end    => $target_end,
        target_chr    => $target_chr,
        target_strand => $target_strand,
    );

    my $scf_converter = HTGT::QC::Util::SCFVariationSeq->new( %params );

    return $scf_converter->get_seq_from_scf;
}

=head2 scf_to_fasta

Extract the called sequence from a SCF file.

=cut
sub scf_to_fasta {
    my $scf_file = shift;
    INFO( 'Converting scf file to fasta file' );

    my $read_seq = $work_dir->file('read_seq.fa')->absolute;
    my @extract_seq_command = (
        $EXTRACT_SEQ_CMD,
        '-scf',                         # align command
        '-fasta_out',                   # reduce gap open penalty ( default 6 )
        $scf_file->stringify,           # query file with read sequences
    );

    my $extract_seq_log_file = $work_dir->file( 'extract_seq.log' )->absolute;
    run( \@extract_seq_command,
        '>', $read_seq->stringify,
        '2>', $extract_seq_log_file->stringify
    ) or die(
            "Failed to run extract_seq command, log file: $extract_seq_log_file" );

    return $read_seq;
}

__END__

=head1 NAME

crispr_damage_analysis.pl - Analyse crispr damage using one primer read

=head1 SYNOPSIS

  crispr_damage_analysis.pl [options]

      --help                      Display a brief help message
      --man                       Display the manual page
      --debug                     Debug output
      --sequence-file             File with primer read sequence
      --scf-file                  SCF file with read trace sequence
      --het-scf-file              SCF file with heterozygous read trace sequence.
      --target-start              * Start coordinate of target region
      --target-end                * End coordinate of target region
      --target-chr                * Chromosome name of target region
      --target-strand             * Strand of target region
      --species                   * Species, either Mouse or Human supported

The parameters marked with a * are required.
You must specify a sequence-file or a scf-file.
The sequence file maybe Fasta or Genbank, only the first sequence in the
file will be used.

=head1 DESCRIPTION

Analyse the possible damage caused by a crispr or crispr pair to a specific
target region ( where the crispr targets ).

Input may be a Fasta file or a SCF file, which represents the sequence from a primer read
that is run across the target site.
If the SCF file with a heterozygous read is passed in the script attempts to extract
the variant / non-wildtype sequence from the trace.

The output from this script include:
- Alignment of read against genome.
- Pileup of read against genome.
- VCF file, only for target region.
- Output from Ensembl Variant Effect Predictor.
- If variant found, reference and mutant protein sequence for targeted gene transcript.

=cut
