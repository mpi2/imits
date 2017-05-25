Ext.namespace('Imits.MiAttempts.Shared');
function replaceTextFieldWithExtField(selector, replacementCreationFunction) {
    Ext.select(selector).each(function (textField) {
        var name = textField.dom.name;
        var defaultValue = textField.dom.value;
        var renderDiv = new Ext.Element(Ext.core.DomHelper.createDom({tag: 'div', 'data-name-of-replaced': name}));
        renderDiv.replace(textField);

        replacementCreationFunction(renderDiv, name, defaultValue);
    });
}

function validateFloatKeyPress(el) {
    var v = parseFloat(el.value);
    el.value = (isNaN(v)) ? '' : v.toFixed(2);
}

function initNumberFields() {
    replaceTextFieldWithExtField('.number-field', function(renderDiv, name, defaultValue) {
        new Ext.form.field.Number({
            cls: 'number-field',
            renderTo: renderDiv,
            name: name,
            value: defaultValue,
            width: 40,
            allowDecimals: false,
            minValue: 0,
            hideTrigger: true,
            keyNavEnabled: false,
            mouseWheelEnabled: false
        });
    });
}

function initfloatFields() {
    replaceTextFieldWithExtField('.float-field', function(renderDiv, name, defaultValue) {
        new Ext.form.field.Number({
            cls: 'float-field',
            renderTo: renderDiv,
            name: name,
            value: defaultValue,
            width: 80,
            allowDecimals: true,
            minValue: 0,
            hideTrigger: true,
            keyNavEnabled: false,
            mouseWheelEnabled: false
        });
    });
}

function initDateFields() {
    replaceTextFieldWithExtField('.date-field', function(renderDiv, name, defaultValue) {
        new Ext.form.field.Date({
            cls: 'date-field',
            renderTo: renderDiv,
            name: name,
            value: defaultValue,
            editable: false,
            format: 'd/m/Y'
        });
    });
}

function displayAndHideFormContents(){
    var esCellName = Ext.get('mi_attempt_es_cell_name').getValue();
    var mutagenesisShow = Ext.get('mutagenesis-show').getValue();
    var MarkerSymbolValue = Ext.get('marker_symbol').getValue();

    var esCellName = Ext.get('mi_attempt_es_cell_name').getValue();
    var mutagenesisShow = Ext.get('mutagenesis-show').getValue();
    var divTop = Ext.get('object-new-top');
    var restOfFormDiv = Ext.get('rest-of-form');

    if(esCellName == '' && mutagenesisShow != 'true') {
        divTop.setVisible(true, true);
        divTop.hidden = false;

        restOfFormDiv.setVisible(false, 'display');
        restOfFormDiv.hidden = true;
    } else {
        divTop.setVisible(false, 'display');
        divTop.hidden = true;
    }

    if(esCellName != ''){
       $('.object-es-cell').show();
       if (MarkerSymbolValue){
          listView.set_mi_plan_selection(MarkerSymbolValue);
      }
    } else {
        $('.object-es-cell').hide();
    }

    if(mutagenesisShow != 'true') {
        $('.object-crispr').hide();
    } else {
        $('.object-crispr').show();

        if (MarkerSymbolValue){
           var crispr = 'true';
           listView.set_mi_plan_selection(MarkerSymbolValue, crispr);
       }
    }

}

function changePlanButton(){
    Ext.create('Ext.Button', {
        minHeight: 20,
        text: 'Change Mi Plan',
        renderTo: 'change_plan',
        handler: function() {

                var planChanger= Ext.get('change_plan');
                planChanger.setVisible(false, 'display');
                planChanger.hidden = true;

                var planChanger= Ext.get('mi_plan_preious_selection');
                planChanger.setVisible(false, 'display');
                planChanger.hidden = true;

                var planSelector= Ext.get('mi_plan_selection_div');
                planSelector.setVisible(true, true);
                planSelector.hidden = false;

                var mi_plan_id = Ext.get('mi_attempt_mi_plan_id').getValue();
                var recordIndex = listView.store.find('id', mi_plan_id);
                if (recordIndex != -1) {
                    listView.getSelectionModel().select(recordIndex);
                }
            }
        });
}

function miPlanSelectionList(){

    listView = Ext.create('Imits.MiAttempts.Shared.ListView')
}

Ext.define('Imits.MiAttempts.Shared.ListView', {

    set_mi_plan_selection: function(MarkerSymbol, crispr){
        crispr = crispr || false;
        if (MarkerSymbol){
            this.store.load({params: {marker_symbol: MarkerSymbol, crispr: crispr}});
        };
    },
    store: Ext.create('Ext.data.JsonStore', {
               model: 'MiPlanListViewModel',
               storeId: 'store',
               proxy: {
                    type: 'ajax',
                    url: window.basePath + '/mi_plans/search_for_available_mi_attempt_plans.json'
               },
    }),
    extend: 'Ext.grid.Panel',
    width:1000,
    height:250,
    title:'Select a Plan',
    renderTo: 'mi_plan_list',
    multiSelect: false,
    viewConfig: {
        emptyText: 'No images to display'
    },

    columns: [{
        text: 'Consortium',
        flex: 50,
        dataIndex: 'consortium_name',
        height: 20
    },{
        text: 'Production Centre',
        flex: 50,
        dataIndex: 'production_centre_name',
        height: 20
    },{
        text: 'Sub Project',
        flex: 40,
        dataIndex: 'sub_project_name',
        height: 20
    },{
        text: 'Knockout First Tm1a',
        flex: 60,
        dataIndex: 'is_conditional_allele',
        height: 20
    },{
        text: 'Conditional tm1c',
        flex: 50,
        dataIndex: 'conditional_tm1c',
        height: 20
    },{
        text: 'Deletion',
        flex: 30,
        dataIndex: 'is_deletion_allele',
        height: 20
    },{
        text: 'Cre Knock In',
        flex: 40,
        dataIndex: 'is_cre_knock_in_allele',
        height: 20
    },{
        text: 'Cre Bac',
        flex: 30,
        dataIndex: 'is_cre_bac_allele',
        height: 20
    },{
        text: 'Point Mutation',
        flex: 40,
        dataIndex: 'point_mutation',
        height: 20
    },{
        text: 'Conditional Point Mutation',
        flex: 70,
        dataIndex: 'conditional_point_mutation',
        height: 20
    },{
        text: 'Active',
        flex: 40,
        dataIndex: 'is_active',
        height: 20
    }],

    listeners : {
        afterrender : function(panel) {
            var header = panel.header;
            header.setHeight(40);
        }
    },

    initComponent: function() {
        this.callParent();
        this.addListener('selectionchange', function(view, nodes) {
            if (nodes.length > 0){
              Ext.get("mi_attempt_mi_plan_id").set({ value: nodes[0].get('id') });
            }
        });
    }
});

Ext.onReady(function() {
    miPlanSelectionList();
    initNumberFields();
    initfloatFields();
    initDateFields();
    displayAndHideFormContents();
    changePlanButton();


    Ext.select('#mi_attempt_mutagenesis_factor_attributes_individually_set_grna_concentrations').on("change", function(e) {
      div = Ext.select('.grna_concentration_col');
      div2 = Ext.select('#grna_concentrations');

      if(this.checked) {
        div.show();
        div2.hide();

      } else {
        div.hide();
        div2.show();
      }
   });


});

$(function() {
  $('.qcimage').each(function(idx, elm){
    var colonyIndex = $(elm).attr('data-colonyindex');
    var alleleIndex = $(elm).attr('data-alleleindex');
    CreateQcDiagram(colonyIndex, alleleIndex); 
  })

})

function CreateQcDiagram(colonyIndex, alleleIndex) {

    var attribute_prefix = 'mi_attempt[colonies_attributes][' + colonyIndex + '][alleles_attributes][' + alleleIndex + '][production_centre_qc_attributes]' ;
    var attribute_id_prefix = 'mi_attempt_colonies_attributes_' + colonyIndex + '_alleles_attributes_' + alleleIndex + '_production_centre_qc_attributes_' ;
    var holder_mutant = 'holder_mutant_colony_' + colonyIndex + '_allele_' + alleleIndex ;
    var holder_wildtype = 'holder_wildtype_colony_' + colonyIndex + '_allele_' + alleleIndex ;

//    console.log(holder_mutant);

    builder = new DiagramBuilder({
        frame_id: holder_mutant,
        width: 850,
        height: 375,
        shape_y: 120
    });

    // Start chain from a string
    var line = builder.drawLine(10);

    // Vertical line
    var attrs = builder._getElementAttributes(1);
    var vertical_line = builder._addBox(attrs);

    // Box 1
    var attrs = builder._getElementAttributes(20);
    attrs.text = '1';
    attrs['background-color'] = "yellow";
    var box1 = builder._addBox(attrs);

    // Frt Site
    var frt = builder.FrtSite();

    // SA box
    var attrs = builder._getElementAttributes(40, 5);
    attrs.text = 'SA'
    sa = builder._addBox(attrs);

    builder.addLabel({
      first : sa,
      second : line,
      text : 'Five Prime LR PCR',
      position : "end to start",
      name : attribute_prefix + '[five_prime_lr_pcr]',
      id : attribute_id_prefix + 'five_prime_lr_pcr',
      positionY : 20
    });

    builder.addLabel({
      first : box1,
      second : sa,
      text : 'Mutant Specific SR PCR',
      position : "start to end above",
      name : attribute_prefix + '[mutant_specific_sr_pcr]',
      id : attribute_id_prefix + 'mutant_specific_sr_pcr'
    });

    // LacZ
    var attrs = builder._getElementAttributes(80, 5);
    attrs.text = 'LacZ';
    attrs.color = '#fff';
    attrs['background-color'] = "rgba(74,115,162, 1.0)";
    var lacz = builder._addBox(attrs);

    builder.addLabel({
      first : lacz,
      second : lacz,
      text : 'LacZ SR PCR',
      position : "start to end",
      name : attribute_prefix + '[lacz_sr_pcr]',
      id : attribute_id_prefix + 'lacz_sr_pcr',
      positionY : 20
    });

    builder.addLabel({
      first : lacz,
      second : lacz,
      text : 'LacZ count QPCR',
      arrowHeads : 'oval-wide-long',
      fill : 'rgba(166, 74, 70, 1)',
      position : "start to end",
      name : attribute_prefix + '[lacz_count_qpcr]',
      id : attribute_id_prefix + 'lacz_count_qpcr',
      positionY : -50,
    });

    // NEO
    var attrs = builder._getElementAttributes(80, 5);
    attrs.text = 'NEO';
    attrs.color = '#fff';
    attrs['background-color'] = "rgba(46,107,123, 1.0)";
    var neo = builder._addBox(attrs);

    builder.addLabel({
      first : neo,
      second : neo,
      text : 'Neo Count QPCR',
      position : "start to end above",
      name : attribute_prefix + '[neo_count_qpcr]',
      id : attribute_id_prefix + 'neo_count_qpcr',
      arrowHeads : 'oval-wide-long',
      fill : 'rgba(166, 74, 70, 1)'
    });

    builder.addLabel({
      first : neo,
      second : neo,
      text : 'Neo SR PCR',
      position : "start to end",
      name : attribute_prefix + '[neo_sr_pcr]',
      id : attribute_id_prefix + 'neo_sr_pcr',
      positionY : 20
    });


    // Frt Site end
    var frt_end = builder.FrtSite();

    // Loxp Site
    var loxp = builder.LoxpSite();

    // Box 2
    var attrs = builder._getElementAttributes(20);
    attrs.text = '2';
    attrs['background-color'] = "yellow";
    var box2 = builder._addBox(attrs);

    // Loxp Site
    var loxp_end = builder.LoxpSite();

    // Box 3
    var attrs = builder._getElementAttributes(20);
    attrs.text = '3';
    attrs['background-color'] = "yellow";
    var box3 = builder._addBox(attrs);

    // Vertical line
    var attrs = builder._getElementAttributes(1);
    var vertical_line2 = builder._addBox(attrs);

    var line2 = builder.drawLine(10);

    builder.addLabel({
      first : loxp,
      second : loxp_end,
      text : 'LoxP Confirmation',
      position : "start to end above",
      name : attribute_prefix + '[loxp_confirmation]',
      id : attribute_id_prefix + 'loxp_confirmation'
    });

    builder.addLabel({
      first : loxp,
      second : line2,
      text : 'Three Prime LR PCR',
      position : "start to end",
      name : attribute_prefix + '[three_prime_lr_pcr]',
      id : attribute_id_prefix + 'three_prime_lr_pcr',
      positionY : 20
    });

    builder.addLabel({
      first : loxp,
      second : loxp_end,
      text : 'Critical region QPCR',
      position : "end to start",
      name : attribute_prefix + '[critical_region_qpcr]',
      id : attribute_id_prefix + 'critical_region_qpcr',
      arrowHeads : 'oval-wide-long',
      fill : 'rgba(166, 74, 70, 1)',
      positionY : -50
    });

    builder.addTextBox({
      name: attribute_prefix + '[tv_backbone_assay]',
      id : attribute_id_prefix + 'tv_backbone_assay',
      title: 'TV Backbone Assay',
      value: '',
      positionY : 20
    })

    builder.addTextBox({
      name: attribute_prefix + '[southern_blot]',
      id : attribute_id_prefix + 'southern_blot',
      title: 'Southern Blot',
      value: '',
      labelPosition: 'above'
    })

    builder.addTextBox({
      name: attribute_prefix + '[five_prime_cassette_integrity]',
      id : attribute_id_prefix + 'five_prime_cassette_integrity',
      title: 'Five Prime Cassette Integrity',
      value: ''
    })

    builder.addTextBox({
      name: attribute_prefix + '[loxp_srpcr]',
      id : attribute_id_prefix + 'loxp_srpcr',
      title: 'LOXP SRPCR',
      value: '',
      offsetY: -305,
      offsetX: 225
    })

    builder.addTextBox({
      name: attribute_prefix + '[loxp_srpcr_and_sequencing]',
      id : attribute_id_prefix + 'loxp_srpcr_and_sequencing',
      title: 'LOXP SRPCR and sequencing',
      value: '',
      offsetY: -305,
      offsetX: 194
    })

    //
    //  Wildtype diagram
    //

    builder = new DiagramBuilder({
        frame_id : holder_wildtype,
        width : 850,
        height : 230,
        shape_y: 80
    });

    // Start chain from a string
    var line = builder.drawLine(10);

    // Vertical line
    var attrs = builder._getElementAttributes(1);
    var vertical_line = builder._addBox(attrs);

    // Box 1
    var attrs = builder._getElementAttributes(20);
    attrs.text = '1';
    attrs['background-color'] = "yellow";
    var box1 = builder._addBox(attrs);

    // Start chain from a string
    var line2 = builder.drawLine(445);


    // Box 2
    var attrs = builder._getElementAttributes(20);
    attrs.text = '2';
    attrs['background-color'] = "yellow";
    var box2 = builder._addBox(attrs);

    // Start chain from a string
    var line3 = builder.drawLine(50);

    // Box 3
    var attrs = builder._getElementAttributes(20);
    attrs.text = '3';
    attrs['background-color'] = "yellow";
    var box3 = builder._addBox(attrs);
    
    // Vertical line
    var attrs = builder._getElementAttributes(1);
    var vertical_line2 = builder._addBox(attrs);

    var line4 = builder.drawLine(10);

    builder.addLabel({
      first : box1,
      second : box2,
      text : 'LOA QPCR',
      position : "end to start above",
      name : attribute_prefix + '[loa_qpcr]',
      id : attribute_id_prefix + 'loa_qpcr',
      arrowHeads : 'oval-wide-long',
      line_height : 30,
      fill : 'rgba(166, 74, 70, 1)'
    });

    builder.addLabel({
      first : box1,
      second : box2,
      text : 'Homozygous LOA SR PCR',
      position : "end to start",
      name : attribute_prefix + '[homozygous_loa_sr_pcr]',
      id : attribute_id_prefix + 'homozygous_loa_sr_pcr',
      line_height : 30
    });


    // Keep the value of the two fields in sync
    $('.diagram select').live('change', function() {
        var $select = $(this);
        var value   = $select.val();
        var id      = $select.attr('id');

        matched_indexes = id.match(/(\d+)/g, '');
        matched_id = id.replace(/(mi_attempt_colonies_attributes_\d+_alleles_attributes_\d+_production_centre_qc_attributes_)/g, '');

        var $mi_select = $('#qc_data_colony_' + matched_indexes[0] +'_allele_' + matched_indexes[1] + '_' + matched_id);

        $mi_select.attr('data_value', value);
    })

    // Fill the fields on page load
    $('.qc-details div.qc_data').each(function() {
        var $div = $(this);
        var value   = $div.attr('data_value');
        var id      = $div.attr('id');

        matched_indexes = id.match(/(\d+)/g, '');
        matched_id = id.replace(/(qc_data_colony_\d+_allele_\d+_)/g, '');

        var $qc_select = $('#mi_attempt_colonies_attributes_' + matched_indexes[0] +'_alleles_attributes_' + matched_indexes[1] + '_production_centre_qc_attributes_' + matched_id);
        $qc_select.val(value);
    })

}