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

    createGoal: function() {
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
            alert("You must enter a valid year.");
            return;
        }

        if(!endDate || endDate && endDate.length) {
            alert("You must enter a valid month.");
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
            'commence'               : commenceDate,
            'end'                    : endDate,
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
            labelWidth: 55,
            storeOptionsAreSpecial: true,
            hidden: false
        });

        self.yearText = Ext.create('Ext.form.field.Number', {
            fieldLabel: 'Year',
            name: 'year',
            labelWidth: 30,
            labelAlign: 'right',
            regex: /[1-9-]*/
        });

        //[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]

        self.monthText = Ext.create('Ext.form.field.Number', {
            fieldLabel: 'Month',
            name: 'month',
            labelWidth: 35,
            labelAlign: 'right',
            regex: /[1-9-]*/
        });

        self.miText = Ext.create('Ext.form.field.Number', {
            fieldLabel: 'MI Goal',
            name: 'mi_goal',
            labelWidth: 40,
            labelAlign: 'right',
            regex: /[1-9-]*/
        });

        self.gcText = Ext.create('Ext.form.field.Number', {
            fieldLabel: 'GC Goal',
            name: 'gc_goal',
            labelWidth: 40,
            labelAlign: 'right',
            regex: /[1-9-]*/
        });

        self.crisprmiText = Ext.create('Ext.form.field.Number', {
            fieldLabel: 'Crispr MI Goal',
            name: 'crispr_mi_goal',
            labelWidth: 40,
            labelAlign: 'right',
            regex: /[1-9-]*/
        });

        self.crisprgcText = Ext.create('Ext.form.field.Number', {
            fieldLabel: 'Crispr GC Goal',
            name: 'crispr_gc_goal',
            labelWidth: 40,
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
            self.crisprmiText,
            self.crisprgcText,
            '  ',
            {
                id: 'register_interest_button',
                text: 'Create goals',
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
            },
            filter: {
                type: 'list',
                options: window.CONSORTIUM_OPTIONS
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
        },
        {
            dataIndex: 'crispr_mi_goal',
            header: 'Crispr MI Goal',
            editor: 'simplenumberfield'
        },
        {
            dataIndex: 'crispr_gc_goal',
            header: 'Crispr GC Goal',
            editor: 'simplenumberfield'
        },
        {
            xtype:'actioncolumn',
            width:21,
            items: [{
                icon: 'images/icons/delete.png',
                tooltip: 'Delete',
                handler: function(grid, rowIndex, colIndex) {
                    var rec = grid.getStore().getAt(rowIndex);
                    if(confirm("Remove production goal?"))
                        grid.getStore().removeAt(rowIndex)
                }
            }]
        },
        {
            header: 'History',
            dataIndex: 'edit_link',
            renderer: function(value, metaData, record) {
                var pgId = record.getId();
                return Ext.String.format('<a href="{0}/production_goals/{1}/history">View history</a>', window.basePath, pgId);
            },
            sortable: false
        }
    ]
});
