load_goals = function(){
    if ( $('#goal_data').length == 0 ){return;}

    $('#goal_data').load('grants/get_goal_data', function(){
        line_graph_monthly_goals();
        column_graph_monthly_goal_counts();
    })
}

function replaceTextFieldWithExtField(selector, replacementCreationFunction) {
    Ext.select(selector).each(function (textField) {
        var name = textField.dom.name;
        var defaultValue = textField.dom.value;
        var renderDiv = new Ext.Element(Ext.core.DomHelper.createDom({tag: 'div', 'data-name-of-replaced': name}));
        renderDiv.replace(textField);

        replacementCreationFunction(renderDiv, name, defaultValue);
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

Ext.onReady(function() {
    initDateFields();
     
    var grid = Ext.create('Imits.widget.GrantGoalsGrid', {
        renderTo: 'grant_list'
    });

    load_goals();
});