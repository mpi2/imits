#encoding: utf-8

Factory.define :user do |user|
  user.sequence(:email) { |n| "user#{n}@example.com" }
  user.password 'password'
  user.production_centre { Centre.find_by_name!('WTSI') }
end

Factory.define :pipeline do |pipeline|
  pipeline.sequence(:name) { |n| "Auto-generated Pipeline Name #{n}" }
  pipeline.description 'Pipeline Description'
end

Factory.define :gene do |gene|
  gene.sequence(:marker_symbol) { |n| "Auto-generated Symbol #{n}" }
  gene.sequence(:mgi_accession_id) { |n| "MGI:#{"%.10i" % n}" }
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

Factory.define :es_cell do |es_cell|
  es_cell.sequence(:name) { |n| "Auto-generated ES Cell Name #{n}" }
  es_cell.allele_symbol_superscript 'tm1a(EUCOMM)Wtsi'
  es_cell.association(:pipeline) { Pipeline.find_by_name! 'EUCOMM' }
  es_cell.association(:gene)
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

Factory.define :mi_plan_with_recent_status_history, :parent => :mi_plan do |mi_plan|
  mi_plan.after_create do |plan|
    plan.status = MiPlan::Status["Assigned - ES Cell QC Complete"]
    plan.save!
  end
end

Factory.define :mi_attempt do |mi_attempt|
  mi_attempt.association :es_cell
  mi_attempt.consortium_name 'EUCOMM-EUMODIC'
  mi_attempt.production_centre_name 'WTSI'
  mi_attempt.mi_date { Date.today }
end

Factory.define :mi_attempt_distribution_centre, :class => MiAttempt::DistributionCentre do |distribution_centre|
  distribution_centre.association :centre
  distribution_centre.association :deposited_material
  distribution_centre.association :mi_attempt
  distribution_centre.start_date (Date.today - 1.year).to_time.strftime('%Y-%m-%d')
  distribution_centre.end_date (Date.today).to_time.strftime('%Y-%m-%d')
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

Factory.define :mi_attempt_with_status_history, :parent => :mi_attempt_genotype_confirmed do |mi_attempt|
  mi_attempt.after_create do |mi|
    mi.status_stamps.destroy_all

    mi.status_stamps.create!(
      :mi_attempt_status => MiAttemptStatus.genotype_confirmed,
      :created_at => Time.parse('2011-07-07 12:00:00'))
    mi.status_stamps.create!(
      :mi_attempt_status => MiAttemptStatus.micro_injection_aborted,
      :created_at => Time.parse('2011-06-06 12:00:00'))
    mi.status_stamps.create!(
      :mi_attempt_status => MiAttemptStatus.genotype_confirmed,
      :created_at => Time.parse('2011-05-05 12:00:00'))
    mi.status_stamps.create!(
      :mi_attempt_status => MiAttemptStatus.micro_injection_in_progress,
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
      :mi_attempt_status => MiAttemptStatus.genotype_confirmed,
      :created_at => (Time.now - 1.hour))
    mi.status_stamps.create!(
      :mi_attempt_status => MiAttemptStatus.micro_injection_in_progress,
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

Factory.define :populated_phenotype_attempt, :parent => :phenotype_attempt do |phenotype_attempt|
  phenotype_attempt.rederivation_started true
  phenotype_attempt.rederivation_complete true
  phenotype_attempt.deleter_strain {DeleterStrain.first}
  phenotype_attempt.number_of_cre_matings_successful { rand(10..50)}
  phenotype_attempt.phenotyping_started true
  phenotype_attempt.phenotyping_complete true
  phenotype_attempt.mouse_allele_type 'b'
end

Factory.define :phenotype_attempt_with_recent_status_history, :parent => :populated_phenotype_attempt do |phenotype_attempt|
  phenotype_attempt.after_create do |pa|
    pa.status_stamps.destroy_all

    pa.status_stamps.create!(
      :status => PhenotypeAttempt::Status["Phenotype Attempt Registered"],
      :created_at => (Time.now - 1.hour)
      )
    pa.status_stamps.create!(
      :status => PhenotypeAttempt::Status["Phenotyping Complete"],
      :created_at => (Time.now - 30.minute)
      )
    pa.status_stamps.reload

    pa.mi_attempt.status_stamps.create!(
      :mi_attempt_status => MiAttemptStatus.genotype_confirmed,
      :created_at => (Time.now - 1.hour))
    pa.mi_attempt.status_stamps.create!(
      :mi_attempt_status => MiAttemptStatus.micro_injection_in_progress,
      :created_at => (Time.now - 1.month))


    pa.mi_plan.status_stamps.create!(
      :status => MiPlan::Status["Assigned - ES Cell QC Complete"],
      :created_at => (Time.now - 10.day))
    pa.mi_plan.status_stamps.create!(
      :status => MiPlan::Status[:Assigned],
      :created_at => (Time.now - 10.month))
    pa.mi_plan.status_stamps.create!(
      :status => MiPlan::Status[:Interest],
      :created_at => (Time.now - 20.month))


  end
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
  es_cell.pipeline { Pipeline.find_by_name! 'EUCOMM' }
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
  end
end

Factory.define :es_cell_EPD0343_1_H06_without_mi_attempts, :parent => :es_cell do |es_cell|
  es_cell.name 'EPD0343_1_H06'
  es_cell.association :gene, :marker_symbol => 'Myo1c'
  es_cell.allele_symbol_superscript 'tm1a(EUCOMM)Wtsi'
  es_cell.pipeline { Pipeline.find_by_name! 'EUCOMM' }
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
  end
end

Factory.define :es_cell_EPD0029_1_G04, :parent => :es_cell do |es_cell|
  es_cell.name 'EPD0029_1_G04'
  es_cell.association :gene, :marker_symbol => 'Gatc'
  es_cell.allele_symbol_superscript 'tm1a(KOMP)Wtsi'
  es_cell.pipeline { Pipeline.find_by_name! 'KOMP-CSD' }

  es_cell.after_create do |es_cell|
    mi_attempt = Factory.create(:mi_attempt,
      :es_cell => es_cell,
      :colony_name => 'MBFD',
      :consortium_name => 'MGP',
      :production_centre_name => 'WTSI'
    )
  end
end

Factory.define :es_cell_EPD0011_1_G18, :parent => :es_cell do |es_cell|
  es_cell.name 'EPD0011_1_G18'
  es_cell.association :gene, :marker_symbol => 'Gatc'
  es_cell.allele_symbol_superscript 'tm1a(KOMP)Wtsi'
  es_cell.pipeline { Pipeline.find_by_name! 'KOMP-CSD' }

  es_cell.after_create do |es_cell|

    mi_attempt = Factory.create(:mi_attempt,
      :es_cell => es_cell,
      :colony_name => 'MBFD',
      :consortium_name => 'MGP',
      :production_centre_name => 'WTSI'
    )
    mi_attempt_status = MiAttemptStatus.find_by_description('Genotype confirmed')
    mi_attempt.mi_attempt_status = mi_attempt_status
    phenotype_attempt = Factory.create :populated_phenotype_attempt, :mi_attempt => mi_attempt
  end


end

Factory.define :report_cache do |report_cache|
  report_cache.sequence(:name) { |n| "Report Cache #{n}"}
  report_cache.data ''
  report_cache.format 'csv'
end
