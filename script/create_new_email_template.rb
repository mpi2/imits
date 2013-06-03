@welcome_body = <<-EOF
<% if !Rails.env.production? %>
<%= render :partial => 'notification_mailer/shared/development_environment_warning' %>
<% end %>
Dear colleague,

Thank you for registering for the following genes:
<%= @gene_list %>.

--------------------------------------------------------------------------------

<% @genes.each do |gene| %>

You have registered for gene <%= gene[:marker_symbol] %>.

This gene currently <%= gene[:modifier_string] %> assigned for mouse production and phenotyping as part of the IMPC initiative.
<% if gene[:modifier_string] == "is not" %>
This gene will be considered for mouse production by the IMPC.
<% end %>

<% if gene[:relevant_status][:status] %>
<% @relevant_status = gene[:relevant_status] %>
<%= render :partial => "notification_mailer/welcome_email/" + gene[:relevant_status][:status].to_s %>
<% end %>

<% if gene[:total_cell_count] > 0 %>
Currently the IKMC has the following mutant ES Cells for this gene;
<% if gene[:conditional_es_cells_count] && gene[:conditional_es_cells_count] > 0 %>
<%= gene[:conditional_es_cells_count] %> conditional ES cells
<% end %>
<% if gene[:non_conditional_es_cells_count] && gene[:non_conditional_es_cells_count] > 0 %>
<%= gene[:non_conditional_es_cells_count] %> non-conditional ES cells
<% end %>
<% if gene[:deletion_es_cells_count] && gene[:deletion_es_cells_count] > 0 %>
<%= gene[:deletion_es_cells_count] %> deletions
<% end %>
<% else %>
The IKMC has not produced any targeted mutant ES Cells for this gene.

This gene will be considered by the EUCOMMTools program for production of targeted mutant ES Cells.
<% end %>

<% if gene[:modifier_string] == "is" %>
Details of mutant ES Cells, Mouse Production and Phenotyping for this gene can be found at the IMPC site:
http://www.mousephenotype.org/gene-details?gene_id=<%= gene[:mgi_accession_id] %>

<% elsif gene[:total_cell_count] > 0 %>
Details of targeted mutant ES Cells for this gene can be found here:
www.knockoutmouse.org/search_results?criteria=<%= gene[:mgi_accession_id] %>
<% end %>

--------------------------------------------------------------------------------

<% end %>

Updates on gene status will be sent to <%= @contact_email %>.

For further information / enquiries please write to info@mousephenotype.org

Best Regards,

The MPI2 (KOMP2) informatics consortium.

EOF

begin
  email_template = EmailTemplate.find_by_status('welcome_new')

  email_template.destroy if email_template

  email_template = EmailTemplate.new

  email_template.status = 'welcome_new'

  email_template.welcome_body = @welcome_body
  email_template.update_body  = 'unused'

  #raise "Rollback!"

  email_template.save!
rescue => e
  puts e.inspect
  puts "An error has occurred. Rolling back."
  #EmailTemplate.where(:id => created_templates).map(&:delete)
end
