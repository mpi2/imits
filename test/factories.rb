#encoding: utf-8

Factory.define :user do |user|
  user.sequence(:email) { |n| "user#{n}@example.com" }
  user.password 'password'
  user.production_centre { Centre.find_by_name!('WTSI') }
end

Factory.define :admin_user, :parent => :user do |user|
  user.email 'vvi@sanger.ac.uk'
  user.admin true
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
  es_cell.allele_id { rand 99999 }
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

Factory.define :mi_attempt2, :class => MiAttempt do |mi_attempt|
  mi_attempt.association :mi_plan, :factory => :mi_plan_with_production_centre
  mi_attempt.es_cell { |mi| Factory.create(:es_cell, :gene => mi.mi_plan.gene) }
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

Factory.define :mi_attempt_with_recent_status_history, :parent => :mi_attempt2_status_gtc do |mi_attempt|
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

# Pass in :mi_plan => nil if you want to pass in production_centre_name and consortium_name
Factory.define :public_mi_attempt, :class => Public::MiAttempt do |mi_attempt|
  mi_attempt.association(:mi_plan, :factory => :mi_plan_with_production_centre)
  mi_attempt.es_cell_name do |i|
    if i.mi_plan.try(:gene)
      Factory.create(:es_cell, :gene => i.mi_plan.gene).name
    else
      Factory.create(:es_cell).name
    end
  end
  mi_attempt.mi_date { Date.today }
end

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

Factory.define :randomly_populated_gene, :parent => :gene do |gene|
  gene.marker_symbol { (1..4).map { ('a'..'z').to_a.sample }.push((1..9).to_a.sample).join.capitalize }
end

Factory.define :randomly_populated_es_cell, :parent => :es_cell do |es_cell|
  es_cell.allele_symbol_superscript_template 'tm1@(EUCOMM)Wtsi'
  es_cell.allele_type { ('a'..'e').to_a.sample }
  es_cell.association :gene, :factory => :randomly_populated_gene
end

Factory.define :randomly_populated_mi_attempt, :parent => :mi_attempt2 do |mi_attempt|
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
  distribution_centre.association :mi_attempt, :factory => :mi_attempt2_status_gtc
end

Factory.define :phenotype_attempt_distribution_centre, :class => PhenotypeAttempt::DistributionCentre do |distribution_centre|
  distribution_centre.association :centre
  distribution_centre.association :deposited_material
  distribution_centre.association :phenotype_attempt, :factory => :phenotype_attempt_status_cec
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
  es_cell.association :gene, :marker_symbol => 'Myo1c'
  es_cell.allele_symbol_superscript 'tm1a(EUCOMM)Wtsi'
  es_cell.pipeline { Pipeline.find_by_name! 'EUCOMM' }
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
  es_cell.association :gene, :marker_symbol => 'Gatc'
  es_cell.allele_symbol_superscript 'tm1a(KOMP)Wtsi'
  es_cell.pipeline { Pipeline.find_by_name! 'KOMP-CSD' }

  es_cell.after_create do |es_cell|
    mi_attempt = Factory.create(:mi_attempt2,
      :es_cell => es_cell,
      :colony_name => 'MBFD',
      :mi_plan => TestDummy.mi_plan('MGP', 'WTSI', :gene => es_cell.gene)
    )
    es_cell.reload
  end
end

Factory.define :report_cache do |report_cache|
  report_cache.sequence(:name) { |n| "Report Cache #{n}"}
  report_cache.data ''
  report_cache.format 'csv'
end

Factory.define :solr_update_queue_item, :class => SolrUpdate::Queue::Item do |item|
  item.action 'update'
end


Factory.define :solr_update_queue_item_mi_attempt, :parent => :solr_update_queue_item do |item|
  item.sequence(:mi_attempt_id)
end

Factory.define :solr_update_queue_item_phenotype_attempt, :parent => :solr_update_queue_item do |item|
  item.sequence(:phenotype_attempt_id)
end

Factory.define :production_goal do |production_goal|
  production_goal.consortium { Consortium.first }
  production_goal.year 2012
  production_goal.month 1
  production_goal.mi_goal 123
  production_goal.gc_goal 123
end

Factory.define :email_template_without_status, :class => EmailTemplate do |email_template|
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

      For further information / enquiries please write to  info@mousephenotype.org

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

      For further information / enquiries please write to  info@mousephenotype.org

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