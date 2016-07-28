package SiteSpecificRecombination;
{
  $SiteSpecificRecombination::VERSION = '1.0.5';
}

use warnings FATAL => 'all';
use strict;
use Bio::SeqUtils;
use Bio::Range;
use Const::Fast;
use Sub::Exporter -setup => { exports => ['apply_cre', 'apply_flp', 'apply_flp_cre'] };

const my %SSR_TARGET_SEQS => (
    LOXP =>   'ATAACTTCGTATAGCATACATTATACGAAGTTAT', # see http://arep.med.harvard.edu/labgc/adnan/projects/Utilities/revcomp.html
    LOXPRC => 'ATAACTTCGTATAATGTATGCTATACGAAGTTAT',
    FRT  =>   'GAAGTTCCTATTCCGAAGTTCCTATTCTCTAGAAAGTATAGGAACTTC'
);

const my @ANNOTATIONS => (
    'display_id',
    'species',
    'desc',
    'is_circular',
);

sub apply_cre {
    my $seq = shift;

    my $loxps1 = _find_ssr_target($seq, 'LOXP');
    my $loxps2 = undef;

    if(!$loxps1) {
      $loxps2 = _find_ssr_target($seq, 'LOXPRC');
    }

    die "LOXP problem: both LOXP and LOXPC found!" if($loxps1 && $loxps2);
    die "LOXP problem: neither LOXP or LOXPRC found!" if(!$loxps1 && !$loxps2);

    my $loxps = $loxps1 || $loxps2;

    my $modified_seq = _recombinate_sequence($loxps, $seq);

    return _clean_sequence($modified_seq, $seq);
}

sub apply_flp {
    my $seq = shift;

    my $frts = _find_ssr_target($seq, 'FRT');

    my $modified_seq = _recombinate_sequence($frts, $seq);

    return _clean_sequence($modified_seq, $seq);
}

sub apply_flp_cre {
    my $seq = shift;

    my $flp_seq = apply_flp($seq);

    my $cre_seq = apply_cre($flp_seq);

    return $cre_seq;
}

sub _clean_sequence{
    my ( $modified_seq, $seq ) = @_;

    #remove cassette source feature
    my @cleaned_features = grep { not _is_cassette_source($_) } $modified_seq->remove_SeqFeatures();
    $modified_seq->add_SeqFeature(@cleaned_features);

    #add back annotation
    for my $annotation (@ANNOTATIONS) {
        $modified_seq->$annotation($seq->$annotation)
            if $seq->$annotation;
    }

    #comments have been duplicated, replace with original comments
    my $design_id;
    $modified_seq->annotation->remove_Annotations('comment');

    for my $annotation ( $seq->annotation->get_Annotations('comment') ) {
        $modified_seq->annotation->add_Annotation('comment',$annotation);
        if ($annotation->as_text =~ /design_id\s?:\s(\d*)/) {
            $design_id = $1;
        }
    }

    $modified_seq->annotation->remove_Annotations('dblink');

    if ( $design_id ) {
        $modified_seq->annotation->add_Annotation(
            "dblink",
            Bio::Annotation::DBLink->new(
                -primary_id => "design_id=" . $design_id,
            )
        );
    }

    return $modified_seq;
}

sub _is_cassette_source {
    my $feature = shift;

    return unless $feature->primary_tag eq 'source';
    for my $note ( $feature->get_tag_values('note') ) {
        return 1 if $note =~ /^targeting cassette/i;
    }
    return;
}

sub _are_synthetic_cassettes_contiguous {
    my (@synthetic_cassettes) = @_;

    @synthetic_cassettes = sort {$a->start <=> $b->start} @synthetic_cassettes;

    for (my $i = 1; $i < scalar(@synthetic_cassettes); $i++) {
      die "Synthetic cassettes not contiguous!" if $synthetic_cassettes[$i-1]->end != $synthetic_cassettes[$i]->start;
    }
}

sub _is_feature {
    my ($feat, $itag, $value) = @_;
    foreach my $tag ( $feat->get_all_tags() ) {
      return 1 if($tag eq $itag && join(' ', $feat->get_tag_values($tag)) eq $value);
    }
    return 0;
}

sub _amend_sequence {
    my ($seq) = @_;
    my ($min, $max) = (0, 0);
    my (@features, @synthetic_cassettes, @loxps);

    # split all seq features into 'synthetic cassettes' and everything else
    # delete all features
    # add back in non-synthetic cassette
    # add in merged synthetic cassette feature (if there was one)

    foreach my $feat ( $seq->get_SeqFeatures() ) {
      if(! _is_feature($feat, 'note', 'Synthetic Cassette')) {
        push @features, $feat;
        next;
      }

      push @synthetic_cassettes, $feat;

      $min = $min == 0 ? $feat->start : $min > $feat->start ? $feat->start : $min;
      $max = $max == 0 ? $feat->end : $max < $feat->end ? $feat->end : $max;
    }

    _are_synthetic_cassettes_contiguous(\@synthetic_cassettes);

    $seq->remove_SeqFeatures();

    foreach my $feat ( @features ) {
      $seq->add_SeqFeature($feat);
    }

    if(scalar(@synthetic_cassettes) > 0) {
      my $feat = new Bio::SeqFeature::Generic (
        -start => $min,
        -end => $max,
        -primary => 'misc_feature'
      );

      $feat->add_tag_value('note',"Synthetic Cassette");
      $seq->add_SeqFeature($feat);
    }
}

sub _recombinate_sequence {
    my ($ssr_sites, $seq) = @_;

    my $modified_seq = Bio::Seq->new(
        -alphabet => 'dna',
        -seq      => '',
    );

    my $first_site = $ssr_sites->[0];
    my $last_site  = $ssr_sites->[-1];

    ### predicted length : $seq->length - (($last_site->start -1 ) - ($first_site->start -1 ))
    Bio::SeqUtils->cat(
        $modified_seq,
        Bio::SeqUtils->trunc_with_features($seq, 1 ,$first_site->end ),
        Bio::SeqUtils->trunc_with_features($seq, $last_site->end + 1,  $seq->length)
    );

    _amend_sequence($modified_seq);

    return $modified_seq;
}

sub _find_ssr_target{
    my ($seq, $target) = @_;
    my @target_sites;

    die "Unexpected target ssr sequence: $target"
        unless exists $SSR_TARGET_SEQS{$target};

    my $target_sequence = $SSR_TARGET_SEQS{$target};
    my $target_length = length($target_sequence);

    my $result = index( $seq->seq, $target_sequence);
    my $offset = 0;
    while ($result != -1) {
        my $site = Bio::Range->new(
            -start => $result + 1,
            -end   => $result + $target_length
        );
        push @target_sites, $site;

        $offset = $result + 1;
        $result = index($seq->seq, $target_sequence, $offset);
    }

    if ( scalar(@target_sites) >= 2) {
        return \@target_sites;
    }
    elsif ( scalar(@target_sites) == 1 ) {
        die "Only one $target site found in given sequence, can not carry out recombination";
    }
    else {
        return undef;
    }
}

1;

__END__
=pod

=head1 NAME

HTGT::Utils::SiteSpecificRecombination

=head1 VERSION

version 1.0.5

=head1 AUTHOR

Sajith Perera

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Genome Research Ltd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut