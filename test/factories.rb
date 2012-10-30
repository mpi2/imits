#encoding: utf-8

##
##  Factory helpers - From TargRep
##
Factory.sequence(:pgdgr_plate_name) { |n| "PGDGR_#{n}" }
Factory.sequence(:epd_plate_name)   { |n| "EPD_#{n}" }
Factory.sequence(:pipeline_name)    { |n| "pipeline_name_#{n}" }
Factory.sequence(:ikmc_project_id)  { |n| "project_000#{n}" }
Factory.sequence(:mgi_allele_id)    { |n| "MGI:#{n}" }
Factory.sequence(:centre_name)   { |n| "Centre_#{n}" }


Factory.define :user do |user|
  user.sequence(:email) { |n| "user#{n}@example.com" }
  user.password 'password'
  user.production_centre { Centre.find_by_name!('WTSI') }
end

Factory.define :gene do |gene|
  gene.sequence(:marker_symbol) { |n| "Auto-generated Symbol #{n}" }
  gene.sequence(:mgi_accession_id) { |n| "MGI:#{"%.10i" % n}" }
end

##
## ES Cells - from TargRep
##

Factory.define :es_cell, :class => TargRep::EsCell do |f|
  f.name                { Factory.next(:epd_plate_name) }
  f.parental_cell_line  { ['JM8 parental', 'JM8.F6', 'JM8.N19'][rand(3)] }
  f.mgi_allele_id       { Factory.next(:mgi_allele_id) }
  f.allele_symbol_superscript 'tm1a(EUCOMM)Wtsi'

  ikmc_project_id = Factory.next( :ikmc_project_id )

  f.association :pipeline, :factory => :pipeline
  f.association :allele, :factory => :allele
  f.targeting_vector { |es_cell|
    es_cell.association( :targeting_vector, {
      :allele_id       => es_cell.allele_id,
      :ikmc_project_id => ikmc_project_id
    })
  }
  f.ikmc_project_id { ikmc_project_id }
end

Factory.define :invalid_escell, :class => TargRep::EsCell do |f|
end

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

Factory.define :centre do |centre|
  centre.sequence(:name) { |n| "Auto-generated Centre Name #{n}" }
end

Factory.define :deposited_material do |deposited_material|
  deposited_material.sequence(:name) { |n| "Auto-generated Deposited Material #{n}"}
end

Factory.define :consortium do |consortium|
  consortium.sequence(:name) { |n| "Auto-generated Consortium Name #{n}" }
end

Factory.define :mi_plan do |mi_plan|
  mi_plan.association :gene
  mi_plan.association :consortium
  mi_plan.status   { MiPlan::Status.find_by_name! 'Interest' }
  mi_plan.priority { MiPlan::Priority.find_by_name! 'High' }
end

Factory.define :mi_plan_with_production_centre, :parent => :mi_plan do |mi_plan|
  mi_plan.association :production_centre, :factory => :centre
end

# TODO Remove this factory, it is only used in 1 place
Factory.define :mi_plan_with_recent_status_history, :parent => :mi_plan do |mi_plan|
  mi_plan.after_create do |plan|
    plan.number_of_es_cells_passing_qc = 2
    plan.save!
  end
end

Factory.define :mi_attempt do |mi_attempt|
  mi_attempt.association :es_cell
  mi_attempt.consortium_name 'EUCOMM-EUMODIC'
  mi_attempt.production_centre_name 'WTSI'
  mi_attempt.mi_date { Date.today }
end

Factory.define :mi_attempt2, :class => MiAttempt do |mi_attempt|
  mi_attempt.association :mi_plan
  mi_attempt.es_cell { |mi| Factory.create(:es_cell, :gene => mi.mi_plan.gene) }
  mi_attempt.mi_date { Date.today }
end

Factory.define :mi_attempt_chimeras_obtained, :parent => :mi_attempt do |mi_attempt|
  mi_attempt.total_male_chimeras 1
end

Factory.define :public_mi_attempt, :class => Public::MiAttempt do |mi_attempt|
  mi_attempt.es_cell_name { Factory.create(:es_cell).name }
  mi_attempt.consortium_name 'EUCOMM-EUMODIC'
  mi_attempt.production_centre_name 'WTSI'
  mi_attempt.mi_date { Date.today }
end

Factory.define :mi_attempt_genotype_confirmed, :parent => :mi_attempt_chimeras_obtained do |mi_attempt|
  mi_attempt.production_centre_name 'ICS'
  mi_attempt.number_of_het_offspring 1
end

Factory.define :wtsi_mi_attempt_genotype_confirmed, :parent => :mi_attempt_chimeras_obtained do |mi_attempt|
  mi_attempt.production_centre_name 'WTSI'
  mi_attempt.is_released_from_genotyping true
end

# TODO Remove this, move the set up of this test data to the one test where the
# test data is used
Factory.define :mi_attempt_with_status_history, :parent => :mi_attempt_genotype_confirmed do |mi_attempt|
  mi_attempt.after_create do |mi|
    mi.status_stamps.destroy_all

    mi.status_stamps.create!(
      :status => MiAttempt::Status.genotype_confirmed,
      :created_at => Time.parse('2011-07-07 12:00:00'))
    mi.status_stamps.create!(
      :status => MiAttempt::Status.micro_injection_aborted,
      :created_at => Time.parse('2011-06-06 12:00:00'))
    mi.status_stamps.create!(
      :status => MiAttempt::Status.genotype_confirmed,
      :created_at => Time.parse('2011-05-05 12:00:00'))
    mi.status_stamps.create!(
      :status => MiAttempt::Status.micro_injection_in_progress,
      :created_at => Time.parse('2011-04-04 12:00:00'))

    mi.mi_plan.status_stamps.first.update_attributes(:created_at => Time.parse('2011-03-03 12:00:00'))
    mi.mi_plan.status_stamps.create!(
      :status => MiPlan::Status[:Conflict],
      :created_at => Time.parse('2011-02-02 12:00:00'))
    mi.mi_plan.status_stamps.create!(
      :status => MiPlan::Status[:Interest],
      :created_at => Time.parse('2011-01-01 12:00:00'))

    mi.mi_plan.status_stamps.reload
    mi.status_stamps.reload
  end
end

Factory.define :mi_attempt_with_recent_status_history, :parent => :mi_attempt_genotype_confirmed do |mi_attempt|
  mi_attempt.after_create do |mi|
    mi.status_stamps.destroy_all

    mi.status_stamps.create!(
      :status => MiAttempt::Status.genotype_confirmed,
      :created_at => (Time.now - 1.hour))
    mi.status_stamps.create!(
      :status => MiAttempt::Status.micro_injection_in_progress,
      :created_at => (Time.now - 1.month))

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

Factory.define :phenotype_attempt do |phenotype_attempt|
  phenotype_attempt.association :mi_attempt, :factory => :mi_attempt_genotype_confirmed
end

Factory.define :public_phenotype_attempt, :class => Public::PhenotypeAttempt do |phenotype_attempt|
  phenotype_attempt.mi_attempt_colony_name { Factory.create(:mi_attempt_genotype_confirmed).colony_name }
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

Factory.define :randomly_populated_gene, :parent => :gene do |gene|
  gene.marker_symbol { (1..4).map { ('a'..'z').to_a.sample }.push((1..9).to_a.sample).join.capitalize }
end

Factory.define :randomly_populated_es_cell, :parent => :es_cell do |es_cell|
  es_cell.allele_symbol_superscript_template 'tm1@(EUCOMM)Wtsi'
  es_cell.allele_type { ('a'..'e').to_a.sample }
  es_cell.association :gene, :factory => :randomly_populated_gene
end

Factory.define :randomly_populated_mi_attempt, :parent => :mi_attempt do |mi_attempt|
  mi_attempt.blast_strain { Strain.all.sample }
  mi_attempt.test_cross_strain { Strain.all.sample }
  mi_attempt.colony_background_strain { Strain.all.sample }
  mi_attempt.colony_name { (1..4).to_a.map { ('A'..'Z').to_a.sample }.join }

  MiAttempt.columns.each do |column|
    next if ['id', 'created_at', 'updated_at'].include?(column.name.to_s)
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
  distribution_centre.association :mi_attempt, :factory => :mi_attempt_genotype_confirmed
end

Factory.define :phenotype_attempt_distribution_centre, :class => PhenotypeAttempt::DistributionCentre do |distribution_centre|
  distribution_centre.association :centre
  distribution_centre.association :deposited_material
  distribution_centre.association :phenotype_attempt, :factory => :phenotype_attempt_status_cec
end

## TargRep Specific factories

# 4413674 starts the longest sequence VALID of sequential MGI accession IDs
Factory.sequence(:mgi_accession_id) { |n| "MGI:#{n + 4413674}" }

Factory.define :pipeline, :class => TargRep::Pipeline do |pipeline|
  pipeline.name { Factory.next(:pipeline_name) }
  pipeline.description 'Pipeline Description'
end

Factory.define :allele, :class => TargRep::Allele do |f|
  f.sequence(:project_design_id)    { |n| "design id #{n}"}
  f.sequence(:subtype_description)  { |n| "subtype description #{n}" }
  f.sequence(:cassette)             { |n| "cassette #{n}"}
  f.sequence(:backbone)             { |n| "backbone #{n}"}

  f.assembly       "NCBIM37"
  f.chromosome     { [("1".."19").to_a + ['X', 'Y', 'MT']].flatten[rand(22)] }
  f.strand         { ['+', '-'][rand(2)] }
  f.mutation_method { TargRep::MutationMethod.all[rand(TargRep::MutationMethod.all.count)] }
  f.mutation_type    { TargRep::MutationType.find_by_code('crd')  }
  f.mutation_subtype { TargRep::MutationSubtype.all[rand(TargRep::MutationSubtype.all.count)]  }
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
    if !allele.mutation_type.no_loxp_site?
      case allele.strand
        when '+' then 100
        when '-' then 70
      end
    end
  end

  f.loxp_end do |allele|
    if !allele.mutation_type.no_loxp_site?
      case allele.strand
        when '+' then 130
        when '-' then 40
      end
    end
  end
end

Factory.define :invalid_allele, :class => TargRep::Allele do |f|
end

##
## Targeting Vector
##

Factory.define :targeting_vector, :class => TargRep::TargetingVector do |f|
  f.name { Factory.next(:pgdgr_plate_name) }
  f.ikmc_project_id { Factory.next(:ikmc_project_id) }
  f.association :pipeline, :factory => :pipeline
  f.association :allele, :factory => :allele
end

Factory.define :invalid_targeting_vector, :class => TargRep::TargetingVector do |f|
end

##
## EsCellQcConflict
##

Factory.define :es_cell_qc_conflict, :class => TargRep::EsCellQcConflict do |f|
  qc_field  = TargRep::EsCell::ESCELL_QC_OPTIONS.keys[ rand(TargRep::EsCell::ESCELL_QC_OPTIONS.size) - 1 ]
  qc_values = TargRep::EsCell::ESCELL_QC_OPTIONS[qc_field][:values]

  current_result  = qc_values.first
  proposed_result = qc_values[ rand(qc_values.size - 1) + 1 ]

  f.qc_field        { qc_field.to_s }
  f.proposed_result { proposed_result }

  f.es_cell { |conflict|
    conflict.association( :es_cell, {
      qc_field.to_sym => current_result
    })
  }
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
  f.name { Factory.next(:centre_name) }
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


#Specifics

Factory.define :gene_cbx1, :parent => :gene do |gene|
  gene.marker_symbol 'Cbx1'
  gene.mgi_accession_id 'MGI:105369'
end

Factory.define :gene_trafd1, :parent => :gene do |gene|
  gene.marker_symbol 'Trafd1'
  gene.mgi_accession_id 'MGI:1923551'
end

Factory.define :es_cell_EPD0127_4_E01_without_mi_attempts, :parent => :es_cell do |es_cell|
  es_cell.name 'EPD0127_4_E01'
  es_cell.association(:gene, :factory => :gene_trafd1)
  es_cell.allele_symbol_superscript 'tm1a(EUCOMM)Wtsi'
  es_cell.pipeline { TargRep::Pipeline.find_by_name! 'EUCOMM' }
end

Factory.define :es_cell_EPD0127_4_E01, :parent => :es_cell_EPD0127_4_E01_without_mi_attempts do |es_cell|
  es_cell.after_create do |es_cell|
    common_attrs = {
      :consortium_name => 'EUCOMM-EUMODIC',
      :production_centre_name => 'ICS'
    }

    Factory.create(:mi_attempt,
      common_attrs.merge(
        :es_cell => es_cell,
        :colony_name => 'MBSS'
      )
    )

    Factory.create(:mi_attempt,
      common_attrs.merge(
        :es_cell => es_cell
      )
    )

    Factory.create(:mi_attempt,
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
  es_cell.association :gene, :marker_symbol => 'Myo1c'
  es_cell.allele_symbol_superscript 'tm1a(EUCOMM)Wtsi'
  es_cell.pipeline {TargRep::Pipeline.find_by_name! 'EUCOMM' }
end

Factory.define :es_cell_EPD0343_1_H06, :parent => :es_cell_EPD0343_1_H06_without_mi_attempts do |es_cell|
  es_cell.after_create do |es_cell|

    Factory.create(:mi_attempt,
      :es_cell => es_cell,
      :colony_name => 'MDCF',
      :production_centre_name => 'WTSI',
      :mi_date => Date.parse('2010-09-13'),
      :consortium_name => 'EUCOMM-EUMODIC'
    )

    es_cell.reload
  end
end

Factory.define :es_cell_EPD0029_1_G04, :parent => :es_cell do |es_cell|
  es_cell.name 'EPD0029_1_G04'
  es_cell.association :gene, :marker_symbol => 'Gatc'
  es_cell.allele_symbol_superscript 'tm1a(KOMP)Wtsi'
  es_cell.pipeline { TargRep::Pipeline.find_by_name! 'KOMP-CSD' }

  es_cell.after_create do |es_cell|
    mi_attempt = Factory.create(:mi_attempt,
      :es_cell => es_cell,
      :colony_name => 'MBFD',
      :consortium_name => 'MGP',
      :production_centre_name => 'WTSI'
    )
    es_cell.reload
  end
end

Factory.define :report_cache do |report_cache|
  report_cache.sequence(:name) { |n| "Report Cache #{n}"}
  report_cache.data ''
  report_cache.format 'csv'
end
