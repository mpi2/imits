Ext.define('Imits.widget.GrantGoalsGrid', {
    extend: 'Imits.widget.Grid',

    requires: [
        'Imits.model.GrantGoal',
        'Imits.widget.grid.RansackFiltersFeature',
        'Imits.Util'
    ],

    title: 'Grant Goals',
    iconCls: 'icon-grid',
    columnLines: true,

    store: {
        model: 'Imits.model.GrantGoal',
        autoLoad: true,
        autoSync: true,
        remoteSort: true,
        remoteFilter: true,
    },

     selType: 'rowmodel',

    features: [
    {
        ftype: 'ransack_filters',
        local: false
    }
    ],

    plugins: [
    Ext.create('Ext.grid.plugin.RowEditing', {
        autoCancel: false,
        clicksToEdit: 1
    })
    ],

     createGrantGoal: function() {
         var self = this;
         var fundedBy             = self.fundedByCombo.getSubmitValue();
         var consortiumName       = self.consortiumCombo.getSubmitValue();
         var productionCentreName = self.productionCentreCombo.getSubmitValue();
         var commenceDate         = self.commenceDateText.getSubmitValue();
         var endDate              = self.endDateText.getSubmitValue();
         var delivery             = self.deliveryText.getSubmitValue();

        if(!consortiumName || consortiumName && !consortiumName.length) {
            alert("You must enter a valid Consortium.");
            return
        }

        if(!productionCentreName || productionCentreName && !productionCentreName.length) {
            alert("You must enter a valid Production Center.");
            return
        }

        if(!fundedBy || fundedBy && !fundedBy.length) {
            alert("You must enter a valid Funder.");
            return
        }

        if(!commenceDate || commenceDate && !commenceDate.length) {
            alert("You must enter a valid commence Date.");
            return;
        }

        if(!endDate || endDate && !endDate.length) {
            alert("You must enter a valid end Date.");
            return
        }

        if(!delivery || delivery && !delivery.length) {
            alert("You must enter the number of mouse lines to deliver.")
            return
        }

        self.setLoading(true);

        var grantGoal = Ext.create('Imits.model.GrantGoal', {
            'funding'                : fundedBy,
            'consortium_name'        : consortiumName,
            'production_centre_name' : productionCentreName,
            'commence_date'          : commenceDate,
            'end_date'               : endDate,
            'grant_goal'             : delivery 
        });

        grantGoal.save({
            callback: function() {
                self.reloadStore();
                self.setLoading(false);

                // reset docked fields.
               self.fundedByCombo.setValue();
               self.consortiumCombo.setValue();
               self.productionCentreCombo.setValue();
               self.commenceDateText.setValue();
               self.endDateText.setValue();
               self.deliveryText.setValue();
            }
        })
     },
 
     initComponent: function () {
        var self = this;
 
        self.callParent();
 
      //  Add the create toolbar.
        self.nameText = Ext.create('Ext.form.field.Text', {
            id: 'nameText',
            fieldLabel: 'Project / Grant Name',
            labelAlign: 'right',
            labelWidth: 70,
            width: 150,
            hidden: false
        });

        self.fundedByCombo = Ext.create('Ext.form.field.Text', {
            id: 'fundedByCombo',
            fieldLabel: 'Funded By',
            labelAlign: 'right',
            labelWidth: 60,
            width: 150,
            hidden: false
        });
 
        self.consortiumCombo = Ext.create('Imits.widget.SimpleCombo', {
            id: 'consortiumCombobox',
            store: window.CONSORTIUM_OPTIONS,
            fieldLabel: 'Consortium',
            labelAlign: 'right',
            labelWidth: 70,
            width: 200,
            storeOptionsAreSpecial: true,
            hidden: false
        });
 
        self.productionCentreCombo = Ext.create('Imits.widget.SimpleCombo', {
            id: 'productionCentreCombobox',
            store: window.CENTRE_OPTIONS,
            fieldLabel: 'Production Centre',
            labelAlign: 'right',
            labelWidth: 60,
            width: 200,
            storeOptionsAreSpecial: true,
            hidden: false
        });
 
 
        self.commenceDateText = Ext.create('Ext.form.field.Date', {
            fieldLabel: 'Commence',
            name: 'commence_date',
            labelWidth: 70,
            width: 190,
            labelAlign: 'right',
            regex: /[1-9-]*/
        });
 
        self.endDateText = Ext.create('Ext.form.field.Date', {
            fieldLabel: 'End',
            name: 'end_date',
            labelWidth: 30,
            width: 150,
            labelAlign: 'right'
        });
 
        self.deliveryText = Ext.create('Ext.form.field.Number', {
            fieldLabel: 'Delivery',
            name: 'delivery',
            labelWidth: 50,
            width: 125,
            labelAlign: 'right',
            regex: /[1-9-]*/
        });
 
        self.addDocked(Ext.create('Ext.toolbar.Toolbar', {
            dock: 'top',
            items: [
              self.nameText,
              self.fundedByCombo,
              self.consortiumCombo,
              self.productionCentreCombo,
              self.commenceDateText,
              self.endDateText ,
              self.deliveryText,
              {
                  id: 'register_interest_button',
                  text: 'Add Grant with Goals',
                  cls:'x-btn-text-icon',
                  iconCls: 'icon-add',
                  grid: self,
                   handler: function() {
                       self.createGrantGoal();
                   }
              }
           ]
        }));
     },

    columns: [
        {
            dataIndex: 'id',
            header: 'ID',
            readOnly: true,
            hidden: true
        },
        {
            dataIndex: 'name',
            header: 'Project / Grant',
            minWidth: 200,
            editor: 'textfield'
        },
        {
            dataIndex: 'funding',
            header: 'Funded By',
            minWidth: 200,
            editor: 'textfield'
        },
        // {
        //     dataIndex: 'funding',
        //     header: 'Funded By',
        //     editor: {
        //         xtype: 'simplecombo',
        //         store: Ext.Array.merge([''], window.PRODUCTION_CENTRE_OPTIONS),
        //         storeOptionsAreSpecial: true,
        //         listConfig: {
        //             minWidth: 200
        //         }
        //     },
        //     filter: {
        //         type: 'list',
        //         options: window.PRODUCTION_CENTRE_OPTIONS
        //     }
        // },
        {
            dataIndex: 'consortium_name',
            header: 'Consortium',
            minWidth: 200,
            editor: {
                xtype: 'simplecombo',
                store: Ext.Array.merge([''], window.CONSORTIUM_OPTIONS),
                storeOptionsAreSpecial: true,
                listConfig: {
                    minWidth: 200
                }
            },
            filter: {
                type: 'list',
                options: window.CONSORTIUM_OPTIONS
            }
        },
        {
            dataIndex: 'production_centre_name',
            header: 'Production Centre',
            minWidth: 200,
            editor: {
                xtype: 'simplecombo',
                store: Ext.Array.merge([''], window.CENTRE_OPTIONS),
                storeOptionsAreSpecial: true,
                listConfig: {
                    minWidth: 200
                }
            },
            filter: {
                type: 'list',
                options: window.CENTRE_OPTIONS
            }
        },
        {
            dataIndex: 'commence_date',
            xtype: 'simpledatecolumn',
            header: 'Commence',
            minWidth: 150
        },
        {
            dataIndex: 'end_date',
            xtype: 'simpledatecolumn',
            header: 'End',
            minWidth: 150
        },
        {
            dataIndex: 'grant_goal',
            header: 'Mouse Lines to Deliver',
            editor: 'simplenumberfield',
            minWidth: 150
        },
        {
            xtype:'actioncolumn',
            width:21,
            items: [{
                icon: 'images/icons/delete.png',
                tooltip: 'Delete',
                handler: function(grid, rowIndex, colIndex) {
                    var rec = grid.getStore().getAt(rowIndex);
                    if(confirm("Remove grant and goals?"))
                        grid.getStore().removeAt(rowIndex)
                }
            }]
        }
    ]
});
