#encoding: utf-8
FactoryGirl.define do
##
## iMITS
##

##
## Genes
##

  factory :gene do
    sequence(:marker_symbol) { |n| "Auto-generated Symbol #{n}" }
    sequence(:mgi_accession_id) { |n| "MGI:#{"%.10i" % n}" }
  end

##
## Allele
##
  factory :base_allele, :class => Allele do
    allele_type { ['a', 'e'][rand(2)] }
    sequence(:mgi_allele_symbol_superscript) { |n| "tm1a(KOMP)Wtsi" }
    sequence(:mgi_allele_accession_id) { |n| "MGI:#{"%.10i" % n}" }
  end

##
## Centres
##

  factory :centre do
    sequence(:name) { |n| "Auto-generated Centre Name #{n}" }
  end

##
## Consortia
##

  factory :consortium do
    sequence(:name) { |n| "Auto-generated Consortium Name #{n}" }
  end

##
## Users
##

  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    password 'password'
    production_centre { Centre.find_by_name!('WTSI') }
  end
  
  factory :admin_user, :parent => :user do
    email 'vvi@sanger.ac.uk'
    admin true
end

##
## Contacts
##
  factory :contact do
    sequence(:email) { |n| "contact#{n}@example.com"}
  end


##
## Mi Plans
##

  factory :mi_plan do
    association :gene
    association :consortium
    priority { MiPlan::Priority.find_by_name! 'High' }
  end
  
  factory :mi_plan_with_production_centre, :parent => :mi_plan do
    association :production_centre, :factory => :centre
  end
  
  factory :crispr_plan, :parent => :mi_plan_with_production_centre do
    mutagenesis_via_crispr_cas9 true
  end

  factory :mi_plan_es_cell_qc_only, :parent => :mi_plan_with_production_centre do
    es_cell_qc_only true
  end

  factory :mi_plan_phenotype_only, :parent => :mi_plan_with_production_centre do
    phenotype_only true
  end
  

##
## Models for Mi Attempt Setup 
##

#  factory :mutagenesis_factor, :class => MutagenesisFactor do |mf|
#    mf.crisprs_attributes [{:chr => [("1".."19").to_a, ['X', 'Y', 'MT']].flatten[rand(22)], :sequence =>(1..23).map{['A','C','G','T'][rand(4)]}.join , :start =>1, :end => 2}]
#    mf.association :vector, :factory => :targeting_vector
#  end

##
## Mi Attempts
##
  factory :mi_attempt, :class => MiAttempt do
    association :mi_plan, :factory => :mi_plan_with_production_centre
    sequence(:external_ref) { |n| "EXT:#{n}" }
    es_cell { |mi| FactoryGirl.create(:es_cell, :allele => FactoryGirl.create(:targ_rep_allele, :gene => mi.mi_plan.gene)) }
    mi_date { Date.today }
  end
  
  factory :mi_attempt_status_chr, :parent => :mi_attempt do
    total_male_chimeras 1
  end
  
  factory :mi_attempt_status_gtc, :parent => :mi_attempt_status_chr do
    after(:build)  do |mi_attempt| 
      if mi_attempt.production_centre.name == 'WTSI'
        mi_attempt.is_released_from_genotyping = true
      else
        mi_attempt.number_of_het_offspring = 1
      end
    end
  end
  
  
#  factory :mi_attempt_crispr, :class => MiAttempt do |mi_attempt|
#    mi_attempt.association :mi_plan, :factory => :mi_plan_with_production_centre, :mutagenesis_via_crispr_cas9 => true
#    mi_attempt.association :mutagenesis_factor
#    mi_attempt.mi_date { Date.today }
#  end
#  
#  factory :mi_attempt_crispr_status_fod, :parent => :mi_attempt_crispr do |mi_attempt|
#    mi_attempt.crsp_total_num_mutant_founders 1
#  end



##
## TargRep
##

##
## Allele
##

  factory :base_targ_rep_allele, :class => TargRep::Allele do
    sequence(:project_design_id)    { |n| "design id #{n}"}
    sequence(:subtype_description)  { |n| "subtype description #{n}" }
    association :gene, :factory => :gene
  
    assembly       "NCBIM37"
    chromosome     { [("1".."19").to_a + ['X', 'Y', 'MT']].flatten[rand(22)] }
    strand         { ['+', '-'][rand(2)] }
    mutation_method { TargRep::MutationMethod.all[rand(TargRep::MutationMethod.all.count)] }
    mutation_type    { TargRep::MutationType.find_by_code('crd') }
    mutation_subtype { TargRep::MutationSubtype.all[rand(TargRep::MutationSubtype.all.count)] }
  end


  factory :targ_rep_allele, :class => TargRep::TargetedAllele, :parent => :base_targ_rep_allele do
    sequence(:cassette)             { |n| "cassette #{n}"}
    sequence(:backbone)             { |n| "backbone #{n}"}
    cassette_type  { ['Promotorless','Promotor Driven'][rand(2)] }
  
    #     Features positions chose for this factory:
    #     They have been fixed so that complex tests can be cleaner. Otherwise,
    #     for testing a single feature, each other feature position has to be
    #     reset.
    #
    #     +--------------------+------------+------------+
    #     | Feature            | Strand '+' | Strand '-' |
    #     +--------------------+------------+------------+
    #     | Homology arm start | 10         | 160        |
    #     | Cassette start     | 40         | 130        |
    #     | Cassette end       | 70         | 100        |
    #     | LoxP start         | 100        | 70         | <- Absent for design
    #     | LoxP end           | 130        | 40         | <- type 'Knock Out'
    #     | Homology arm end   | 160        | 10         |
    #     +--------------------+------------+------------+
    #
  
    # Homology arm
    homology_arm_start do |allele|
      case allele.strand
        when '+' then 10
        when '-' then 160
      end
    end
  
    homology_arm_end do |allele|
      case allele.strand
        when '+' then 160
        when '-' then 10
      end
    end
  
    # Cassette
    cassette_start do |allele|
      case allele.strand
        when '+' then 40
        when '-' then 130
      end
    end
  
    cassette_end do |allele|
      case allele.strand
        when '+' then 70
        when '-' then 100
      end
    end
  
    # LoxP
    loxp_start do |allele|
      if allele.mutation_type && !allele.mutation_type.no_loxp_site?
        case allele.strand
          when '+' then 100
          when '-' then 70
        end
      end
    end
  
    loxp_end do |allele|
      if allele.mutation_type && !allele.mutation_type.no_loxp_site?
        case allele.strand
          when '+' then 130
          when '-' then 40
        end
      end
    end
  end

##
## ES Cells
##
  factory :es_cell, :class => TargRep::EsCell do
    sequence(:name)     { |n| "EPD_#{n}" }
    parental_cell_line  { ['JM8 parental', 'JM8.F6', 'JM8.N19'].sample }  
    pipeline { TargRep::Pipeline.find_by_name! 'EUCOMM' }
    association :allele,   :factory => :targ_rep_allele
    alleles {build_list :base_allele, 1}
    sequence(:ikmc_project_id)  { |n| "project_000#{n}" }
  end

end
