namespace :imits do
  desc 'Generate email templates from current file implementation (this will remove current email templates!)'
  task :generate_email_templates => :environment do

    ## Remove all current email templates
    EmailTemplate.delete_all

    welcome_body = <<-EOF
      Dear colleague,

      Thank you for registering for gene <%= @gene.marker_symbol %>

      This gene currently <%= @modifier_string %> assigned for mouse production and phenotyping as part of the IMPC initiative.
      <% if @modifier_string == "is not" %>
      This gene will be considered for mouse production by the IMPC.
      <% end %>

      <% if !@relevant_status.empty? %>
      __RELEVANT_STATUS__
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


    update_body = <<-EOF
      Dear colleague,

      You have registered interest in this gene via the IMPC (www.mousephenotype.org).

      You are receiving this email because the IMPC production status of the gene has changed.

      <% if !@relevant_status.empty? %>
      __RELEVANT_STATUS__
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

      You will be notified by email with any future changes in gene status.

      For further information / enquiries please write to  info@mousephenotype.org

      Best Wishes,

      The MPI2 (KOMP2) informatics consortium.
    EOF

    statuses = `ls #{Rails.root}/app/views/notification_mailer/status_email`.split(/\n/)

    created_templates = [0]

    begin
      ## Create non status template
      email_template = EmailTemplate.new

      email_template.welcome_body = welcome_body.gsub(/__RELEVANT_STATUS__\n/, '').gsub(/^      /, '')
      email_template.update_body  = update_body.gsub(/__RELEVANT_STATUS__\n/, '').gsub(/^      /, '')

      email_template.save!

      statuses.each do |status|
        email_template = EmailTemplate.new

        welcome_snippet = File.read "#{Rails.root}/app/views/notification_mailer/welcome_email/#{status}"
        status_snippet = File.read "#{Rails.root}/app/views/notification_mailer/status_email/#{status}"

        email_template.status = status.gsub(/\.text\.erb/, '')
        email_template.status[0] = ''

        next if email_template.status.blank? && email_template.status.blank? && !['aborted_es_cell_qc_failed', 'microinjection_aborted', 'phenotype_attempt_aborted'].include?(email_template.status)

        email_template.welcome_body = welcome_body.gsub(/__RELEVANT_STATUS__\n/, welcome_snippet).gsub(/^      /, '')
        email_template.update_body  = update_body.gsub(/__RELEVANT_STATUS__\n/, status_snippet).gsub(/^      /, '')

        email_template.save!
        created_templates << email_template.id
      end
    rescue => e
      puts e.inspect
      puts "An error has occurred. Rolling back."
      EmailTemplate.where(:id => created_templates).map(&:delete)
    end

  end



  desc 'Generate email welcome template'
task :welcome_email_template => :environment do
  welcome_body = <<-EOF
<% if !Rails.env.production? %>
<%= render :partial => 'notification_mailer/shared/development_environment_warning' %>
<% end %>
Dear colleague,

Thank you for registering for the following genes:
<%= @gene_list %>.

Please see the attached file for further details.

Updates on gene status will be sent to <%= @contact_email %>.

For further information / enquiries please write to info@mousephenotype.org

Best Regards,

The MPI2 (KOMP2) informatics consortium.
    EOF

    email_template = EmailTemplate.find_by_status('welcome_new')

    if email_template
      puts "#### welcome_new email template already exists!"
      email_template.destroy
    end

    email_template = EmailTemplate.new

    update_body = 'unused'
    email_template.status = 'welcome_new'

    email_template.welcome_body = welcome_body
    email_template.update_body  = update_body

    email_template.save!

  end
end

#<% if gene[:relevant_status][:status] && File.exist?("#{Rails.root}/app/views/notification_mailer/welcome_email/_#{gene[:relevant_status][:status]}.text.erb") %>
