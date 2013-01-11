Ext.define('Imits.widget.ProductionGoalsGrid', {
    extend: 'Imits.widget.Grid',

    requires: [
        'Imits.model.ProductionGoal',
        'Imits.Util'
    ],

    title: 'Production Goals',
    iconCls: 'icon-grid',
    columnLines: true,

    store: {
        model: 'Imits.model.ProductionGoal',
        autoLoad: true,
        autoSync: true,
        remoteSort: true,
        remoteFilter: true,
      //  onUpdateRecords: function(records, operation, success) {
       //     console.log(records);
        //}
    },

    selType: 'rowmodel',

    plugins: [
    Ext.create('Ext.grid.plugin.RowEditing', {
        autoCancel: false,
        clicksToEdit: 1
    })
    ],

    createProductionGoal: function() {
        var self = this;
        var consortiumName = self.consortiumCombo.getSubmitValue();
        var yearValue      = self.yearText.getSubmitValue();
        var monthValue     = self.monthText.getSubmitValue();
        var miValue        = self.miText.getSubmitValue();
        var gcValue        = self.gcText.getSubmitValue();

        if(!consortiumName || consortiumName && !consortiumName.length) {
            alert("You must enter a valid Consortium.");
            return
        }

        if(!yearValue.length || yearValue.length && (yearValue < 2010 || yearValue > 2050)) {
            alert("You must enter a valid year.");
            return;
        }

        if(monthValue.length && (monthValue < 1 || monthValue > 12)) {
            alert("You must enter a valid month.");
            return
        }

        if(!miValue.length || !gcValue) {
            alert("You must enter correct production goal values.")
            return
        }

        self.setLoading(true);

        var productionGoal = Ext.create('Imits.model.ProductionGoal', {
            'consortium_name' : consortiumName,
            'year' : yearValue,
            'month' : monthValue,
            'mi_goal' : miValue,
            'gc_goal' : gcValue
        });

        productionGoal.save({
            callback: function() {
                self.reloadStore();
                self.setLoading(false);


                self.consortiumCombo.setValue()
                self.yearText.setValue()
                self.monthText.setValue()
                self.miText.setValue()
                self.gcText.setValue()
            }
        })
    },

    initComponent: function () {
        var self = this;

        self.callParent();

        self.addDocked(Ext.create('Ext.toolbar.Paging', {
            store: self.getStore(),
            dock: 'bottom',
            displayInfo: true
        }));

        // Add the create toolbar.
        self.consortiumCombo = Ext.create('Imits.widget.SimpleCombo', {
            id: 'consortiumCombobox',
            store: window.CONSORTIUM_OPTIONS,
            fieldLabel: 'Consortium',
            labelAlign: 'right',
            labelWidth: 65,
            storeOptionsAreSpecial: true,
            hidden: false
        });

        self.yearText = Ext.create('Ext.form.field.Number', {
            fieldLabel: 'Year',
            name: 'year',
            labelWidth: 50,
            labelAlign: 'right',
            regex: /[1-9-]*/
        });

        //[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]

        self.monthText = Ext.create('Ext.form.field.Number', {
            fieldLabel: 'Month',
            name: 'month',
            labelWidth: 50,
            labelAlign: 'right',
            regex: /[1-9-]*/
        });

        self.miText = Ext.create('Ext.form.field.Number', {
            fieldLabel: 'MI Goal',
            name: 'mi_goal',
            labelWidth: 50,
            labelAlign: 'right',
            regex: /[1-9-]*/
        });

        self.gcText = Ext.create('Ext.form.field.Number', {
            fieldLabel: 'GC Goal',
            name: 'gc_goal',
            labelWidth: 50,
            labelAlign: 'right',
            regex: /[1-9-]*/
        });

        self.addDocked(Ext.create('Ext.toolbar.Toolbar', {
            dock: 'top',
            items: [
            self.consortiumCombo,
            self.yearText,
            self.monthText,
            self.miText,
            self.gcText,
            '  ',
            {
                id: 'register_interest_button',
                text: 'Create production goal',
                cls:'x-btn-text-icon',
                iconCls: 'icon-add',
                grid: self,
                handler: function() {
                    self.createProductionGoal();
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
        //{
        //    header: 'Edit In Form',
        //    dataIndex: 'edit_link',
        //    renderer: function(value, metaData, record) {
        //        var id = record.getId();
        //        return Ext.String.format('<a href="{0}/production_goals/{1}">Edit in Form</a>', window.basePath, id);
        //    },
        //    sortable: false
        //},
        {
            dataIndex: 'consortium_name',
            header: 'Consortium',
            editor: {
                xtype: 'simplecombo',
                store: Ext.Array.merge([''], window.CONSORTIUM_OPTIONS),
                storeOptionsAreSpecial: true,
                listConfig: {
                    minWidth: 200
                }
            }
        },
        {
            dataIndex: 'year',
            header: 'Year',
            editor: 'simplenumberfield'
        },
        {
            dataIndex: 'month',
            header: 'Month',
            editor: 'simplenumberfield'
        },
        {
            dataIndex: 'mi_goal',
            header: 'MI Goal',
            editor: 'simplenumberfield'
        },
        {
            dataIndex: 'gc_goal',
            header: 'GC Goal',
            editor: 'simplenumberfield'
        }
    ]
});
