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

Ext.onReady(initNumberFields);
Ext.onReady(initDateFields);

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
      name : 'qc_five_prime_lr_pcr'
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
      name : 'qc_lacz_sr_pcr'
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
      name : 'qc_neo_sr_pcr'
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
      name : 'qc_three_prime_lr_pcr'
    });

    builder.addTextBox('qc_tv_backbone_assay', 'TV Backbone Assay', '')
    builder.addTextBox('qc_southern_blot', 'Southern Blot', '')
    builder.addTextBox('qc_five_prime_cassette_integrity', 'Five Prime Cassette Integrity', '')
    builder.addTextBox('qc_critical_region_qpcr', 'Critical region QPCR', '')
    builder.addTextBox('qc_loxp_srpcr', 'LOXP SRPCR', '')
    builder.addTextBox('qc_loxp_srpcr_and_sequencing', 'LOCP SRPCR and sequencing', '')

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

})