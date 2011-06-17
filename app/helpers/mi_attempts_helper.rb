# encoding: utf-8

module MiAttemptsHelper

  class MiAttemptsGrid < Netzke::Basepack::GridPanel
    include Rails.application.routes.url_helpers

    EMMA_OPTIONS = MiAttempt::EMMA_OPTIONS

    action :apply do
      {
        :text => 'Save Changes',
        :icon => :tick,
        :tooltip => 'You must select this to save the changes you have made'
      }
    end

    def default_context_menu
      return nil
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

    js_method :ensureDate, <<-JS
      function(date) {
        if(typeof(date) == "object" && date.constructor == Date) {
          return date;
        }

        if(typeof(date) == "string") {
          return new Date(Date.parse(date));
        }

        throw "Unsupported date type detected";
      }
    JS

    js_method :dateFieldDirtyFlaggingWorkaround, <<-JS
      function(e) {
        if(['mi_date', 'date_chimeras_mated'].indexOf(e.field) == -1) {
          return;
        }

        var dateValue = this.ensureDate(e.value);
        var dateOriginalValue = this.ensureDate(e.originalValue);

        if(dateOriginalValue.toDateString() == dateValue.toDateString()) {
          e.cancel = true;
          e.record.data[e.field] = dateValue;
        }
      }
    JS

    js_method :initComponent, <<-JS
      function() {
        #{js_full_class_name}.superclass.initComponent.call(this);

        this.on('validateedit', this.emptyCellsDirtyFlaggingWorkaround);
        this.on('validateedit', this.dateFieldDirtyFlaggingWorkaround);
      }
    JS

    js_method :comboRenderer, <<-'JS'
      function(submitValue, comboId) {
        var combo = Ext.getCmp(comboId);
        var record = combo.findRecord(combo.valueField, submitValue);
        return record ? record.get(combo.displayField) : Ext.util.Format.htmlEncode(submitValue);
      }
    JS

    js_method :mouseAlleleTypeComboEditMonitor, <<-'JS'
      function(event) {
        if(event.field != 'mouse_allele_type') {return;}

        if(event.record.data.allele_type == null) { event.cancel = true; }
      }
    JS

    def mi_attempt_column(name, extra_params = {})
      name = name.to_s
      return {
        :id => name,
        :name => name,
        :header => name.titleize,
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

    def strain_column(name)
      name = name.to_s
      combo_id = name.to_s.camelize(:lower) + 'Combo'
      strain_class = Strain.const_get(name.gsub(/_id$/, '').camelize)

      editor = local_combo_editor(
        strain_class.all.map {|strain| [strain.id, CGI.escape_html(strain.name)] },
        :id => combo_id,
        :listeners => {
          'select' => 'function(combo, record, index) {combo.el.dom.value = Ext.util.Format.htmlDecode(record.get(combo.displayField));}'.to_json_variable,
          'focus' => 'function(combo) {
                        var record = combo.findRecord(combo.valueField, combo.value);
                        if(record) {
                          combo.el.dom.value = Ext.util.Format.htmlDecode(record.get(combo.displayField));
                        }
                      }'.to_json_variable
        }
      )

      mi_attempt_column(name, :editor => editor,
        :renderer => ['comboRenderer', combo_id], :width => 130)
    end

    def mouse_allele_name_columns
      mouse_allele_type_combo = local_combo_editor(MiAttempt::MOUSE_ALLELE_OPTIONS,
        :id => 'mouseAlleleTypeCombo', :minListWidth => 350)

      return [
        mi_attempt_column(:mouse_allele_type,
          :renderer => ['comboRenderer', 'mouseAlleleTypeCombo'],
          :editor => mouse_allele_type_combo),

        mi_attempt_column(:allele_type, :header => 'Allele Type', :readOnly => true,
          :hidden => true, :getter => proc {|mi| mi.clone.allele_type}),

        mi_attempt_column(:mouse_allele_name, :readOnly => true)
      ]
    end

    def define_qc_columns
      columns = MiAttempt::QC_FIELDS.map do |qc_field|
        mi_attempt_column("#{qc_field}__description", :header => qc_field.to_s.titleize.gsub(/^Qc /, ''))
      end

      columns <<
              mi_attempt_column(:should_export_to_mart) <<
              mi_attempt_column(:is_active) <<
              mi_attempt_column(:is_released_from_genotyping)
    end

    def define_columns
      [
        mi_attempt_column(:edit_link,
          :header => 'Edit in form',
          :readOnly => true,
          :getter => proc {|mi| mi_attempt_path(mi) },
          :renderer => 'function(link) {return "<a href=\\""+link+"\\">Edit in Form</a>"}'
        ),

        mi_attempt_column(:clone__clone_name, :header => 'Clone Name',
          :readOnly => true),
        mi_attempt_column(:clone__marker_symbol, :header => 'Marker Symbol',
          :width => 75, :readOnly => true),

        mi_attempt_column(:clone__allele_name, :readOnly => true, :header => 'Allele Name'),

        mi_attempt_column(:mi_date, :header => 'MI Date',
          :width => 84,
          :renderer => ['date', 'd-m-Y'],
          :editor => {
            :xtype => 'datefield',
            :format => 'd-m-Y'
          }
        ),

        mi_attempt_column(:mi_attempt_status__description, :header => 'Status', :readOnly => true, :width => 150),

        mi_attempt_column(:colony_name),

        mi_attempt_column(:production_centre__name, :header => 'Production Centre', :readOnly => true),

        mi_attempt_column(:distribution_centre__name, :header => 'Distribution Centre'),

        strain_column(:blast_strain_id),

        mi_attempt_column(:total_blasts_injected, :align => :right),

        mi_attempt_column(:total_transferred, :align => :right),

        mi_attempt_column(:number_surrogates_receiving, :align => :right),

        mi_attempt_column(:total_pups_born, :align => :right),

        mi_attempt_column(:total_female_chimeras, :align => :right),

        mi_attempt_column(:total_male_chimeras, :align => :right),

        mi_attempt_column(:total_chimeras, :readOnly => true, :align => :right),

        mi_attempt_column(:number_of_males_with_100_percent_chimerism, :header => '100% Male Chimerism Levels', :align => :right),

        mi_attempt_column(:number_of_males_with_80_to_99_percent_chimerism, :header => '99-80% Male Chimerism Levels', :align => :right),

        mi_attempt_column(:number_of_males_with_40_to_79_percent_chimerism, :header => '79-40% Male Chimerism Levels', :align => :right),

        mi_attempt_column(:number_of_males_with_0_to_39_percent_chimerism, :header => '39-0% Male Chimerism Levels', :align => :right),

        emma_status_column,

        strain_column(:test_cross_strain_id),

        strain_column(:colony_background_strain_id),

        mi_attempt_column(:date_chimeras_mated, :header => 'Date Chimeras Mated',
          :width => 84,
          :renderer => ['date', 'd-m-Y'],
          :editor => {
            :xtype => 'datefield',
            :format => 'd-m-Y'
          }
        ),

        mi_attempt_column(:number_of_chimera_matings_attempted,
          :header => 'No. Chimera Matings Attempted', :align => :right),

        mi_attempt_column(:number_of_chimera_matings_successful,
          :header => 'No. Chimera Matings Successful', :align => :right),

        mi_attempt_column(:number_of_chimeras_with_glt_from_cct,
          :header => 'No. Chimeras with Germline Transmission from CCT',
          :align => :right),

        mi_attempt_column(:number_of_chimeras_with_glt_from_genotyping,
          :header => 'No. Chimeras with Germline Transmission from Genotyping',
          :align => :right),

        mi_attempt_column(:number_of_chimeras_with_0_to_9_percent_glt,
          :header => 'No. Chimeras with 0-10% GLT', :align => :right),

        mi_attempt_column(:number_of_chimeras_with_10_to_49_percent_glt,
          :header => 'No. Chimeras with 10-49% GLT', :align => :right),

        mi_attempt_column(:number_of_chimeras_with_50_to_99_percent_glt,
          :header => 'No. Chimeras with 50-99% GLT', :align => :right),

        mi_attempt_column(:number_of_chimeras_with_100_percent_glt,
          :header => 'No. Chimeras with 100% GLT', :align => :right),

        mi_attempt_column(:total_f1_mice_from_matings,
          :header => 'Total F1 Mice from Matings', :align => :right),

        mi_attempt_column(:number_of_cct_offspring,
          :header => 'No. Coat Colour Transmission Offspring',
          :attr_type => :integer, :align => :right),

        mi_attempt_column(:number_of_het_offspring,
          :header => 'No. Het Offspring', :align => :right),

        mi_attempt_column(:number_of_live_glt_offspring,
          :header => 'No. Live GLT Offspring', :align => :right)

      ] + mouse_allele_name_columns + define_qc_columns
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

        :title => 'Micro-Injection Attempts',

        :clicks_to_edit => 1,
        :rows_per_page => 20,
        :stripe_rows => true,

        :tbar => [self.view_config_buttons],

        :bbar => [
          :apply.action
        ],

        :columns => self.define_columns,

        :listeners => {
          'beforeedit' => 'function(event) {
                        this.mouseAlleleTypeComboEditMonitor(event);
                      }'.to_json_variable
        },

        :prohibit_create => true,
        :prohibit_delete => true,
        :enable_edit_in_form => false,
        :enable_extended_search => false,
        :strong_default_attrs => {:updated_by_id => @passed_config[:current_user_id]},
        :scope => [:search, @passed_config[:search_params]]
      )
    end
  end

  class MiAttemptsWidget < Netzke::Basepack::Panel
    def configuration
      config_up_to_now = super
      search_params = config_up_to_now.delete(:search_params)
      current_user_id = config_up_to_now.delete(:current_user_id)
      config_up_to_now.merge(
        :name => :micro_injection_attempts_widget,
        :title => 'Micro-injection Attempts',
        :layout => :fit,
        :autoHeight => true,
        :items => [
          { :name => :micro_injection_attempts,
            :class_name => 'MiAttemptsHelper::MiAttemptsGrid',
            :ref => 'grid',
            :current_user_id => current_user_id,
            :search_params => search_params
          }
        ]
      )
    end

    js_method :manageResize, <<-JS
      function() {
        var windowHeight = window.innerHeight - 30;
        if(!windowHeight) { // fricking IE
          windowHeight = document.documentElement.clientHeight - 30;
        }
        var newGridHeight = windowHeight - this.grid.getEl().getTop();
        if(newGridHeight < 200) {
          newGridHeight = 200;
        }
        this.grid.setHeight(newGridHeight);
        this.doLayout();
      }
    JS
  end

  def mi_attempts_table(search_params)
    onready = javascript_tag(<<-'EOL')
      Ext.onReady(function(){
        var widget = Netzke.page.microInjectionAttemptsWidget;
        Ext.EventManager.onWindowResize(widget.manageResize, widget);
        widget.manageResize();
      });
    EOL

    netzke(:micro_injection_attempts_widget,
      :class_name => 'MiAttemptsHelper::MiAttemptsWidget',
      :current_user_id => current_user.id,
      :search_params => search_params) + "\n" + onready
  end
end
