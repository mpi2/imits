function PlanSelectionList(){
    //Global Variables
    markerSymbol = 'Cbx1';
    selectorWindow = Ext.create('Imits.Plans.Selector.PlanSelectorWindow');
    planDataFieldId = '';
    consortiumDataFieldId = '';
    centreDataFieldId = '';
    hideShowDataFieldId = '';
    currentSelectedButton = '';


    $('.plan_selection_button').each(function(){
        var element_id = this.id;
        Ext.create('Imits.Plans.Selector.FormInitializer', {
            renderTo: element_id
        });
    });

}


Ext.define('Imits.Plans.Selector.PlanGrid', {

    set_plan_selection: function(MarkerSymbol){
        if (MarkerSymbol){
            this.store.load({params: {marker_symbol: MarkerSymbol}});
        };
    },

    extend: 'Ext.grid.Panel',
    store: {
        extend: 'Ext.data.JsonStore',
        proxy: {
            type: 'ajax',
            url: window.basePath + '/mi_plans/search_for_available_plans.json'
        },
        model: 'PlanListViewModel',
        storeId: 'planstore'
    },

    width:1000,
    height:250,
    title:'Select a Plan',
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
    }],

     initComponent: function() {
         this.callParent();
         this.addListener('selectionchange', function(view, nodes) {
             if (nodes.length > 0){
               Ext.get(planDataFieldId).set({ value: nodes[0].get('id') });
               $('#' + consortiumDataFieldId).html(nodes[0].get('consortium_name'));
               $('#' + centreDataFieldId).html(nodes[0].get('production_centre_name'));

               currentSelectedButton.innerHTML = 'Change Selection'
               Ext.get(hideShowDataFieldId).show();
             }

             selectorWindow.hide();
         });
    }
}),

Ext.define('Imits.Plans.Selector.PlanSelectorWindow', {
    extend: 'Imits.widget.Window',
    layout: {
        type: 'vbox',
        align: 'stretch'
    },
    title: 'Plan Selector',
    floating: true,
    resizable: false,
    closable: false,
    width: 1000,
    height: 300,
    items: [
    ],
    initComponent: function() {
        this.callParent();
        this.selectorGrid = Ext.create('Imits.Plans.Selector.PlanGrid' );
        this.add(this.selectorGrid);

        this.add(
            {
                xtype: 'button',
                text: 'Cancel',
                listeners: {
                    'click': function() {
                        selectorWindow.hide();
                        }
                }
            }
        );
    }
}),

// BUTTON TO SHOW SELECTION GRID

Ext.define('Imits.Plans.Selector.FormInitializer', {
    extend: 'Ext.panel.Panel',
    layout: {
        type: 'hbox',
        align: 'stretch'
    },
    ui: 'plain',
    width: 300,
    height: 40,
    items: [
        {
            xtype: 'button',
            margins: {
                left: 10,
                right: 0,
                top: 0,
                bottom: 0
            },
            text: 'Select Plan',
            listeners: {
                click: function() {
                    pd_parents = $(event.target).parents('.plan_details').toArray()[0];
                    ps_parent = $(event.target).parents('.plan_selector').toArray()[0];
                    consortiumDataFieldId = pd_parents.getElementsByClassName('consortium_name')[0].id;
                    centreDataFieldId = pd_parents.getElementsByClassName('production_centre_name')[0].id;
                    hideShowDataFieldId = pd_parents.children[0].id;
                    planDataFieldId = ps_parent.getElementsByClassName('plan_id')[0].children[0].id;
                    currentSelectedButton = $(event.target)[0];

                    selectorWindow.selectorGrid.set_plan_selection(markerSymbol);

                    // Wierd bug where the first show does not work after the grid has already been used to select a plan.
                    selectorWindow.show();
                    selectorWindow.show();
                },
                scope: this
            }
        }
    ]
});