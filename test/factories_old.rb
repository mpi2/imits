#encoding: utf-8

##
## Users
##

Factory.define :user do |user|
  user.sequence(:email) { |n| "user#{n}@example.com" }
  user.password 'password'
  user.production_centre { Centre.find_by_name!('WTSI') }
end

Factory.define :admin_user, :parent => :user do |user|
  user.email 'vvi@sanger.ac.uk'
  user.admin true
end

##
## Contacts and Notification emails
##
Factory.define :contact do |contact|
  contact.sequence(:email) { |n| "contact#{n}@example.com"}
end

Factory.define :notification do |notification|
  notification.association(:gene)
  notification.association(:contact)
  notification.welcome_email_sent Date.yesterday.to_time
  notification.welcome_email_text 'Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.'
  notification.last_email_sent Time.now - 1.hour
  notification.last_email_text 'Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.'
end

Factory.define :notification_simple, :class => Notification  do |notification|
  notification.association(:gene)
  notification.association(:contact)
end

##
## Genes
##

Factory.define :gene do |gene|
  gene.sequence(:marker_symbol) { |n| "Auto-generated Symbol #{n}" }
  gene.sequence(:mgi_accession_id) { |n| "MGI:#{"%.10i" % n}" }
end

Factory.define :randomly_populated_gene, :parent => :gene do |gene|
  gene.marker_symbol { (1..4).map { ('a'..'z').to_a.sample }.push((1..9).to_a.sample).join.capitalize }
end

Factory.define :gene_cbx1, :parent => :gene do |gene|
  gene.marker_symbol 'Cbx1'
  gene.mgi_accession_id 'MGI:105369'
end

Factory.define :gene_trafd1, :parent => :gene do |gene|
  gene.marker_symbol 'Trafd1'
  gene.mgi_accession_id 'MGI:1923551'
end

Factory.define :gene_myolc, :parent => :gene do |gene|
  gene.marker_symbol 'Myo1c'
  gene.mgi_accession_id 'MGI:1923352'
end

Factory.define :gene_gatc, :parent => :gene do |gene|
  gene.marker_symbol 'Gatc'
  gene.mgi_accession_id 'MGI:1923353'
end
## TargRep Specific factories

# 4413674 starts the longest sequence VALID of sequential MGI accession IDs
Factory.sequence(:mgi_accession_id) { |n| "MGI:#{n + 4413674}" }

##
## IKMC Project - from TargRep
##

Factory.define :ikmc_project, :class => 'TargRep::IkmcProject' do |f|
  f.association :status,   :factory => :ikmc_project_status
  f.association :pipeline,   :factory => :ikmc_project_pipeline
  f.sequence(:name)  { |n| "ikmc_project_name_000#{n}" }
end

Factory.define :ikmc_project_status, :class => 'TargRep::IkmcProject::Status' do |f|
  f.sequence(:name)  { |n| "ikmc_project_status_name_000#{n}" }
end

##
## Pipelines - from TargRep
##

Factory.define :pipeline, :class => TargRep::Pipeline do |pipeline|
  pipeline.sequence(:name) { |n| "Auto-generated Pipeline Name #{n}" }
  pipeline.description 'Pipeline Description'
end

Factory.define :invalid_pipeline, :class => TargRep::Pipeline do |f|
end

Factory.define :ikmc_project_pipeline, :class => "TargRep::Pipeline" do |f|
  f.sequence(:name)  { |n| "ikmc_project_pipeline_name_000#{n}" }
end

##
## Alleles - from TargRep
##

Factory.define :base_allele, :class => TargRep::Allele do |f|
  f.sequence(:project_design_id)    { |n| "design id #{n}"}
  f.sequence(:subtype_description)  { |n| "subtype description #{n}" }
  f.association :gene, :factory => :gene

  f.assembly       "NCBIM37"
  f.chromosome     { [("1".."19").to_a + ['X', 'Y', 'MT']].flatten[rand(22)] }
  f.strand         { ['+', '-'][rand(2)] }
  f.mutation_method { TargRep::MutationMethod.all[rand(TargRep::MutationMethod.all.count)] }
  f.mutation_type    { TargRep::MutationType.find_by_code('crd') }
  f.mutation_subtype { TargRep::MutationSubtype.all[rand(TargRep::MutationSubtype.all.count)] }
end


Factory.define :gene_trap, :class => TargRep::GeneTrap, :parent => :base_allele do |f|
  f.mutation_method { TargRep::MutationMethod.find_by_code('gt') }
  f.mutation_type    { TargRep::MutationType.find_by_code('gt') }

  f.sequence(:intron)               { (1..10).to_a[rand(10)] }
  f.sequence(:cassette)             { |n| "cassette #{n}"}
  f.cassette_type  { ['Promotorless','Promotor Driven'][rand(2)] }

  # Cassette
  f.cassette_start do |allele|
    case allele.strand
      when '+' then 40
      when '-' then 130
    end
  end

  f.cassette_end do |allele|
    case allele.strand
      when '+' then 70
      when '-' then 100
    end
  end

end

Factory.define :allele, :class => TargRep::TargetedAllele, :parent => :base_allele do |f|
  f.sequence(:cassette)             { |n| "cassette #{n}"}
  f.sequence(:backbone)             { |n| "backbone #{n}"}
  f.cassette_type  { ['Promotorless','Promotor Driven'][rand(2)] }

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
  f.homology_arm_start do |allele|
    case allele.strand
      when '+' then 10
      when '-' then 160
    end
  end

  f.homology_arm_end do |allele|
    case allele.strand
      when '+' then 160
      when '-' then 10
    end
  end

  # Cassette
  f.cassette_start do |allele|
    case allele.strand
      when '+' then 40
      when '-' then 130
    end
  end

  f.cassette_end do |allele|
    case allele.strand
      when '+' then 70
      when '-' then 100
    end
  end

  # LoxP
  f.loxp_start do |allele|
    if allele.mutation_type && !allele.mutation_type.no_loxp_site?
      case allele.strand
        when '+' then 100
        when '-' then 70
      end
    end
  end

  f.loxp_end do |allele|
    if allele.mutation_type && !allele.mutation_type.no_loxp_site?
      case allele.strand
        when '+' then 130
        when '-' then 40
      end
    end
  end
end

Factory.define :invalid_allele, :class => TargRep::TargetedAllele do |f|
end


Factory.define :crispr_targeted_allele, :class => TargRep::CrisprTargetedAllele, :parent => :allele do |f|
end

Factory.define :hdr_allele, :class => TargRep::HdrAllele, :parent => :base_allele do |f|
    f.sequence(:backbone)             { |n| "backbone #{n}"}
end

Factory.define :nhej_allele, :class => TargRep::NhejAllele, :parent => :base_allele do |f|
end

Factory.define :allele_with_gene_cbx1, :parent => :allele do |allele|
  allele.association :gene, :factory => :gene_cbx1
end

Factory.define :allele_with_gene_trafd1, :parent => :allele do |allele|
  allele.association :gene, :factory => :gene_trafd1
end

Factory.define :allele_with_gene_myolc, :parent => :allele do |allele|
  allele.association :gene, :factory => :gene_myolc
end

Factory.define :allele_with_gene_gatc, :parent => :allele do |allele|
  allele.association :gene, :factory => :gene_gatc
end

Factory.define :allele_ikmc_project, :parent => :allele do |f|
  f.after_create do |a|
    a.es_cells << Factory.create(:es_cell_ikmc_project)
    a.save!
    a.reload
  end
end

Factory.define :allele_ikmc_project2, :parent => :allele do |f|
  f.after_create do |a|
    a.targeting_vectors << Factory.create(:targeting_vector_ikmc_project)
    a.save!
    a.reload
  end
end
## Alleles END

##
## Real Alleles
##
Factory.define :real_allele, :class => TargRep::RealAllele do |real_allele|
  real_allele.gene_id :gene_id
  real_allele.allele_name :allele_name
end

Factory.define :base_real_allele, :class => TargRep::RealAllele do |real_allele|
  real_allele.association :gene, :factory => :gene
  real_allele.allele_name { "tm1#{(("a".."e").to_a).concat(["e.1", nil]).sample}(EUCOMM)Wtsi" }
end

Factory.define :real_allele_cbx1_a, :class => TargRep::RealAllele do |real_allele|
  real_allele.association :gene, :factory => :gene_cbx1
  real_allele.allele_name "tm1a(EUCOMM)Wtsi"
end

Factory.define :real_allele_cbx1_b, :class => TargRep::RealAllele do |real_allele|
  real_allele.association :gene, :factory => :gene_cbx1
  real_allele.allele_name "tm1b(EUCOMM)Wtsi"
end

Factory.define :real_allele_cbx1_c, :class => TargRep::RealAllele do |real_allele|
  real_allele.association :gene, :factory => :gene_cbx1
  real_allele.allele_name "tm1c(EUCOMM)Wtsi"
end

Factory.define :real_allele_cbx1_d, :class => TargRep::RealAllele do |real_allele|
  real_allele.association :gene, :factory => :gene_cbx1
  real_allele.allele_name "tm1d(EUCOMM)Wtsi"
end

Factory.define :real_allele_cbx1_e, :class => TargRep::RealAllele do |real_allele|
  real_allele.association :gene, :factory => :gene_cbx1
  real_allele.allele_name "tm1e(EUCOMM)Wtsi"
end

Factory.define :real_allele_cbx1_e1, :class => TargRep::RealAllele do |real_allele|
  real_allele.association :gene, :factory => :gene_cbx1
  real_allele.allele_name "tm1e.1(EUCOMM)Wtsi"
end

Factory.define :real_allele_cbx1_del, :class => TargRep::RealAllele do |real_allele|
  real_allele.association :gene, :factory => :gene_cbx1
  real_allele.allele_name "tm1(EUCOMM)Wtsi"
end
## Real Alleles END

##
## ES Cells - from TargRep
##

Factory.define :es_cell, :class => TargRep::EsCell do |f|
  f.sequence(:name)     { |n| "EPD_#{n}" }
  f.parental_cell_line  { ['JM8 parental', 'JM8.F6', 'JM8.N19'].sample }
  f.sequence(:mgi_allele_id)    { |n| "MGI:#{n}" }
  f.allele_symbol_superscript 'tm1a(EUCOMM)Wtsi'

  f.pipeline { TargRep::Pipeline.find_by_name! 'EUCOMM' }
  f.association :allele,   :factory => :allele

  f.sequence(:ikmc_project_id)  { |n| "project_000#{n}" }
end

Factory.define :randomly_populated_es_cell, :parent => :es_cell do |es_cell|
  es_cell.allele_symbol_superscript_template 'tm1@(EUCOMM)Wtsi'
  es_cell.allele_type { ('a'..'e').to_a.sample }
  es_cell.association :gene, :factory => :randomly_populated_gene
end

Factory.define :invalid_escell, :class => TargRep::EsCell do |f|
end

Factory.define :es_cell_EPD0127_4_E01_without_mi_attempts, :parent => :es_cell do |es_cell|
  es_cell.name 'EPD0127_4_E01'
  es_cell.association :allele, :factory => :allele_with_gene_trafd1
  es_cell.allele_symbol_superscript 'tm1a(EUCOMM)Wtsi'
  es_cell.pipeline { TargRep::Pipeline.find_by_name! 'EUCOMM' }
end

Factory.define :es_cell_EPD0127_4_E01, :parent => :es_cell_EPD0127_4_E01_without_mi_attempts do |es_cell|
  es_cell.after_create do |es_cell|
    plan = TestDummy.mi_plan('EUCOMM-EUMODIC', 'ICS', :gene => es_cell.gene)
    common_attrs = {:mi_plan => plan}

    Factory.create(:mi_attempt2,
      common_attrs.merge(
        :es_cell => es_cell,
        :colony_name => 'MBSS'
      )
    )

    Factory.create(:mi_attempt2,
      common_attrs.merge(
        :es_cell => es_cell
      )
    )

    Factory.create(:mi_attempt2,
      common_attrs.merge(
        :es_cell => es_cell,
        :colony_name => 'WBAA'
      )
    )

    es_cell.reload
  end
end

Factory.define :es_cell_EPD0343_1_H06_without_mi_attempts, :parent => :es_cell do |es_cell|
  es_cell.name 'EPD0343_1_H06'
  es_cell.association :allele, :factory => :allele_with_gene_myolc
  es_cell.allele_symbol_superscript 'tm1a(EUCOMM)Wtsi'
  es_cell.pipeline {TargRep::Pipeline.find_by_name! 'EUCOMM' }
end

Factory.define :es_cell_EPD0343_1_H06, :parent => :es_cell_EPD0343_1_H06_without_mi_attempts do |es_cell|
  es_cell.after_create do |es_cell|
    plan = TestDummy.mi_plan('EUCOMM-EUMODIC', 'WTSI', :gene => es_cell.gene)
    Factory.create(:mi_attempt2,
      :es_cell => es_cell,
      :colony_name => 'MDCF',
      :mi_date => Date.parse('2010-09-13'),
      :mi_plan => plan
    )

    es_cell.reload
  end
end

Factory.define :es_cell_EPD0029_1_G04, :parent => :es_cell do |es_cell|
  es_cell.name 'EPD0029_1_G04'
  es_cell.association :allele, :factory => :allele_with_gene_gatc
  es_cell.allele_symbol_superscript 'tm1a(KOMP)Wtsi'
  es_cell.pipeline { TargRep::Pipeline.find_by_name! 'KOMP-CSD' }

  es_cell.after_create do |es_cell|
    mi_attempt = Factory.create(:mi_attempt2,
      :es_cell => es_cell,
      :colony_name => 'MBFD',
      :mi_plan => TestDummy.mi_plan('MGP', 'WTSI', :gene => es_cell.gene)
    )
    es_cell.reload
  end
end

Factory.define :es_cell_ikmc_project, :parent => :es_cell do |f|
  f.association :ikmc_project,   :factory => :ikmc_project
end
## ES Cell END

##
## Targeting Vector - from TargRep
##

Factory.define :targeting_vector, :class => TargRep::TargetingVector do |f|
  f.sequence(:name) { |n| "PGDGR_#{n}" }
  f.sequence(:ikmc_project_id)  { |n| "project_000#{n}" }
  f.pipeline { TargRep::Pipeline.find_by_name! 'EUCOMM' }
  f.association :allele, :factory => :allele
  f.report_to_public true
end

Factory.define :invalid_targeting_vector, :class => TargRep::TargetingVector do |f|
  f.report_to_public true
end

Factory.define :targeting_vector_ikmc_project, :parent => :targeting_vector do |f|
  f.after_create do |tv|
    tv.ikmc_project = Factory.create(:ikmc_project)
    tv.ikmc_project.status.name = ["Vector Complete", "ES Cells - Targeting Confirmed"].sample    # just legal ones for doc factory
    tv.ikmc_project.status.save!
    tv.ikmc_project.status.reload
    tv.save!
    tv.reload
  end
end

##
## GenBank files
##

Factory.define :genbank_file, :class => TargRep::GenbankFile do |f|
  f.sequence(:escell_clone)       { |n| "ES Cell clone file #{n}" }
  f.sequence(:targeting_vector)   { |n| "Targeting vector file #{n}" }

  f.association :allele, :factory => :allele
end

Factory.define :invalid_genbank_file, :class => TargRep::GenbankFile do |f|
end

##
## Now named: EsCellDistributionCentre
##

Factory.define :es_cell_distribution_centre, :class => TargRep::EsCellDistributionCentre do |f|
  f.sequence(:name)   { |n| "Centre_#{n}" }
end

##
## DistributionQc
##

Factory.define :distribution_qc, :class => TargRep::DistributionQc do |f|
  f.association :es_cell_distribution_centre, :factory => :es_cell_distribution_centre
  f.association :es_cell, :factory => :es_cell

  f.five_prime_sr_pcr 'pass'
  f.three_prime_sr_pcr 'fail'
  f.karyotype_low 0.1
  f.karyotype_high 0.9
  f.copy_number 'pass'
  f.five_prime_lr_pcr 'fail'
  f.three_prime_lr_pcr 'pass'
  f.thawing 'fail'
  f.loa 'pass'
  f.loxp 'fail'
  f.lacz 'pass'
  f.chr1 'fail'
  f.chr8a 'pass'
  f.chr8b 'fail'
  f.chr11a 'pass'
  f.chr11b 'fail'
  f.chry 'pass'
end



##
## iMITS
##

##
## Centres
##

Factory.define :centre do |centre|
  centre.sequence(:name) { |n| "Auto-generated Centre Name #{n}" }
end

##
## Consortia
##

Factory.define :consortium do |consortium|
  consortium.sequence(:name) { |n| "Auto-generated Consortium Name #{n}" }
end

##
## Mi Plans
##

Factory.define :mi_plan do |mi_plan|
  mi_plan.association :gene
  mi_plan.association :consortium
  mi_plan.status   { MiPlan::Status.find_by_name! 'Interest' }
  mi_plan.priority { MiPlan::Priority.find_by_name! 'High' }
end

Factory.define :mi_plan_with_production_centre, :parent => :mi_plan do |mi_plan|
  mi_plan.association :production_centre, :factory => :centre
end

Factory.define :mi_plan_phenotype_only, :parent => :mi_plan_with_production_centre do |mi_plan|
  mi_plan.phenotype_only true
end

Factory.define :crispr_plan, :parent => :mi_plan_with_production_centre do |mi_plan|
  mi_plan.mutagenesis_via_crispr_cas9 true
end

# TODO Remove this factory, it is only used in 1 place
Factory.define :mi_plan_with_recent_status_history, :parent => :mi_plan do |mi_plan|
  mi_plan.after_create do |plan|
    plan.number_of_es_cells_passing_qc = 2
    plan.save!
  end
end

Factory.define :mi_plan_with_recent_status_history2, :parent => :mi_plan do |mi_plan|
  mi_plan.after_create do |plan|
    plan.number_of_es_cells_starting_qc = 2
    plan.save!
  end
end

Factory.define :mi_plan_with_recent_status_history3, :parent => :mi_plan do |mi_plan|
  mi_plan.after_create do |plan|
    plan.number_of_es_cells_starting_qc = 2
    plan.save!
    plan.number_of_es_cells_passing_qc = 2
    plan.save!
  end
end

##
## Mutagenesis Factors
##


Factory.define :mutagenesis_factor, :class => MutagenesisFactor do |mf|
  mf.crisprs_attributes [{:chr => [("1".."19").to_a, ['X', 'Y', 'MT']].flatten[rand(22)], :sequence =>(1..23).map{['A','C','G','T'][rand(4)]}.join , :start =>1, :end => 2}]
  mf.association :vector, :factory => :targeting_vector
end

##
## Mi Attempts
##
Factory.define :mi_attempt, :class => MiAttempt do |mi_attempt|
  mi_attempt.association :mi_plan, :factory => :mi_plan_with_production_centre
  mi_attempt.mi_date { Date.today }
end

Factory.define :mi_attempt2, :class => MiAttempt do |mi_attempt|
  mi_attempt.association :mi_plan, :factory => :mi_plan_with_production_centre
  mi_attempt.es_cell { |mi| Factory.create(:es_cell, :allele => Factory.create(:allele, :gene => mi.mi_plan.gene)) }
  mi_attempt.mi_date { Date.today }
end

Factory.define :mi_attempt2_status_chr, :parent => :mi_attempt2 do |mi_attempt|
  mi_attempt.total_male_chimeras 1
end

Factory.define :mi_attempt2_status_gtc, :parent => :mi_attempt2_status_chr do |mi_attempt|
  mi_attempt.after_create do |mi_attempt|
    if mi_attempt.production_centre.name == 'WTSI'
      mi_attempt.update_attributes!(:is_released_from_genotyping => true)
    else
      mi_attempt.update_attributes!(:number_of_het_offspring => 1)
    end
    raise 'Status not gtc!' if ! mi_attempt.has_status? :gtc
  end
end


Factory.define :mi_attempt_crispr, :class => MiAttempt do |mi_attempt|
  mi_attempt.association :mi_plan, :factory => :mi_plan_with_production_centre, :mutagenesis_via_crispr_cas9 => true
  mi_attempt.association :mutagenesis_factor
  mi_attempt.mi_date { Date.today }
end

Factory.define :mi_attempt_crispr_status_fod, :parent => :mi_attempt_crispr do |mi_attempt|
  mi_attempt.crsp_total_num_mutant_founders 1
end


#Factory.define :mi_attempt_crispr_status_gtc, :parent => :mi_attempt_crispr_status_fod do |mi_attempt|
#  mi_attempt.after_create do |mi_attempt|
#  end
#end


Factory.define :mi_attempt_with_recent_status_history, :parent => :mi_attempt2_status_gtc do |mi_attempt|
  mi_attempt.after_create do |mi|

    stamp = mi.status_stamps.where("status_id = #{MiAttempt::Status.genotype_confirmed.id}").first
    stamp.created_at = (Time.now - 1.hour)
    stamp.save

    stamp = mi.status_stamps.where("status_id = #{MiAttempt::Status.micro_injection_in_progress.id}").first
    stamp.created_at = (Time.now - 1.month)
    stamp.save

    mi.mi_plan.status_stamps.first.update_attributes(:created_at => (Time.now - 3.month))
    mi.mi_plan.status_stamps.create!(
      :status => MiPlan::Status[:Conflict],
      :created_at => (Time.now - 4.month))
    mi.mi_plan.status_stamps.create!(
      :status => MiPlan::Status[:Interest],
      :created_at => (Time.now - 5.month))

    mi.mi_plan.status_stamps.reload
    mi.status_stamps.reload
  end
end

Factory.define :mi_attempt2_ikmc_project, :parent => :mi_attempt2_status_chr do |mi_attempt|
  mi_attempt.after_create do |mi|
    ikmc_project = Factory.create(:ikmc_project)
    mi.es_cell.ikmc_project = ikmc_project
    mi.es_cell.save!
    mi.es_cell.reload
  end
end


# Pass in :mi_plan => nil if you want to pass in production_centre_name and consortium_name
Factory.define :public_mi_attempt, :class => Public::MiAttempt do |mi_attempt|
  mi_attempt.association(:mi_plan, :factory => :mi_plan_with_production_centre)
  mi_attempt.es_cell_name do |i|
    if i.mi_plan.try(:gene)
      Factory.create(:es_cell, :allele => Factory.create(:allele, :gene => i.mi_plan.gene)).name
    else
      Factory.create(:es_cell).name
    end
  end
  mi_attempt.mi_date { Date.today }
end

Factory.define :randomly_populated_mi_attempt, :parent => :mi_attempt2_status_chr do |mi_attempt|
  mi_attempt.blast_strain { Strain.all.sample }
  mi_attempt.test_cross_strain { Strain.all.sample }
  mi_attempt.colony_background_strain { Strain.all.sample }
  mi_attempt.colony_name { (1..4).to_a.map { ('A'..'Z').to_a.sample }.join }
  mi_attempt.mi_date { Date.today - 1.month }

  MiAttempt.columns.each do |column|
    next if ['id', 'created_at', 'updated_at', 'mi_date'].include?(column.name.to_s)
    next if column.name.match(/_id$/)

    if column.type == :integer
      mi_attempt.send(column.name) { rand(20) }
    elsif column.type == :date
      mi_attempt.send(column.name) { Date.today.beginning_of_month + rand(29).days }
    elsif column.type == :boolean
      mi_attempt.send(column.name) { [true, false].sample }
    end
  end

  MiAttempt::QC_FIELDS.each do |column_name|
    mi_attempt.send(column_name) { QcResult.all.sample }
  end
end

Factory.define :mi_attempt_distribution_centre, :class => MiAttempt::DistributionCentre do |distribution_centre|
  distribution_centre.association :centre
  distribution_centre.association :deposited_material
  distribution_centre.association :mi_attempt, :factory => :mi_attempt2_status_gtc
end


##
## Phenotype Attempts
##

Factory.define :phenotype_attempt do |phenotype_attempt|
  phenotype_attempt.association :mi_attempt, :factory => :mi_attempt2_status_gtc
  phenotype_attempt.mi_plan { |pa| pa.mi_attempt.mi_plan }
end

Factory.define :public_phenotype_attempt, :class => Public::PhenotypeAttempt do |phenotype_attempt|
  phenotype_attempt.mi_attempt_colony_name { |pa| Factory.create(:mi_attempt2_status_gtc).colony_name }
end

Factory.define :phenotype_attempt_status_cec, :parent => :phenotype_attempt do |phenotype_attempt|
  phenotype_attempt.rederivation_started true
  phenotype_attempt.rederivation_complete true
  phenotype_attempt.deleter_strain {DeleterStrain.first}
  phenotype_attempt.number_of_cre_matings_successful 1
  phenotype_attempt.mouse_allele_type 'b'
  phenotype_attempt.colony_background_strain {Strain.first}
end

Factory.define :phenotype_attempt_status_pdc, :parent => :phenotype_attempt_status_cec do |phenotype_attempt|
  phenotype_attempt.phenotyping_started true
  phenotype_attempt.phenotyping_complete true
end

Factory.define :phenotype_attempt_distribution_centre, :class => PhenotypeAttempt::DistributionCentre do |distribution_centre|
  distribution_centre.association :centre
  distribution_centre.association :deposited_material
  distribution_centre.association :phenotype_attempt, :factory => :phenotype_attempt_status_cec
end

Factory.define :phenotype_attempt_ikmc_project, :parent => :phenotype_attempt do |phenotype_attempt|
  phenotype_attempt.after_create do |pa|
    pa.mi_attempt = Factory.create(:mi_attempt2_ikmc_project)
    pa.mi_attempt.save!
    pa.mi_attempt.reload
  end
end

##
## Deposited Material
##

Factory.define :deposited_material do |deposited_material|
  deposited_material.sequence(:name) { |n| "Auto-generated Deposited Material #{n}"}
end


##
## Solr
##

Factory.define :solr_update_queue_item, :class => SolrUpdate::Queue::Item do |item|
  item.action 'update'
end


Factory.define :solr_update_queue_item_mi_attempt, :parent => :solr_update_queue_item do |item|
  item.sequence(:mi_attempt_id)
end

Factory.define :solr_update_queue_item_phenotype_attempt, :parent => :solr_update_queue_item do |item|
  item.sequence(:phenotype_attempt_id)
end

##
## Reports
##

Factory.define :report_cache do |report_cache|
  report_cache.sequence(:name) { |n| "Report Cache #{n}"}
  report_cache.data ''
  report_cache.format 'csv'
end

Factory.define :production_goal do |production_goal|
  production_goal.consortium { Consortium.first }
  production_goal.year 2012
  production_goal.month 1
  production_goal.mi_goal 123
  production_goal.gc_goal 123
end

Factory.define :tracking_goal do |tracking_goal|
  tracking_goal.production_centre { Centre.first }
  tracking_goal.month (rand(11) + 1)
  tracking_goal.year (2012..2014).to_a[rand(2)]
  tracking_goal.goal_type TrackingGoal::GOAL_TYPES[rand(7)]
  tracking_goal.goal rand(100)
end

Factory.define :email_template_without_status, :class => EmailTemplate do |email_template|
  email_template.status ''

  email_template.welcome_body <<-EOF
      Dear colleague,

      Thank you for registering for gene <%= @gene.marker_symbol %>

      This gene currently <%= @modifier_string %> assigned for mouse production and phenotyping as part of the IMPC initiative.
      <% if @modifier_string == "is not" %>
      This gene will be considered for mouse production by the IMPC.
      <% end %>

      <% if @total_cell_count > 0 %>
      Currently the IKMC has the following mutant ES Cells for this gene;
      <% if @gene.conditional_es_cells_count && @gene.conditional_es_cells_count > 0 %>
      <%= @gene.conditional_es_cells_count %> conditional ES cells
      <% end %>
      <% if @gene.non_conditional_es_cells_count && @gene.non_conditional_es_cells_count > 0 %>
      <%= @gene.non_conditional_es_cells_count %> non-conditional ES cells
      <% end %>
      <% if @gene.deletion_es_cells_count && @gene.deletion_es_cells_count > 0 %>
      <%= @gene.deletion_es_cells_count %> deletions
      <% end %>
      <% else %>
      The IKMC has not produced any targeted mutant ES Cells for this gene.
      This gene will be considered by the EUCOMMTools program for production of targeted mutant ES Cells
      <% end %>

      <% if @modifier_string == "is" %>
      Details of mutant ES Cells, Mouse Production and Phenotyping for this gene can be found at the IMPC site:
      http://www.mousephenotype.org/gene-details?gene_id=<%= @gene.mgi_accession_id %>

      <% elsif @total_cell_count > 0 %>
      Details of targeted mutant ES Cells for this gene can be found here:
      www.knockoutmouse.org/search_results?criteria=<%= @gene.mgi_accession_id %>
      <% end %>

      Updates on gene status will be sent to <%= @contact.email %>.

      For further information / enquiries please write to  mouse-helpdesk@ebi.ac.uk

      Best Regards,

      The MPI2 (KOMP2) informatics consortium.

    EOF

  email_template.update_body <<-EOF
      Dear colleague,

      You have registered interest in this gene via the IMPC (www.mousephenotype.org).

      You are receiving this email because the IMPC production status of the gene has changed.

      <% if @total_cell_count > 0 %>
      Currently the IKMC has the following mutant ES Cells for this gene;
      <% if @gene.conditional_es_cells_count && @gene.conditional_es_cells_count > 0 %>
      <%= @gene.conditional_es_cells_count %> conditional ES cells
      <% end %>
      <% if @gene.non_conditional_es_cells_count && @gene.non_conditional_es_cells_count > 0 %>
      <%= @gene.non_conditional_es_cells_count %> non-conditional ES cells
      <% end %>
      <% if @gene.deletion_es_cells_count && @gene.deletion_es_cells_count > 0 %>
      <%= @gene.deletion_es_cells_count %> deletions
      <% end %>
      <% else %>
      The IKMC has not produced any targeted mutant ES Cells for this gene.
      This gene will be considered by the EUCOMMTools program for production of targeted mutant ES Cells
      <% end %>

      <% if @modifier_string == "is" %>
      Details of mutant ES Cells, Mouse Production and Phenotyping for this gene can be found at the IMPC site:
      http://www.mousephenotype.org/gene-details?gene_id=<%= @gene.mgi_accession_id %>

      <% elsif @total_cell_count > 0 %>
      Details of targeted mutant ES Cells for this gene can be found here:
      www.knockoutmouse.org/search_results?criteria=<%= @gene.mgi_accession_id %>
      <% end %>

      You will be notified by email with any future changes in gene status.

      For further information / enquiries please write to  mouse-helpdesk@ebi.ac.uk

      Best Wishes,

      The MPI2 (KOMP2) informatics consortium.
    EOF
end

Factory.define :email_template_microinjection_aborted, :parent => :email_template_without_status do |et|
  et.status 'microinjection_aborted'
end

Factory.define :email_template_genotype_confirmed, :parent => :email_template_without_status do |et|
  et.status 'genotype_confirmed'
end

Factory.define :email_template_assigned_es_cell_qc_complete, :parent => :email_template_without_status do |et|
  et.status 'assigned_es_cell_qc_complete'
end

Factory.define :email_template_phenotyping_complete, :parent => :email_template_without_status do |et|
  et.status 'phenotyping_complete'
end

Factory.define :email_template_welcome, :class => EmailTemplate do |email_template|

welcome_body = <<-EOF
<% if !Rails.env.production? %>
You have registered at the Beta system, which is subject to constant change. Please go to http://www.mousephenotype.org to register interest.
<% end %>
Dear registered IMPC user

Thank you for registering your interest in the following genes:

<%= @gene_list %>.

Please see the attached csv file for details on the status of each gene in IMPC production, along with links for further information for each gene. (The csv file can be saved and opened inside Microsoft Excel or any other spreadsheet program.)

Further updates on the status of individual genes in this list will be sent to <%= @contact_email %>.

Further all further information / enquiries, please write to mouse-helpdesk@ebi.ac.uk

Best Regards,

The MPI2 (KOMP2) informatics consortium.

EOF

  email_template.status 'welcome_template'
  email_template.welcome_body { welcome_body }
  email_template.update_body  { 'unused' }
end
