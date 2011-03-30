# encoding: utf-8

module MiAttemptsHelper

  class MiAttemptsGrid < Netzke::Basepack::GridPanel

    EMMA_OPTIONS = {
      :unsuitable => 'Unsuitable for EMMA',
      :suitable => 'Suitable for EMMA',
      :suitable_sticky => 'Suitable for EMMA - STICKY',
      :unsuitable_sticky => 'Unsuitable for EMMA - STICKY',
    }

    REVERSE_EMMA_OPTIONS = EMMA_OPTIONS.invert

    QA_STORE_OPTIONS = ['pass', 'fail', 'na']

    action :apply do
      {
        :text => 'Save Changes',
        :icon => :tick,
        :tooltip => 'You must select this to save the changes you have made'
      }
    end

    def mi_attempt_column(name, extra_params = {})
      name = name.to_s
      return {
        :id => name,
        :name => name,
        :header => name.titleize,
        :read_only => false,
        :editable => true,
        :sortable => true,
      }.merge(extra_params)
    end

    def local_combo_editor(selections)
      return {
        :mode => :local,
        :store => selections,
        :editable => false,
        :xtype => :combo,
        :force_selection => true,
        :trigger_action => :all,
      }
    end

    def emma_status_column_options
      return mi_attempt_column(:emma_status).merge(
        :header => 'EMMA Status',
        :sortable => false,
        :getter => lambda { |relation| EMMA_OPTIONS[relation.emma_status] },
        :setter => lambda { |relation, value| relation.emma_status = REVERSE_EMMA_OPTIONS[value] },
        :width => 175,
        :editor => local_combo_editor(EMMA_OPTIONS.values)
      )
    end

    def distribution_centre_name_column_options
      mi_attempt_column(:distribution_centre_name).merge(
        :header => 'Distribution Centre',
        :setter => lambda { |mi_attempt, centre_name|
          mi_attempt.set_distribution_centre_by_name(centre_name,
            @passed_config[:current_username])
        },
        :sortable => true,
        :sorting_scope => :sort_by_distribution_centre_name,
        :editor => local_combo_editor(Centre.all.collect(&:name))
      )
    end

    js_method :floor_number, <<-'JS'
      function(number) {
        return Math.floor(number);
      }
    JS

    def define_columns
      [
        mi_attempt_column(:clone_name, :sorting_scope => :sort_by_clone_name),

        mi_attempt_column(:gene_symbol, :sorting_scope => :sort_by_gene_symbol),

        mi_attempt_column(:allele_name, :sorting_scope => :sort_by_allele_name),

        mi_attempt_column(:actual_mi_date, :header => 'Actual MI Date'),

        mi_attempt_column(:status,
          :getter => proc { |relation| relation.mi_attempt_status.name },
          :sorting_scope => :sort_by_mi_attempt_status),

        mi_attempt_column(:colony_name),

        distribution_centre_name_column_options,

        mi_attempt_column(:blast_strain, :editor => local_combo_editor(BLAST_STRAINS)),

        mi_attempt_column(:num_blasts, :header => 'Total Blasts Injected'),

        mi_attempt_column(:num_transferred, :header => 'Total Transferred', :renderer => ['floorNumber']),

        # mi_attempt_column(:no_surrogates_received, :header => 'No. Surrogates Receiving'),

        mi_attempt_column(:number_born, :header => 'Total Pups Born'),

        mi_attempt_column(:number_female_chimeras, :header => 'Total Female Chimeras'),

        mi_attempt_column(:number_male_chimeras, :header => 'Total Male Chimeras'),

        mi_attempt_column(:total_chimeras, :read_only => true),

        mi_attempt_column(:number_male_100_percent, :header => '100% Male Chimerism Levels'),

        mi_attempt_column(:number_male_gt_80_percent, :header => '>=80% Male Chimerism Levels'),

        mi_attempt_column(:number_male_40_to_80_percent, :header => '80-40% Male Chimerism Levels'),

        mi_attempt_column(:number_male_lt_40_percent, :header => '<40% Male Chimerism Levels'),

        emma_status_column_options,

        mi_attempt_column(:test_cross_strain, :editor => local_combo_editor(TEST_CROSS_STRAINS)),

        mi_attempt_column(:back_cross_strain, :editor => local_combo_editor(BACK_CROSS_STRAINS)),

        mi_attempt_column(:date_chimeras_mated),

        mi_attempt_column(:number_chimera_mated,
          :header => 'No. Chimera Matings Attempted'),

        mi_attempt_column(:number_chimera_mating_success,
          :header => 'No. Chimera Matings Successful'),

        mi_attempt_column(:chimeras_with_glt_from_cct,
          :header => 'No. Chimeras with Germline Transmission from CCT'),

        mi_attempt_column(:chimeras_with_glt_from_genotyp,
          :header => 'No. Chimeras with Germline Transmission from Genotyping'),

        mi_attempt_column(:number_lt_10_percent_glt,
          :header => 'No. Chimeras with < 10% GLT'),

        mi_attempt_column(:number_btw_10_50_percent_glt,
          :header => 'No. Chimeras with 10 - 50% GLT'),

        mi_attempt_column(:number_gt_50_percent_glt,
          :header => 'No. Chimeras with > 50% GLT'),

        mi_attempt_column(:number_100_percent_glt,
          :header => 'No. Chimeras with 100% GLT'),

        mi_attempt_column(:total_f1_mice,
          :header => 'Total F1 Mice from Matings',
          :attr_type => :integer),

        mi_attempt_column(:number_with_cct,
          :header => 'No. Coat Colour Transmission Offspring',
          :attr_type => :integer),

        mi_attempt_column(:number_het_offspring,
          :header => 'No. Het Offspring'),

        mi_attempt_column(:number_live_glt_offspring,
          :header => 'No. Live GLT Offspring'),

        mi_attempt_column(:mouse_allele_name,
          :header => 'Mouse Allele Name'),

        mi_attempt_column(:qc_southern_blot,
          :header => 'Southern Blot',
          :editor => local_combo_editor(QA_STORE_OPTIONS)),

        mi_attempt_column(:qc_five_prime_lr_pcr,
          :header => 'Five Prime LRPCR',
          :editor => local_combo_editor(QA_STORE_OPTIONS)),

        mi_attempt_column(:qc_five_prime_cass_integrity,
          :header => 'Five Prime Cassette Integrity',
          :editor => local_combo_editor(QA_STORE_OPTIONS)),

        mi_attempt_column(:qc_tv_backbone_assay,
          :header => 'TV Backbone Assay',
          :editor => local_combo_editor(QA_STORE_OPTIONS)),

        mi_attempt_column(:qc_neo_count_qpcr,
          :header => 'Neo Count SRPCR',
          :editor => local_combo_editor(QA_STORE_OPTIONS)),

        mi_attempt_column(:qc_neo_sr_pcr,
          :header => 'Neo SR PCR',
          :editor => local_combo_editor(QA_STORE_OPTIONS)),

        mi_attempt_column(:qc_loa_qpcr,
          :header => 'LOA QPCR',
          :editor => local_combo_editor(QA_STORE_OPTIONS)),

        mi_attempt_column(:qc_homozygous_loa_sr_pcr,
          :header => 'Homozygous LOA SRPCR',
          :editor => local_combo_editor(QA_STORE_OPTIONS)),

        mi_attempt_column(:qc_lacz_sr_pcr,
          :header => 'LacZ SRPCR',
          :editor => local_combo_editor(QA_STORE_OPTIONS)),

        mi_attempt_column(:qc_mutant_specific_sr_pcr,
          :header => 'Mutant Specific SRPCR',
          :editor => local_combo_editor(QA_STORE_OPTIONS)),

        mi_attempt_column(:qc_loxp_confirmation,
          :header => 'LoxP Confirmation',
          :editor => local_combo_editor(QA_STORE_OPTIONS)),

        mi_attempt_column(:qc_three_prime_lr_pcr,
          :header => 'Three Prime LRPCR',
          :editor => local_combo_editor(QA_STORE_OPTIONS))
      ]
    end

    def switch_view_button(text, extra_params = {})
      return {
        :enable_toggle => true,
        :allow_depress => false,
        :toggle_group => 'mi_attempt_view_config',
        :min_width => 100,
        :text => text,
        :view_name => text.gsub(' ', '_').downcase,
        :toggle_handler => 'toggleMiAttemptsSwitchViewButton'.to_json_variable,
      }.merge(extra_params)
    end

    def view_config_buttons
      return {
        :xtype => 'buttongroup',
        :title => 'Choose a View',
        :items => [
          switch_view_button('Everything', :pressed => true),
          switch_view_button('Transfer Details'),
          switch_view_button('Litter Details'),
          switch_view_button('Chimera Mating Details'),
          switch_view_button('QC Details')
        ]
      }
    end

    def selectable_cells_magic_view_config
      new_cell_tpl = <<-'EOL'
      new Ext.Template(
        '<td class="x-grid3-col x-grid3-cell x-grid3-td-{id} {css}" style="{style}" tabIndex="0" {cellAttr}>',
        '<div class="x-grid3-cell-inner x-grid3-col-{id}" unselectable="off" {attr}>{value}</div>',
        '</td>'
      )
      EOL
      return {
        :cell_tpl => new_cell_tpl.to_json_variable
      }
    end

    def configuration
      super.merge(
        :model => 'MiAttempt',

        :border => true,
        :header => false,

        :clicks_to_edit => 1,
        :rows_per_page => 20,
        :stripe_rows => true,

        :tbar => [self.view_config_buttons],

        :bbar => [
          :apply.action
        ],

        # :view_config => selectable_cells_magic_view_config,

        :columns => self.define_columns,

        :prohibit_create => true,
        :prohibit_delete => true,
        :enable_edit_in_form => false,
        :enable_extended_search => false,
        :strong_default_attrs => {:edited_by => @passed_config[:current_username]},
        :scope => [:search, @passed_config[:search_terms]]
      )
    end
  end

  class MiAttemptsWidget < Netzke::Basepack::Panel
    def configuration
      config_up_to_now = super
      search_terms = config_up_to_now.delete(:search_terms)
      current_username = config_up_to_now.delete(:current_username)
      config_up_to_now.merge(
        :name => :micro_injection_attempts_widget,
        :layout => :fit,
        :title => 'Micro-Injection Attempts',
        :items => [
          { :name => :micro_injection_attempts,
            :class_name => 'MiAttemptsHelper::MiAttemptsGrid',
            :ref => 'grid',
            :current_username => current_username,
            :search_terms => search_terms
          }
        ]
      )
    end
  end

  def mi_attempts_table(search_terms)
    onready = javascript_tag(<<-'EOL')
      Ext.onReady(function(){
        var widget = Netzke.page.microInjectionAttemptsWidget;
        Ext.EventManager.onWindowResize(widget.doLayout, widget);
      });
    EOL

    netzke(:micro_injection_attempts_widget,
      :class_name => 'MiAttemptsHelper::MiAttemptsWidget',
      :current_username => current_user.user_name,
      :search_terms => search_terms) + "\n" + onready
  end
end
