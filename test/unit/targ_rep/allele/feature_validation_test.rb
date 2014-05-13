require 'pp'
require 'test_helper'

class TargRep::Allele::FeatureValidationTest < ActiveSupport::TestCase

  context 'TargRep::Allele::FeatureValidation' do

    [:allele, :crispr_targeted_allele].each do |model|
      context "#{model}" do
        setup do
          @allele = Factory.create(model)
          # allele has been saved successfully here
        end


        context "An Allele" do

          context "with an incorrect floxed exon" do
            should "not be saved" do
              allele = Factory.build model, :floxed_start_exon => 'ENSMUSG20913091309'
              assert !allele.save, "Allele is saved with an incorrect Ensembl Exon ID"

              allele2 = Factory.build model, :floxed_end_exon => 'ENSMUSG20913091309'
              assert !allele2.save, "Allele is saved with an incorrect Ensembl Exon ID"
            end
          end

          context "with wrong homology arm position" do
            should "not be saved" do
              # Wrong start and end positions for the given strand
              @wrong_position1  = Factory.build(model, {
                  :strand             => '+',
                  :homology_arm_start => 2,
                  :homology_arm_end   => 1
                })
              @wrong_position2  = Factory.build(model, {
                  :strand             => '-',
                  :homology_arm_start => 1,
                  :homology_arm_end   => 2
                })

              # Homology arm site overlaps other features
              @wrong_position3  = Factory.build(model, {
                  :strand             => '+',
                  :homology_arm_start => 50,
                  :homology_arm_end   => 120
                })
              @wrong_position4  = Factory.build(model, {
                  :strand             => '-',
                  :homology_arm_start => 120,
                  :homology_arm_end   => 50
                })
              assert !@wrong_position1.save, "Homology arm start cannot be greater than LoxP end on strand '+'"
              assert !@wrong_position2.save, "Homology arm end cannot be greater than LoxP start on strand '-'"
              assert !@wrong_position3.save, "Homology arm cannot overlap other features (strand '+')"
              assert !@wrong_position4.save, "Homology arm cannot overlap other features (strand '-')"
            end
          end

          context "with wrong cassette position" do
            should "not be saved" do
              # Wrong start and end positions for the given strand
              @wrong_position1  = Factory.build(model, {
                  :strand         => '+',
                  :cassette_start => 2,
                  :cassette_end   => 1
                })
              @wrong_position2  = Factory.build(model, {
                  :strand         => '-',
                  :cassette_start => 1,
                  :cassette_end   => 2
                })

              # LoxP site overlaps other features
              @wrong_position3  = Factory.build(model, {
                  :strand             => '+',
                  :cassette_start     => 5,
                  :cassette_end       => 170
                })
              @wrong_position4  = Factory.build(model, {
                  :strand             => '-',
                  :cassette_start     => 170,
                  :cassette_end       => 5
                })

              assert !@wrong_position1.save, "Cassette start cannot be greater than LoxP end on strand '+'"
              assert !@wrong_position2.save, "Cassette end cannot be greater than LoxP start on strand '-'"
              assert !@wrong_position3.save, "Cassette cannot overlap other features (strand '+')"
              assert !@wrong_position4.save, "Cassette cannot overlap other features (strand '-')"
            end
          end

          context "with wrong LoxP position" do
            should "not be saved" do
              # Wrong start and end positions for the given strand
              @wrong_position1  = Factory.build(model, {
                  :strand     => '+',
                  :loxp_start => 2,
                  :loxp_end   => 1
                })
              @wrong_position2  = Factory.build(model, {
                  :strand     => '-',
                  :loxp_start => 1,
                  :loxp_end   => 2
                })

              # LoxP site overlaps other features
              @wrong_position3  = Factory.build(model, {
                  :strand             => '+',
                  :loxp_start         => 5,
                  :loxp_end           => 170
                })
              @wrong_position4  = Factory.build(model, {
                  :strand             => '-',
                  :loxp_start         => 170,
                  :loxp_end           => 5
                })

              assert !@wrong_position1.save, "LoxP start cannot be greater than LoxP end (strand '+')"
              assert !@wrong_position2.save, "LoxP end cannot be greater than LoxP start (strand '-')"
              assert !@wrong_position3.save, "LoxP site cannot overlap other features (strand '+')"
              assert !@wrong_position4.save, "LoxP site cannot overlap other features (strand '-')"
            end
          end
        end
      end
    end
  end
end
