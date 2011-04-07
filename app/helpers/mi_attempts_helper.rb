# encoding: utf-8

module MiAttemptsHelper

  class MiAttemptsGrid < Netzke::Basepack::GridPanel

    EMMA_OPTIONS = MiAttempt::EMMA_OPTIONS

    QA_STORE_OPTIONS = ['pass', 'fail', 'na']

    action :apply do
      {
        :text => 'Save Changes',
        :icon => :tick,
        :tooltip => 'You must select this to save the changes you have made'
      }
    end

    js_method :emptyCellsDirtyFlaggingWorkaround, <<-JS
      function(e) {
        // inspired by http://www.sencha.com/learn/Ext_FAQ_Grid#Dirty_Record_.2F_Red_Flag_.28modifying.2C_etc..29
        if( (e.originalValue == null || e.originalValue == "") &&
            (e.value == null || e.value == "") ) {
          e.cancel = true;
          e.record.data[e.field] = e.value;
        }
      }
    JS

    js_method :integersWithWrongTypesDirtyFlaggingWorkaround, <<-JS
      function(e) {
        if(['num_transferred', 'num_recipients', 'total_f1_mice'].indexOf(e.field) == -1) {
          return;
        }

        if(e.originalValue == null) { return; }

        if(parseInt(e.originalValue) == parseInt(e.value)) {
          e.cancel = true;
          e.record.data[e.field] = e.value;
        }
      }
    JS

    js_method :initComponent, <<-JS
      function() {
        #{js_full_class_name}.superclass.initComponent.call(this);

        this.on('validateedit', this.emptyCellsDirtyFlaggingWorkaround);
        this.on('validateedit', this.integersWithWrongTypesDirtyFlaggingWorkaround);
      }
    JS

    js_method :floorNumber, <<-'JS'
      function(number) {
        if(number) {
          return Math.floor(number);
        } else {
          return null;
        }
      }
    JS

    js_method :comboRenderer, <<-'JS'
      function(submit_value, combo_id) {
        var combo = Ext.getCmp(combo_id);
        var record = combo.findRecord(combo.valueField, submit_value);
        return record ? record.get(combo.displayField) : Ext.util.Format.htmlEncode(submit_value);
      }
    JS

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

    def local_combo_editor(selections, overrides = {})
      return {
        :mode => :local,
        :store => selections,
        :editable => false,
        :xtype => :combo,
        :force_selection => true,
        :trigger_action => :all,
      }.merge(overrides)
    end

    def emma_status_column
      return mi_attempt_column(:emma_status).merge(
        :header => 'EMMA Status',
        :sortable => false,
        :editor => local_combo_editor(EMMA_OPTIONS.keys.zip(EMMA_OPTIONS.values), :id => 'emmaStatusCombo'),
        :renderer => ['comboRenderer', 'emmaStatusCombo'],
        :width => 175
      )
    end

    def distribution_centre_name_column
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

    def strain_column(name, values)
      combo_id = name.to_s.camelize(:lower) + 'Combo'

      editor = local_combo_editor(
        values.collect {|i| [i, CGI.escape_html(i)] },
        :id => combo_id,
        :listeners => {
          'select' => 'function(combo, record, index) {combo.el.dom.value = record.data[combo.valueField];}'.to_json_variable,
          'focus' => 'function(combo) {
                        var record = combo.findRecord(combo.valueField, combo.value);
                        if(record) {
                          combo.el.dom.value = record.data[combo.valueField];
                        }
                      }'.to_json_variable
        })

      mi_attempt_column(name, :editor => editor,
        :renderer => ['comboRenderer', combo_id], :width => 130)

    end

    def define_columns
      [
        mi_attempt_column(:clone_name, :sorting_scope => :sort_by_clone_name),

        mi_attempt_column(:gene_symbol, :sorting_scope => :sort_by_gene_symbol,
          :width => 75),

        mi_attempt_column(:allele_name, :sorting_scope => :sort_by_allele_name),

        mi_attempt_column(:actual_mi_date, :header => 'Actual MI Date',
          :width => 84,
          :renderer => ['date', 'd-m-Y'],
          :editor => {
            :xtype => 'datefield',
            :format => 'd-m-Y'
          }
        ),

        mi_attempt_column(:status,
          :getter => proc { |relation| relation.mi_attempt_status.name },
          :read_only => true,
          :sorting_scope => :sort_by_mi_attempt_status),

        mi_attempt_column(:colony_name),

        distribution_centre_name_column,

        strain_column(:blast_strain, BLAST_STRAINS),

        mi_attempt_column(:num_blasts, :header => 'Total Blasts Injected',
          :renderer => ['floorNumber'], :attr_type => :integer,
          :align => :right),

        mi_attempt_column(:num_transferred, :header => 'Total Transferred',
          :renderer => ['floorNumber'], :align => :right),

        mi_attempt_column(:num_recipients, :header => 'No. Surrogates Receiving',
          :renderer => ['floorNumber'], :align => :right),

        mi_attempt_column(:number_born, :header => 'Total Pups Born', :align => :right),

        mi_attempt_column(:number_female_chimeras, :header => 'Total Female Chimeras', :align => :right),

        mi_attempt_column(:number_male_chimeras, :header => 'Total Male Chimeras', :align => :right),

        mi_attempt_column(:total_chimeras, :read_only => true, :align => :right),

        mi_attempt_column(:number_male_100_percent, :header => '100% Male Chimerism Levels', :align => :right),

        mi_attempt_column(:number_male_gt_80_percent, :header => '>=80% Male Chimerism Levels', :align => :right),

        mi_attempt_column(:number_male_40_to_80_percent, :header => '80-40% Male Chimerism Levels', :align => :right),

        mi_attempt_column(:number_male_lt_40_percent, :header => '<40% Male Chimerism Levels', :align => :right),

        emma_status_column,

        strain_column(:test_cross_strain, TEST_CROSS_STRAINS),

        strain_column(:back_cross_strain, BACK_CROSS_STRAINS),

        mi_attempt_column(:date_chimera_mated, :header => 'Date Chimeras Mated',
          :width => 84,
          :renderer => ['date', 'd-m-Y'],
          :editor => {
            :xtype => 'datefield',
            :format => 'd-m-Y'
          }
        ),

        mi_attempt_column(:number_chimera_mated,
          :header => 'No. Chimera Matings Attempted', :align => :right),

        mi_attempt_column(:number_chimera_mating_success,
          :header => 'No. Chimera Matings Successful', :align => :right),

        mi_attempt_column(:chimeras_with_glt_from_cct,
          :header => 'No. Chimeras with Germline Transmission from CCT',
          :align => :right),

        mi_attempt_column(:chimeras_with_glt_from_genotyp,
          :header => 'No. Chimeras with Germline Transmission from Genotyping',
          :align => :right),

        mi_attempt_column(:number_lt_10_percent_glt,
          :header => 'No. Chimeras with < 10% GLT', :align => :right),

        mi_attempt_column(:number_btw_10_50_percent_glt,
          :header => 'No. Chimeras with 10 - 50% GLT', :align => :right),

        mi_attempt_column(:number_gt_50_percent_glt,
          :header => 'No. Chimeras with > 50% GLT', :align => :right),

        mi_attempt_column(:number_100_percent_glt,
          :header => 'No. Chimeras with 100% GLT', :align => :right),

        mi_attempt_column(:total_f1_mice, :header => 'Total F1 Mice from Matings',
          :renderer => ['floorNumber'], :align => :right),

        mi_attempt_column(:number_with_cct,
          :header => 'No. Coat Colour Transmission Offspring',
          :attr_type => :integer, :align => :right),

        mi_attempt_column(:number_het_offspring,
          :header => 'No. Het Offspring', :align => :right),

        mi_attempt_column(:number_live_glt_offspring,
          :header => 'No. Live GLT Offspring', :align => :right),

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
