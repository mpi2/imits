Ext.namespace('Imits.PhenotypeAttempts.New');
Ext.require([
    'MiPlanListViewModel'
]);
Ext.onReady(function() {
    processRestOfForm();

    var ignoreWarningsButton = Ext.get('ignore-warnings');
    if(ignoreWarningsButton) {
        ignoreWarningsButton.addListener('click', function() {
            Imits.PhenotypeAttempts.New.restOfForm.submitButton.onClickHandler();
        });
    }
});

function processRestOfForm() {
    var restOfForm = Ext.get('rest-of-form');

    var miplanstore = Ext.create('Ext.data.JsonStore', {
        model: 'MiPlanListViewModel',
        storeId: 'miplanstore',
        proxy: {
            type: 'ajax',
            url: window.basePath + '/mi_plans/search_by_marker_symbol.json'
        },
        reader: {
            type: 'json'
        }

    });

    var miplanlistview = Ext.create('Ext.grid.Panel', {
        id: 'mi_plan_list',
        width:1000,
        height:250,
        title:'Select a Plan',
        renderTo: 'mi_plan_list_phenotype',
        store: miplanstore,
        singleSelect : true,
        viewConfig: {
            emptyText: 'No images to display'
        },

        columns: [{
            text: 'Consortium',
            flex: 50,
            dataIndex: 'consortium_name'
        },{
            text: 'Production Centre',
            flex: 50,
            dataIndex: 'production_centre_name'
        },{
            text: 'Sub Project',
            flex: 50,
            dataIndex: 'sub_project_name'
        },{
            text: 'Conditional',
            flex: 50,
            dataIndex: 'is_conditional_allele'
        },{
            text: 'Deletion',
            flex: 50,
            dataIndex: 'is_deletion_allele'
        },{
            text: 'Cre Knock In',
            flex: 50,
            dataIndex: 'is_cre_knock_in_allele'
        },{
            text: 'Cre Bac',
            flex: 50,
            dataIndex: 'is_cre_bac_allele'
        },{
            text: 'Active',
            flex: 50,
            dataIndex: 'is_active'
        }
        ]
    });


    miplanlistview.on('selectionchange', function(view, nodes){
      restOfForm.getInputElement("phenotype_attempt[mi_plan_id]").set({ value: nodes[0].get('id') });
    });

    miplanstore.on('load', function(){

        var recordIndex = miplanstore.find('id', restOfForm.getInputElement("phenotype_attempt[mi_plan_id]").getValue());
        if (recordIndex != -1) {
            miplanlistview.getSelectionModel().select(recordIndex);
        }
    });

    restOfForm.getInputElement = function(name) {
        return Ext.get(Ext.Array.filter(Ext.query('#rest-of-form input'), function(i) {
            return i.name === name;
        })[0]);
    }

    restOfForm.showIfHidden = function() {
        if(this.hidden == true) {
            this.setVisible(true, true);
            this.hidden = false;
        }
    }

    restOfForm.set_mi_plan_selection = function(MarkerSymbol){
        if (MarkerSymbol){
            miplanstore.load({params: {marker_symbol: MarkerSymbol}});
        };
    }

    restOfForm.set_mi_plan_selection(Ext.get('marker_symbol').getHTML())


    restOfForm.submitButton = Ext.get('phenotype_attempt_submit');
    restOfForm.submitButton.onClickHandler = function() {
        this.dom.disabled = 'disabled';
        Ext.getBody().addCls('wait');
        var form = this.up('form');
        form.dom.submit();
    }
    restOfForm.submitButton.addListener('click', restOfForm.submitButton.onClickHandler, restOfForm.submitButton);

    Imits.PhenotypeAttempts.New.restOfForm = restOfForm;
}
