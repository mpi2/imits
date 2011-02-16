module EmiAttemptsHelper

  def emi_attempts_table(clone_names)
    netzke(:emi_attempts,
      :class_name => "Basepack::GridPanel", :model => "EmiAttempt",
      :columns => [
        {:name => :clone_name, :header => 'Clone'},
        {:name => :gene_symbol, :header => 'Gene'},
        {:name => :allele_name, :header => 'Allele'},
        {:name => :formatted_proposed_mi_date, :header => 'Proposed MI Date'},
        {:name => :formatted_actual_mi_date, :header => 'Actual MI Date'},
        {:name => :colony_name, :header => 'Colony'},
      ],
      :prohibit_create => true,
      :prohibit_update => true,
      :prohibit_delete => true,
      :enable_edit_in_form => false,
      :enable_extended_search => false,
      :scope => [:by_clone_names, *clone_names ]
    )

  end
end
