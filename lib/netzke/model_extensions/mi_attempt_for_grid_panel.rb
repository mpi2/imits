module Netzke::ModelExtensions
  class MiAttemptForGridPanel < EmiAttempt
    netzke_attribute :clone_name
    netzke_attribute :gene_symbol
    netzke_attribute :allele_name
    netzke_attribute :distribution_centre_name
    netzke_attribute :emma_status
  end
end
