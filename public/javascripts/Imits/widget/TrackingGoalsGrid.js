Ext.define('Imits.widget.TrackingGoalsGrid', {
    extend: 'Imits.widget.Grid',

    requires: [
        'Imits.model.TrackingGoal',
        'Imits.widget.grid.RansackFiltersFeature',
        'Imits.Util'
    ],

    title: 'Tracking Goals',
    iconCls: 'icon-grid',
    columnLines: true,

    store: {
        model: 'Imits.model.TrackingGoal',
        autoLoad: true,
        autoSync: true,
        remoteSort: true,
        remoteFilter: true,
      //  onUpdateRecords: function(records, operation, success) {
       //     console.log(records);
        //}
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

    createTrackingGoal: function() {
        var self = this;
        var centreName     = self.centreCombo.getSubmitValue();
        var yearValue      = self.yearText.getSubmitValue();
        var monthValue     = self.monthText.getSubmitValue();
        var goalValue      = self.goalText.getSubmitValue();
        var typeValue      = self.typeText.getSubmitValue();

        if(!centreName || centreName && !centreName.length) {
            alert("You must enter a valid Consortium.");
            return
        }

        //if(!yearValue.length || yearValue.length && (yearValue < 2010 || yearValue > 2050)) {
        //    alert("You must enter a valid year.");
        //    return;
        //}

        //if(monthValue.length && (monthValue < 1 || monthValue > 12)) {
        //    alert("You must enter a valid month.");
        //    return
        //}

        if(!goalValue.length || !typeValue) {
            alert("You must enter correct tracking goal values.")
            return
        }

        self.setLoading(true);

        var trackingGoal = Ext.create('Imits.model.TrackingGoal', {
            'production_centre_name' : centreName,
            'year'      : yearValue,
            'month'     : monthValue,
            'goal'      : goalValue,
            'goal_type' : typeValue
        });

        trackingGoal.save({
            callback: function() {
                self.reloadStore();
                self.setLoading(false);


                self.centreCombo.setValue()
                self.yearText.setValue()
                self.monthText.setValue()
                self.goalText.setValue()
                self.typeText.setValue()
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
        self.centreCombo = Ext.create('Imits.widget.SimpleCombo', {
            id: 'centreCombobox',
            store: window.CENTRE_OPTIONS,
            fieldLabel: 'Production centre',
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

        self.goalText = Ext.create('Ext.form.field.Number', {
            fieldLabel: 'Goal',
            name: 'goal',
            labelWidth: 50,
            labelAlign: 'right',
            regex: /[1-9-]*/
        });

        self.typeText = Ext.create('Imits.widget.SimpleCombo', {
            fieldLabel: 'Goal type',
            store: window.GOAL_TYPES,
            storeOptionsAreSpecial: true,
            name: 'goal_type',
            labelWidth: 50,
            labelAlign: 'right',
            width: 250,
            hidden: false
        });

        self.addDocked(Ext.create('Ext.toolbar.Toolbar', {
            dock: 'top',
            items: [
            self.centreCombo,
            self.yearText,
            self.monthText,
            self.goalText,
            self.typeText,
            '  ',
            {
                id: 'register_interest_button',
                text: 'Create tracking goal',
                cls:'x-btn-text-icon',
                iconCls: 'icon-add',
                grid: self,
                handler: function() {
                    self.createTrackingGoal();
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
            dataIndex: 'production_centre_name',
            header: 'Production centre',
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
            dataIndex: 'goal',
            header: 'Goal',
            editor: 'simplenumberfield'
        },
        {
            dataIndex: 'goal_type',
            header: 'Goal type',
            editor: {
                xtype: 'simplecombo',
                store: Ext.Array.merge([''], window.GOAL_TYPES),
                storeOptionsAreSpecial: true,
                listConfig: {
                    minWidth: 200
                }
            },
            filter: {
                type: 'list',
                options: window.GOAL_TYPES
            }
        },
        {
            xtype:'actioncolumn',
            width:21,
            items: [{
                icon: 'images/icons/delete.png',
                tooltip: 'Delete',
                handler: function(grid, rowIndex, colIndex) {
                    var rec = grid.getStore().getAt(rowIndex);
                    if(confirm("Remove tracking goal?"))
                        grid.getStore().removeAt(rowIndex)
                }
            }]
        },
        {
            header: 'History',
            dataIndex: 'edit_link',
            renderer: function(value, metaData, record) {
                var pgId = record.getId();
                return Ext.String.format('<a href="{0}/tracking_goals/{1}/history">View history</a>', window.basePath, pgId);
            },
            sortable: false
        }
    ]
});
