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
    miPlanSelectionList()
    initNumberFields();
    initDateFields();
    displayAndHideFormContents();
    changePlanButton();
});

$(function() {

    builder = new DiagramBuilder({
        frame_id: "holder_mutant",
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
      name : 'qc_five_prime_lr_pcr',
      positionY : 20
    });

    builder.addLabel({
      first : box1,
      second : sa,
      text : 'Mutant Specific SR PCR',
      position : "start to end above",
      name : 'qc_mutant_specific_sr_pcr'
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
      name : 'qc_lacz_sr_pcr',
      positionY : 20
    });

    builder.addLabel({
      first : lacz,
      second : lacz,
      text : 'LacZ count QPCR',
      arrowHeads : 'oval-wide-long',
      fill : 'rgba(166, 74, 70, 1)',
      position : "start to end",
      name : 'qc_lacz_count_qpcr',
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
      name : 'qc_neo_count_qpcr',
      arrowHeads : 'oval-wide-long',
      fill : 'rgba(166, 74, 70, 1)'
    });

    builder.addLabel({
      first : neo,
      second : neo,
      text : 'Neo SR PCR',
      position : "start to end",
      name : 'qc_neo_sr_pcr',
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
      name : 'qc_loxp_confirmation'
    });

    builder.addLabel({
      first : loxp,
      second : line2,
      text : 'Three Prime LR PCR',
      position : "start to end",
      name : 'qc_three_prime_lr_pcr',
      positionY : 20
    });

    builder.addLabel({
      first : loxp,
      second : loxp_end,
      text : 'Critical region QPCR',
      position : "end to start",
      name : 'qc_critical_region_qpcr',
      arrowHeads : 'oval-wide-long',
      fill : 'rgba(166, 74, 70, 1)',
      positionY : -50
    });

    builder.addTextBox({
      name: 'qc_tv_backbone_assay',
      title: 'TV Backbone Assay',
      value: '',
      positionY : 20
    })

    builder.addTextBox({
      name: 'qc_southern_blot',
      title: 'Southern Blot',
      value: '',
      labelPosition: 'above'
    })

    builder.addTextBox({
      name: 'qc_five_prime_cassette_integrity',
      title: 'Five Prime Cassette Integrity',
      value: ''
    })

    builder.addTextBox({
      name: 'qc_loxp_srpcr',
      title: 'LOXP SRPCR',
      value: '',
      offsetY: -305,
      offsetX: 225
    })

    builder.addTextBox({
      name: 'qc_loxp_srpcr_and_sequencing',
      title: 'LOCP SRPCR and sequencing',
      value: '',
      offsetY: -305,
      offsetX: 194
    })

    //
    //  Wildtype diagram
    //

    builder = new DiagramBuilder({
        frame_id : "holder_wildtype",
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
      name : 'qc_loa_qpcr',
      arrowHeads : 'oval-wide-long',
      line_height : 30,
      fill : 'rgba(166, 74, 70, 1)'
    });

    builder.addLabel({
      first : box1,
      second : box2,
      text : 'Homozygous LOA SR PCR',
      position : "end to start",
      name : 'qc_homozygous_loa_sr_pcr',
      line_height : 30
    });


    // Keep the value of the two fields in sync
    $('.diagram select').live('change', function() {
        var $select = $(this);
        var value   = $select.val();
        var id      = $select.attr('id');

        var $mi_select = $('#mi_attempt_'+id+'_result');
        $mi_select.val(value);
    })

    $('.qc-details select').live('change', function() {
        var $select = $(this);
        var value   = $select.val();
        var id      = $select.attr('id');

        matched_id = id.replace(/(mi_attempt_)|(_result)/g, '')

        var $qc_select = $('#'+matched_id)
        $qc_select.val(value)
    })

    // Fill the fields on page load
    $('.qc-details select').each(function() {
        var $select = $(this);
        var value   = $select.val();
        var id      = $select.attr('id');

        matched_id = id.replace(/(mi_attempt_)|(_result)/g, '')
        var $qc_select = $('#'+matched_id)
        $qc_select.val(value);
    })

})