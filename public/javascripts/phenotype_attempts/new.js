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

    var miplanstorephenotype = Ext.create('Ext.data.JsonStore', {
        model: 'MiPlanListViewModel',
        storeId: 'miplanstorephenotype',
        proxy: {
            type: 'ajax',
            url: window.basePath + '/mi_plans/search_for_available_phenotyping_plans.json'
        },
        reader: {
            type: 'json'
        }

    });

    var miplanlistview = Ext.create('Ext.grid.Panel', {
        id: 'mi_plan_list',
        width:1060,
        height:250,
        title:'Select a Plan',
        renderTo: 'mi_plan_list_phenotype',
        store: miplanstorephenotype,
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
            flex: 40,
            dataIndex: 'sub_project_name'
        },{
            text: 'Knockout First Tm1a',
            flex: 60,
            dataIndex: 'is_conditional_allele'
        },{
            text: 'Conditional tm1c',
            flex: 50,
            dataIndex: 'conditional_tm1c'
        },{
            text: 'Deletion',
            flex: 30,
            dataIndex: 'is_deletion_allele'
        },{
            text: 'Cre Knock In',
            flex: 40,
            dataIndex: 'is_cre_knock_in_allele'
        },{
            text: 'Cre Bac',
            flex: 30,
            dataIndex: 'is_cre_bac_allele'
        },{
            text: 'Point Mutation',
            flex: 40,
            dataIndex: 'point_mutation'
        },{
            text: 'Conditional Point Mutation',
            flex: 70,
            dataIndex: 'conditional_point_mutation'
        },{
            text: 'Active',
            flex: 40,
            dataIndex: 'is_active'
        }
        ]
    });


    miplanlistview.on('selectionchange', function(view, nodes){
      restOfForm.getInputElement("phenotype_attempt[mi_plan_id]").set({ value: nodes[0].get('id') });
      Ext.get("phenotype_attempt_production_centre_name").set({ value: nodes[0].get('production_centre_name') });
    });

    miplanstorephenotype.on('load', function(){

        var recordIndex = miplanstorephenotype.find('id', restOfForm.getInputElement('phenotype_attempt[mi_plan_id]').getValue());
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

    restOfForm.set_mi_plan_selection = function(MarkerSymbol, MiPlanId){
        if (MarkerSymbol){
            miplanstorephenotype.load({params: {marker_symbol: MarkerSymbol, mi_plan_id: MiPlanId}});
        };
    }

    restOfForm.set_mi_plan_selection(Ext.get('marker_symbol').getHTML(), restOfForm.getInputElement('phenotype_attempt[mi_plan_id]').getValue());


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
