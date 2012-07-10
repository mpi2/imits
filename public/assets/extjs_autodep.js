Ext.define('Imits.widget.SimpleCombo', {
    extend: 'Ext.form.field.ComboBox',
    alias: 'widget.simplecombo',
    typeAhead: false,
    triggerAction: 'all',
    forceSelection: true,
    editable: false,

    constructor: function(config) {
        if(config.storeOptionsAreSpecial == true) {
            var mapper = function(i) {
                if(Ext.isEmpty(i)) {
                    return [i, window.NO_BREAK_SPACE];
                } else {
                    return [i, Ext.String.htmlEncode(i)];
                }
            };
            config.store = Ext.Array.map(config.store, mapper);
        }
        this.callParent([config]);
    },

    initComponent: function() {
        this.callParent();

        if(this.storeOptionsAreSpecial == true) {
            this.displayTpl = Ext.create('Ext.XTemplate',
                '<tpl for=".">' +
                '{[typeof values === "string" ? values : values["' + this.valueField + '"]]}' +
                '<tpl if="xindex < xcount">' + this.delimiter + '</tpl>' +
                '</tpl>'
                );
        }
    }
});

Ext.define('Imits.widget.SimpleCheckbox', {
    extend: 'Ext.form.field.Checkbox',
    alias: 'widget.simplecheckbox',

    editor: {
        xtype: 'checkbox',
        cls: 'x-grid-checkheader-editor'
    },

    renderer: function (value) {
        var classes = "x-grid-checkheader";
        if(value === true) {
            classes += ' x-grid-checkheader-checked';
        }
        return "<div class=\"" + classes + "\"></div>";
    },

    filter: {
        type: 'boolean',
        defaultValue: null
    }

});

Ext.define('Imits.widget.Grid', {
    extend: 'Ext.grid.Panel',

    manageResize: function() {
        var windowHeight = window.innerHeight - 30;
        if(!windowHeight) {
            windowHeight = document.documentElement.clientHeight - 30;
        }
        var newGridHeight = windowHeight - this.getEl().getTop();
        if(newGridHeight < 200) {
            newGridHeight = 200;
        }
        this.setHeight(newGridHeight);
        this.setWidth(this.getEl().up('div').getWidth());
        this.doLayout();
    },

    reloadStore: function() {
        var store = this.getStore();
        store.sync();
        store.load();
    }
});

Ext.define('Imits.data.JsonWriter', {
    extend: 'Ext.data.writer.Json',
    writeAllFields: false,
    write: function(originalRequest) {
        var request = this.callParent([originalRequest]);
        request.params['authenticity_token'] = window.authenticityToken;
        if(request.jsonData[this.root] && request.jsonData[this.root]['id']) {
            delete request.jsonData[this.root]['id'];
        }

        if(request.action === "destroy" && !Ext.isEmpty(request.params)) {
            // Set params as URL parameters if DELETE request instead of passing
            // them through as JSON in the body, or certain proxies complain
            request.url = Ext.urlAppend(request.url, Ext.urlEncode(request.params));
            request.jsonData = null;
            request.params = null;
        }

        return request;
    }
});

Ext.define('Imits.data.JsonReader', {
    extend: 'Ext.data.reader.Json',
    alias: null,

    readRecords: function(data) {
        if( !this.getRoot(data) && !Ext.isEmpty(data['id'])  ) {
            data = [data];
        }
        return this.callParent([data]);
    },

    getResponseData: function(response) {
        if(response.request.options.method == 'DELETE' &&
            response.status == 200) {
            return {};
        } else {
            return this.callParent([response]);
        }
    }
});

Ext.define('Imits.data.Proxy', {
    extend: 'Ext.data.proxy.Rest',
    requires: [
        'Imits.data.JsonWriter',
        'Imits.data.JsonReader'
    ],

    constructor: function (config) {
        var resource = config.resource;

        this.callParent([{
            format: 'json',
            url: window.basePath + '/' + resource + 's',
            extraParams: {
                'extended_response': true
            },
            startParam: undefined,
            limitParam: 'per_page',
            sortParam: 'sorts',

            reader: Ext.create('Imits.data.JsonReader', {
                root: resource + 's'
            }),

            writer: Ext.create('Imits.data.JsonWriter', {
                root: resource,
                writeAllFields: false
            }),

            listeners: {
                exception: function (proxy, response, operation) {
                    var errors = Ext.JSON.decode(response.responseText);
                    var errorHelper = function () {
                        var errorStrings = [];
                        Ext.Object.each(errors, function (key, values) {
                            var errorString =
                                Ext.String.capitalize(key).replace(/_/g, " ") +
                                ": ";
                            if (Ext.isString(values)) {
                                errorString += values;
                            } else if (Ext.isArray) {
                                errorString += values.join(", ");
                            }
                            errorStrings.push(errorString);
                        });
                        return errorStrings.join("<br/>");
                    };
                    Ext.MessageBox.show({
                        title: 'Error',
                        msg: errorHelper(errors),
                        icon: Ext.MessageBox.ERROR,
                        buttons: Ext.Msg.OK,
                        fn: function (buttonid, text, opt) {
                            console.log('TODO: Refresh the cell/row that was changed');
                        }
                    });
                }
            },

            encodeSorters: function(sorters) {
                if (sorters.length === 0) {
                    return "";
                } else {
                    var sorter = sorters[0];
                    return sorter.property + ' ' + sorter.direction.toLowerCase();
                }
            }
        }]);
    }
});

Ext.define('Imits.model.MiPlan', {
    extend: 'Ext.data.Model',
    requires: ['Imits.data.Proxy'],

    fields: [
    {
        name: 'id',
        type: 'int',
        persist: false
    },
    {
        name: 'marker_symbol'
    },
    {
        name: 'consortium_name'
    },
    {
        name: 'production_centre_name'
    },
    {
        name: 'status_name'
    },
    {
        name: 'priority_name'
    },
    {
        name: 'sub_project_name'
    },
    {
        name: 'number_of_es_cells_starting_qc'
    },
    {
        name: 'number_of_es_cells_passing_qc'
    },
    {
        name: 'withdrawn',
        defaultValue: false
    },
    {
        name: 'is_active',
        defaultValue: true
    },
    {
        name: 'is_bespoke_allele',
        defaultValue: false
    }
    ],

    proxy: Ext.create('Imits.data.Proxy', {
        resource: 'mi_plan'
    })
});

/*

This file is part of Ext JS 4

Copyright (c) 2011 Sencha Inc

Contact:  http://www.sencha.com/contact

GNU General Public License Usage
This file may be used under the terms of the GNU General Public License version 3.0 as published by the Free Software Foundation and appearing in the file LICENSE included in the packaging of this file.  Please review the following information to ensure the GNU General Public License version 3.0 requirements will be met: http://www.gnu.org/copyleft/gpl.html.

If you are unsure which license is appropriate for your use, please contact the sales department at http://www.sencha.com/contact.

*/
/**
 * @class Ext.ux.grid.menu.ListMenu
 * @extends Ext.menu.Menu
 * This is a supporting class for {@link Ext.ux.grid.filter.ListFilter}.
 * Although not listed as configuration options for this class, this class
 * also accepts all configuration options from {@link Ext.ux.grid.filter.ListFilter}.
 */
Ext.define('Ext.ux.grid.menu.ListMenu', {
    extend: 'Ext.menu.Menu',

    /**
     * @cfg {String} labelField
     * Defaults to 'text'.
     */
    labelField :  'text',
    /**
     * @cfg {String} paramPrefix
     * Defaults to 'Loading...'.
     */
    loadingText : 'Loading...',
    /**
     * @cfg {Boolean} loadOnShow
     * Defaults to true.
     */
    loadOnShow : true,
    /**
     * @cfg {Boolean} single
     * Specify true to group all items in this list into a single-select
     * radio button group. Defaults to false.
     */
    single : false,

    constructor : function (cfg) {
        this.selected = [];
        this.addEvents(
            /**
             * @event checkchange
             * Fires when there is a change in checked items from this list
             * @param {Object} item Ext.menu.CheckItem
             * @param {Object} checked The checked value that was set
             */
            'checkchange'
        );

        this.callParent([cfg = cfg || {}]);

        if(!cfg.store && cfg.options){
            var options = [];
            for(var i=0, len=cfg.options.length; i<len; i++){
                var value = cfg.options[i];
                switch(Ext.type(value)){
                    case 'array':  options.push(value); break;
                    case 'object': options.push([value.id, value[this.labelField]]); break;
                    case 'string': options.push([value, value]); break;
                }
            }

            this.store = Ext.create('Ext.data.ArrayStore', {
                fields: ['id', this.labelField],
                data:   options,
                listeners: {
                    'load': this.onLoad,
                    scope:  this
                }
            });
            this.loaded = true;
        } else {
            this.add({text: this.loadingText, iconCls: 'loading-indicator'});
            this.store.on('load', this.onLoad, this);
        }
    },

    destroy : function () {
        if (this.store) {
            this.store.destroyStore();
        }
        this.callParent();
    },

    /**
     * Lists will initially show a 'loading' item while the data is retrieved from the store.
     * In some cases the loaded data will result in a list that goes off the screen to the
     * right (as placement calculations were done with the loading item). This adapter will
     * allow show to be called with no arguments to show with the previous arguments and
     * thus recalculate the width and potentially hang the menu from the left.
     */
    show : function () {
        var lastArgs = null;
        return function(){
            if(arguments.length === 0){
                this.callParent(lastArgs);
            } else {
                lastArgs = arguments;
                if (this.loadOnShow && !this.loaded) {
                    this.store.load();
                }
                this.callParent(arguments);
            }
        };
    }(),

    /** @private */
    onLoad : function (store, records) {
        var me = this,
            visible = me.isVisible(),
            gid, item, itemValue, i, len;

        me.hide(false);

        me.removeAll(true);

        gid = me.single ? Ext.id() : null;
        for (i = 0, len = records.length; i < len; i++) {
            itemValue = records[i].get('id');
            item = Ext.create('Ext.menu.CheckItem', {
                text: records[i].get(me.labelField),
                group: gid,
                checked: Ext.Array.contains(me.selected, itemValue),
                hideOnClick: false,
                value: itemValue
            });

            item.on('checkchange', me.checkChange, me);

            me.add(item);
        }

        me.loaded = true;

        if (visible) {
            me.show();
        }
        me.fireEvent('load', me, records);
    },

    /**
     * Get the selected items.
     * @return {Array} selected
     */
    getSelected : function () {
        return this.selected;
    },

    /** @private */
    setSelected : function (value) {
        value = this.selected = [].concat(value);

        if (this.loaded) {
            this.items.each(function(item){
                item.setChecked(false, true);
                for (var i = 0, len = value.length; i < len; i++) {
                    if (item.value == value[i]) {
                        item.setChecked(true, true);
                    }
                }
            }, this);
        }
    },

    /**
     * Handler for the 'checkchange' event from an check item in this menu
     * @param {Object} item Ext.menu.CheckItem
     * @param {Object} checked The checked value that was set
     */
    checkChange : function (item, checked) {
        var value = [];
        this.items.each(function(item){
            if (item.checked) {
                value.push(item.value);
            }
        },this);
        this.selected = value;

        this.fireEvent('checkchange', item, checked);
    }
});


/*

This file is part of Ext JS 4

Copyright (c) 2011 Sencha Inc

Contact:  http://www.sencha.com/contact

GNU General Public License Usage
This file may be used under the terms of the GNU General Public License version 3.0 as published by the Free Software Foundation and appearing in the file LICENSE included in the packaging of this file.  Please review the following information to ensure the GNU General Public License version 3.0 requirements will be met: http://www.gnu.org/copyleft/gpl.html.

If you are unsure which license is appropriate for your use, please contact the sales department at http://www.sencha.com/contact.

*/
/**
 * @class Ext.ux.grid.menu.RangeMenu
 * @extends Ext.menu.Menu
 * Custom implementation of {@link Ext.menu.Menu} that has preconfigured items for entering numeric
 * range comparison values: less-than, greater-than, and equal-to. This is used internally
 * by {@link Ext.ux.grid.filter.NumericFilter} to create its menu.
 */
Ext.define('Ext.ux.grid.menu.RangeMenu', {
    extend: 'Ext.menu.Menu',

    /**
     * @cfg {String} fieldCls
     * The Class to use to construct each field item within this menu
     * Defaults to:<pre>
     * fieldCls : Ext.form.field.Number
     * </pre>
     */
    fieldCls : 'Ext.form.field.Number',

    /**
     * @cfg {Object} fieldCfg
     * The default configuration options for any field item unless superseded
     * by the <code>{@link #fields}</code> configuration.
     * Defaults to:<pre>
     * fieldCfg : {}
     * </pre>
     * Example usage:
     * <pre><code>
fieldCfg : {
    width: 150,
},
     * </code></pre>
     */

    /**
     * @cfg {Object} fields
     * The field items may be configured individually
     * Defaults to <tt>undefined</tt>.
     * Example usage:
     * <pre><code>
fields : {
    gt: { // override fieldCfg options
        width: 200,
        fieldCls: Ext.ux.form.CustomNumberField // to override default {@link #fieldCls}
    }
},
     * </code></pre>
     */

    /**
     * @cfg {Object} iconCls
     * The iconCls to be applied to each comparator field item.
     * Defaults to:<pre>
iconCls : {
    gt : 'ux-rangemenu-gt',
    lt : 'ux-rangemenu-lt',
    eq : 'ux-rangemenu-eq'
}
     * </pre>
     */
    iconCls : {
        gt : 'ux-rangemenu-gt',
        lt : 'ux-rangemenu-lt',
        eq : 'ux-rangemenu-eq'
    },

    /**
     * @cfg {Object} fieldLabels
     * Accessible label text for each comparator field item. Can be overridden by localization
     * files. Defaults to:<pre>
fieldLabels : {
     gt: 'Greater Than',
     lt: 'Less Than',
     eq: 'Equal To'
}</pre>
     */
    fieldLabels: {
        gt: 'Greater Than',
        lt: 'Less Than',
        eq: 'Equal To'
    },

    /**
     * @cfg {Object} menuItemCfgs
     * Default configuration options for each menu item
     * Defaults to:<pre>
menuItemCfgs : {
    emptyText: 'Enter Filter Text...',
    selectOnFocus: true,
    width: 125
}
     * </pre>
     */
    menuItemCfgs : {
        emptyText: 'Enter Number...',
        selectOnFocus: false,
        width: 155
    },

    /**
     * @cfg {Array} menuItems
     * The items to be shown in this menu.  Items are added to the menu
     * according to their position within this array. Defaults to:<pre>
     * menuItems : ['lt','gt','-','eq']
     * </pre>
     */
    menuItems : ['lt', 'gt', '-', 'eq'],


    constructor : function (config) {
        var me = this,
            fields, fieldCfg, i, len, item, cfg, Cls;

        me.callParent(arguments);

        fields = me.fields = me.fields || {};
        fieldCfg = me.fieldCfg = me.fieldCfg || {};
        
        me.addEvents(
            /**
             * @event update
             * Fires when a filter configuration has changed
             * @param {Ext.ux.grid.filter.Filter} this The filter object.
             */
            'update'
        );
      
        me.updateTask = Ext.create('Ext.util.DelayedTask', me.fireUpdate, me);
    
        for (i = 0, len = me.menuItems.length; i < len; i++) {
            item = me.menuItems[i];
            if (item !== '-') {
                // defaults
                cfg = {
                    itemId: 'range-' + item,
                    enableKeyEvents: true,
                    hideLabel: false,
                    fieldLabel: me.iconTpl.apply({
                        cls: me.iconCls[item] || 'no-icon',
                        text: me.fieldLabels[item] || '',
                        src: Ext.BLANK_IMAGE_URL
                    }),
                    labelSeparator: '',
                    labelWidth: 29,
                    listeners: {
                        scope: me,
                        change: me.onInputChange,
                        keyup: me.onInputKeyUp,
                        el: {
                            click: function(e) {
                                e.stopPropagation();
                            }
                        }
                    },
                    activate: Ext.emptyFn,
                    deactivate: Ext.emptyFn
                };
                Ext.apply(
                    cfg,
                    // custom configs
                    Ext.applyIf(fields[item] || {}, fieldCfg[item]),
                    // configurable defaults
                    me.menuItemCfgs
                );
                Cls = cfg.fieldCls || me.fieldCls;
                item = fields[item] = Ext.create(Cls, cfg);
            }
            me.add(item);
        }
    },

    /**
     * @private
     * called by this.updateTask
     */
    fireUpdate : function () {
        this.fireEvent('update', this);
    },
    
    /**
     * Get and return the value of the filter.
     * @return {String} The value of this filter
     */
    getValue : function () {
        var result = {}, key, field;
        for (key in this.fields) {
            field = this.fields[key];
            if (field.isValid() && field.getValue() !== null) {
                result[key] = field.getValue();
            }
        }
        return result;
    },
  
    /**
     * Set the value of this menu and fires the 'update' event.
     * @param {Object} data The data to assign to this menu
     */	
    setValue : function (data) {
        var key;
        for (key in this.fields) {
            this.fields[key].setValue(key in data ? data[key] : '');
        }
        this.fireEvent('update', this);
    },

    /**  
     * @private
     * Handler method called when there is a keyup event on an input
     * item of this menu.
     */
    onInputKeyUp: function(field, e) {
        if (e.getKey() === e.RETURN && field.isValid()) {
            e.stopEvent();
            this.hide();
        }
    },

    /**
     * @private
     * Handler method called when the user changes the value of one of the input
     * items in this menu.
     */
    onInputChange: function(field) {
        var me = this,
            fields = me.fields,
            eq = fields.eq,
            gt = fields.gt,
            lt = fields.lt;

        if (field == eq) {
            if (gt) {
                gt.setValue(null);
            }
            if (lt) {
                lt.setValue(null);
            }
        }
        else {
            eq.setValue(null);
        }

        // restart the timer
        this.updateTask.delay(this.updateBuffer);
    }
}, function() {

    /**
     * @cfg {Ext.XTemplate} iconTpl
     * A template for generating the label for each field in the menu
     */
    this.prototype.iconTpl = Ext.create('Ext.XTemplate',
        '<img src="{src}" alt="{text}" class="' + Ext.baseCSSPrefix + 'menu-item-icon ux-rangemenu-icon {cls}" />'
    );

});


/*

This file is part of Ext JS 4

Copyright (c) 2011 Sencha Inc

Contact:  http://www.sencha.com/contact

GNU General Public License Usage
This file may be used under the terms of the GNU General Public License version 3.0 as published by the Free Software Foundation and appearing in the file LICENSE included in the packaging of this file.  Please review the following information to ensure the GNU General Public License version 3.0 requirements will be met: http://www.gnu.org/copyleft/gpl.html.

If you are unsure which license is appropriate for your use, please contact the sales department at http://www.sencha.com/contact.

*/
/**
 * @class Ext.ux.grid.filter.Filter
 * @extends Ext.util.Observable
 * Abstract base class for filter implementations.
 */
Ext.define('Ext.ux.grid.filter.Filter', {
    extend: 'Ext.util.Observable',

    /**
     * @cfg {Boolean} active
     * Indicates the initial status of the filter (defaults to false).
     */
    active : false,
    /**
     * True if this filter is active.  Use setActive() to alter after configuration.
     * @type Boolean
     * @property active
     */
    /**
     * @cfg {String} dataIndex
     * The {@link Ext.data.Store} dataIndex of the field this filter represents.
     * The dataIndex does not actually have to exist in the store.
     */
    dataIndex : null,
    /**
     * The filter configuration menu that will be installed into the filter submenu of a column menu.
     * @type Ext.menu.Menu
     * @property
     */
    menu : null,
    /**
     * @cfg {Number} updateBuffer
     * Number of milliseconds to wait after user interaction to fire an update. Only supported
     * by filters: 'list', 'numeric', and 'string'. Defaults to 500.
     */
    updateBuffer : 500,

    constructor : function (config) {
        Ext.apply(this, config);

        this.addEvents(
            /**
             * @event activate
             * Fires when an inactive filter becomes active
             * @param {Ext.ux.grid.filter.Filter} this
             */
            'activate',
            /**
             * @event deactivate
             * Fires when an active filter becomes inactive
             * @param {Ext.ux.grid.filter.Filter} this
             */
            'deactivate',
            /**
             * @event serialize
             * Fires after the serialization process. Use this to attach additional parameters to serialization
             * data before it is encoded and sent to the server.
             * @param {Array/Object} data A map or collection of maps representing the current filter configuration.
             * @param {Ext.ux.grid.filter.Filter} filter The filter being serialized.
             */
            'serialize',
            /**
             * @event update
             * Fires when a filter configuration has changed
             * @param {Ext.ux.grid.filter.Filter} this The filter object.
             */
            'update'
        );
        Ext.ux.grid.filter.Filter.superclass.constructor.call(this);

        // setting filtered to true on all filter instances ensures that the filter won't be blurred when the mouse leaves the component
        this.menu = this.createMenu(Ext.applyIf({filtered: true}, config));
        this.init(config);
        if(config && config.value){
            this.setValue(config.value);
            this.setActive(config.active !== false, true);
            delete config.value;
        }
    },

    /**
     * Destroys this filter by purging any event listeners, and removing any menus.
     */
    destroy : function(){
        if (this.menu){
            this.menu.destroy();
        }
        this.clearListeners();
    },

    /**
     * Template method to be implemented by all subclasses that is to
     * initialize the filter and install required menu items.
     * Defaults to Ext.emptyFn.
     */
    init : Ext.emptyFn,

    /**
     * @private @override
     * Creates the Menu for this filter.
     * @param {Object} config Filter configuration
     * @return {Ext.menu.Menu}
     */
    createMenu: function(config) {
        return Ext.create('Ext.menu.Menu', config);
    },

    /**
     * Template method to be implemented by all subclasses that is to
     * get and return the value of the filter.
     * Defaults to Ext.emptyFn.
     * @return {Object} The 'serialized' form of this filter
     * @methodOf Ext.ux.grid.filter.Filter
     */
    getValue : Ext.emptyFn,

    /**
     * Template method to be implemented by all subclasses that is to
     * set the value of the filter and fire the 'update' event.
     * Defaults to Ext.emptyFn.
     * @param {Object} data The value to set the filter
     * @methodOf Ext.ux.grid.filter.Filter
     */
    setValue : Ext.emptyFn,

    /**
     * Template method to be implemented by all subclasses that is to
     * return <tt>true</tt> if the filter has enough configuration information to be activated.
     * Defaults to <tt>return true</tt>.
     * @return {Boolean}
     */
    isActivatable : function(){
        return true;
    },

    /**
     * Template method to be implemented by all subclasses that is to
     * get and return serialized filter data for transmission to the server.
     * Defaults to Ext.emptyFn.
     */
    getSerialArgs : Ext.emptyFn,

    /**
     * Template method to be implemented by all subclasses that is to
     * validates the provided Ext.data.Record against the filters configuration.
     * Defaults to <tt>return true</tt>.
     * @param {Ext.data.Record} record The record to validate
     * @return {Boolean} true if the record is valid within the bounds
     * of the filter, false otherwise.
     */
    validateRecord : function(){
        return true;
    },

    /**
     * Returns the serialized filter data for transmission to the server
     * and fires the 'serialize' event.
     * @return {Object/Array} An object or collection of objects containing
     * key value pairs representing the current configuration of the filter.
     * @methodOf Ext.ux.grid.filter.Filter
     */
    serialize : function(){
        var args = this.getSerialArgs();
        this.fireEvent('serialize', args, this);
        return args;
    },

    /** @private */
    fireUpdate : function(){
        if (this.active) {
            this.fireEvent('update', this);
        }
        this.setActive(this.isActivatable());
    },

    /**
     * Sets the status of the filter and fires the appropriate events.
     * @param {Boolean} active        The new filter state.
     * @param {Boolean} suppressEvent True to prevent events from being fired.
     * @methodOf Ext.ux.grid.filter.Filter
     */
    setActive : function(active, suppressEvent){
        if(this.active != active){
            this.active = active;
            if (suppressEvent !== true) {
                this.fireEvent(active ? 'activate' : 'deactivate', this);
            }
        }
    }
});


/*

This file is part of Ext JS 4

Copyright (c) 2011 Sencha Inc

Contact:  http://www.sencha.com/contact

GNU General Public License Usage
This file may be used under the terms of the GNU General Public License version 3.0 as published by the Free Software Foundation and appearing in the file LICENSE included in the packaging of this file.  Please review the following information to ensure the GNU General Public License version 3.0 requirements will be met: http://www.gnu.org/copyleft/gpl.html.

If you are unsure which license is appropriate for your use, please contact the sales department at http://www.sencha.com/contact.

*/
/**
 * @class Ext.ux.grid.filter.BooleanFilter
 * @extends Ext.ux.grid.filter.Filter
 * Boolean filters use unique radio group IDs (so you can have more than one!)
 * <p><b><u>Example Usage:</u></b></p>
 * <pre><code>
var filters = Ext.create('Ext.ux.grid.GridFilters', {
    ...
    filters: [{
        // required configs
        type: 'boolean',
        dataIndex: 'visible'

        // optional configs
        defaultValue: null, // leave unselected (false selected by default)
        yesText: 'Yes',     // default
        noText: 'No'        // default
    }]
});
 * </code></pre>
 */
Ext.define('Ext.ux.grid.filter.BooleanFilter', {
    extend: 'Ext.ux.grid.filter.Filter',
    alias: 'gridfilter.boolean',

	/**
	 * @cfg {Boolean} defaultValue
	 * Set this to null if you do not want either option to be checked by default. Defaults to false.
	 */
	defaultValue : false,
	/**
	 * @cfg {String} yesText
	 * Defaults to 'Yes'.
	 */
	yesText : 'Yes',
	/**
	 * @cfg {String} noText
	 * Defaults to 'No'.
	 */
	noText : 'No',

    /**
     * @private
     * Template method that is to initialize the filter and install required menu items.
     */
    init : function (config) {
        var gId = Ext.id();
		this.options = [
			Ext.create('Ext.menu.CheckItem', {text: this.yesText, group: gId, checked: this.defaultValue === true}),
			Ext.create('Ext.menu.CheckItem', {text: this.noText, group: gId, checked: this.defaultValue === false})];

		this.menu.add(this.options[0], this.options[1]);

		for(var i=0; i<this.options.length; i++){
			this.options[i].on('click', this.fireUpdate, this);
			this.options[i].on('checkchange', this.fireUpdate, this);
		}
	},

    /**
     * @private
     * Template method that is to get and return the value of the filter.
     * @return {String} The value of this filter
     */
    getValue : function () {
		return this.options[0].checked;
	},

    /**
     * @private
     * Template method that is to set the value of the filter.
     * @param {Object} value The value to set the filter
     */
	setValue : function (value) {
		this.options[value ? 0 : 1].setChecked(true);
	},

    /**
     * @private
     * Template method that is to get and return serialized filter data for
     * transmission to the server.
     * @return {Object/Array} An object or collection of objects containing
     * key value pairs representing the current configuration of the filter.
     */
    getSerialArgs : function () {
		var args = {type: 'boolean', value: this.getValue()};
		return args;
	},

    /**
     * Template method that is to validate the provided Ext.data.Record
     * against the filters configuration.
     * @param {Ext.data.Record} record The record to validate
     * @return {Boolean} true if the record is valid within the bounds
     * of the filter, false otherwise.
     */
    validateRecord : function (record) {
		return record.get(this.dataIndex) == this.getValue();
	}
});


/*

This file is part of Ext JS 4

Copyright (c) 2011 Sencha Inc

Contact:  http://www.sencha.com/contact

GNU General Public License Usage
This file may be used under the terms of the GNU General Public License version 3.0 as published by the Free Software Foundation and appearing in the file LICENSE included in the packaging of this file.  Please review the following information to ensure the GNU General Public License version 3.0 requirements will be met: http://www.gnu.org/copyleft/gpl.html.

If you are unsure which license is appropriate for your use, please contact the sales department at http://www.sencha.com/contact.

*/
/**
 * @class Ext.ux.grid.filter.DateFilter
 * @extends Ext.ux.grid.filter.Filter
 * Filter by a configurable Ext.picker.DatePicker menu
 * <p><b><u>Example Usage:</u></b></p>
 * <pre><code>
var filters = Ext.create('Ext.ux.grid.GridFilters', {
    ...
    filters: [{
        // required configs
        type: 'date',
        dataIndex: 'dateAdded',

        // optional configs
        dateFormat: 'm/d/Y',  // default
        beforeText: 'Before', // default
        afterText: 'After',   // default
        onText: 'On',         // default
        pickerOpts: {
            // any DatePicker configs
        },

        active: true // default is false
    }]
});
 * </code></pre>
 */
Ext.define('Ext.ux.grid.filter.DateFilter', {
    extend: 'Ext.ux.grid.filter.Filter',
    alias: 'gridfilter.date',
    uses: ['Ext.picker.Date', 'Ext.menu.Menu'],

    /**
     * @cfg {String} afterText
     * Defaults to 'After'.
     */
    afterText : 'After',
    /**
     * @cfg {String} beforeText
     * Defaults to 'Before'.
     */
    beforeText : 'Before',
    /**
     * @cfg {Object} compareMap
     * Map for assigning the comparison values used in serialization.
     */
    compareMap : {
        before: 'lt',
        after:  'gt',
        on:     'eq'
    },
    /**
     * @cfg {String} dateFormat
     * The date format to return when using getValue.
     * Defaults to 'm/d/Y'.
     */
    dateFormat : 'm/d/Y',

    /**
     * @cfg {Date} maxDate
     * Allowable date as passed to the Ext.DatePicker
     * Defaults to undefined.
     */
    /**
     * @cfg {Date} minDate
     * Allowable date as passed to the Ext.DatePicker
     * Defaults to undefined.
     */
    /**
     * @cfg {Array} menuItems
     * The items to be shown in this menu
     * Defaults to:<pre>
     * menuItems : ['before', 'after', '-', 'on'],
     * </pre>
     */
    menuItems : ['before', 'after', '-', 'on'],

    /**
     * @cfg {Object} menuItemCfgs
     * Default configuration options for each menu item
     */
    menuItemCfgs : {
        selectOnFocus: true,
        width: 125
    },

    /**
     * @cfg {String} onText
     * Defaults to 'On'.
     */
    onText : 'On',

    /**
     * @cfg {Object} pickerOpts
     * Configuration options for the date picker associated with each field.
     */
    pickerOpts : {},

    /**
     * @private
     * Template method that is to initialize the filter and install required menu items.
     */
    init : function (config) {
        var me = this,
            pickerCfg, i, len, item, cfg;

        pickerCfg = Ext.apply(me.pickerOpts, {
            xtype: 'datepicker',
            minDate: me.minDate,
            maxDate: me.maxDate,
            format:  me.dateFormat,
            listeners: {
                scope: me,
                select: me.onMenuSelect
            }
        });

        me.fields = {};
        for (i = 0, len = me.menuItems.length; i < len; i++) {
            item = me.menuItems[i];
            if (item !== '-') {
                cfg = {
                    itemId: 'range-' + item,
                    text: me[item + 'Text'],
                    menu: Ext.create('Ext.menu.Menu', {
                        items: [
                            Ext.apply(pickerCfg, {
                                itemId: item
                            })
                        ]
                    }),
                    listeners: {
                        scope: me,
                        checkchange: me.onCheckChange
                    }
                };
                item = me.fields[item] = Ext.create('Ext.menu.CheckItem', cfg);
            }
            //me.add(item);
            me.menu.add(item);
        }
    },

    onCheckChange : function () {
        this.setActive(this.isActivatable());
        this.fireEvent('update', this);
    },

    /**
     * @private
     * Handler method called when there is a keyup event on an input
     * item of this menu.
     */
    onInputKeyUp : function (field, e) {
        var k = e.getKey();
        if (k == e.RETURN && field.isValid()) {
            e.stopEvent();
            this.menu.hide();
        }
    },

    /**
     * Handler for when the DatePicker for a field fires the 'select' event
     * @param {Ext.picker.Date} picker
     * @param {Object} picker
     * @param {Object} date
     */
    onMenuSelect : function (picker, date) {
        var fields = this.fields,
            field = this.fields[picker.itemId];

        field.setChecked(true);

        if (field == fields.on) {
            fields.before.setChecked(false, true);
            fields.after.setChecked(false, true);
        } else {
            fields.on.setChecked(false, true);
            if (field == fields.after && this.getFieldValue('before') < date) {
                fields.before.setChecked(false, true);
            } else if (field == fields.before && this.getFieldValue('after') > date) {
                fields.after.setChecked(false, true);
            }
        }
        this.fireEvent('update', this);

        picker.up('menu').hide();
    },

    /**
     * @private
     * Template method that is to get and return the value of the filter.
     * @return {String} The value of this filter
     */
    getValue : function () {
        var key, result = {};
        for (key in this.fields) {
            if (this.fields[key].checked) {
                result[key] = this.getFieldValue(key);
            }
        }
        return result;
    },

    /**
     * @private
     * Template method that is to set the value of the filter.
     * @param {Object} value The value to set the filter
     * @param {Boolean} preserve true to preserve the checked status
     * of the other fields.  Defaults to false, unchecking the
     * other fields
     */
    setValue : function (value, preserve) {
        var key;
        for (key in this.fields) {
            if(value[key]){
                this.getPicker(key).setValue(value[key]);
                this.fields[key].setChecked(true);
            } else if (!preserve) {
                this.fields[key].setChecked(false);
            }
        }
        this.fireEvent('update', this);
    },

    /**
     * @private
     * Template method that is to return <tt>true</tt> if the filter
     * has enough configuration information to be activated.
     * @return {Boolean}
     */
    isActivatable : function () {
        var key;
        for (key in this.fields) {
            if (this.fields[key].checked) {
                return true;
            }
        }
        return false;
    },

    /**
     * @private
     * Template method that is to get and return serialized filter data for
     * transmission to the server.
     * @return {Object/Array} An object or collection of objects containing
     * key value pairs representing the current configuration of the filter.
     */
    getSerialArgs : function () {
        var args = [];
        for (var key in this.fields) {
            if(this.fields[key].checked){
                args.push({
                    type: 'date',
                    comparison: this.compareMap[key],
                    value: Ext.Date.format(this.getFieldValue(key), this.dateFormat)
                });
            }
        }
        return args;
    },

    /**
     * Get and return the date menu picker value
     * @param {String} item The field identifier ('before', 'after', 'on')
     * @return {Date} Gets the current selected value of the date field
     */
    getFieldValue : function(item){
        return this.getPicker(item).getValue();
    },

    /**
     * Gets the menu picker associated with the passed field
     * @param {String} item The field identifier ('before', 'after', 'on')
     * @return {Object} The menu picker
     */
    getPicker : function(item){
        return this.fields[item].menu.items.first();
    },

    /**
     * Template method that is to validate the provided Ext.data.Record
     * against the filters configuration.
     * @param {Ext.data.Record} record The record to validate
     * @return {Boolean} true if the record is valid within the bounds
     * of the filter, false otherwise.
     */
    validateRecord : function (record) {
        var key,
            pickerValue,
            val = record.get(this.dataIndex),
            clearTime = Ext.Date.clearTime;

        if(!Ext.isDate(val)){
            return false;
        }
        val = clearTime(val, true).getTime();

        for (key in this.fields) {
            if (this.fields[key].checked) {
                pickerValue = clearTime(this.getFieldValue(key), true).getTime();
                if (key == 'before' && pickerValue <= val) {
                    return false;
                }
                if (key == 'after' && pickerValue >= val) {
                    return false;
                }
                if (key == 'on' && pickerValue != val) {
                    return false;
                }
            }
        }
        return true;
    }
});


/*

This file is part of Ext JS 4

Copyright (c) 2011 Sencha Inc

Contact:  http://www.sencha.com/contact

GNU General Public License Usage
This file may be used under the terms of the GNU General Public License version 3.0 as published by the Free Software Foundation and appearing in the file LICENSE included in the packaging of this file.  Please review the following information to ensure the GNU General Public License version 3.0 requirements will be met: http://www.gnu.org/copyleft/gpl.html.

If you are unsure which license is appropriate for your use, please contact the sales department at http://www.sencha.com/contact.

*/
/**
 * @class Ext.ux.grid.filter.ListFilter
 * @extends Ext.ux.grid.filter.Filter
 * <p>List filters are able to be preloaded/backed by an Ext.data.Store to load
 * their options the first time they are shown. ListFilter utilizes the
 * {@link Ext.ux.grid.menu.ListMenu} component.</p>
 * <p>Although not shown here, this class accepts all configuration options
 * for {@link Ext.ux.grid.menu.ListMenu}.</p>
 *
 * <p><b><u>Example Usage:</u></b></p>
 * <pre><code>
var filters = Ext.create('Ext.ux.grid.GridFilters', {
    ...
    filters: [{
        type: 'list',
        dataIndex: 'size',
        phpMode: true,
        // options will be used as data to implicitly creates an ArrayStore
        options: ['extra small', 'small', 'medium', 'large', 'extra large']
    }]
});
 * </code></pre>
 *
 */
Ext.define('Ext.ux.grid.filter.ListFilter', {
    extend: 'Ext.ux.grid.filter.Filter',
    alias: 'gridfilter.list',

    /**
     * @cfg {Array} options
     * <p><code>data</code> to be used to implicitly create a data store
     * to back this list when the data source is <b>local</b>. If the
     * data for the list is remote, use the <code>{@link #store}</code>
     * config instead.</p>
     * <br><p>Each item within the provided array may be in one of the
     * following formats:</p>
     * <div class="mdetail-params"><ul>
     * <li><b>Array</b> :
     * <pre><code>
options: [
    [11, 'extra small'],
    [18, 'small'],
    [22, 'medium'],
    [35, 'large'],
    [44, 'extra large']
]
     * </code></pre>
     * </li>
     * <li><b>Object</b> :
     * <pre><code>
labelField: 'name', // override default of 'text'
options: [
    {id: 11, name:'extra small'},
    {id: 18, name:'small'},
    {id: 22, name:'medium'},
    {id: 35, name:'large'},
    {id: 44, name:'extra large'}
]
     * </code></pre>
     * </li>
     * <li><b>String</b> :
     * <pre><code>
     * options: ['extra small', 'small', 'medium', 'large', 'extra large']
     * </code></pre>
     * </li>
     */
    /**
     * @cfg {Boolean} phpMode
     * <p>Adjust the format of this filter. Defaults to false.</p>
     * <br><p>When GridFilters <code>@cfg encode = false</code> (default):</p>
     * <pre><code>
// phpMode == false (default):
filter[0][data][type] list
filter[0][data][value] value1
filter[0][data][value] value2
filter[0][field] prod

// phpMode == true:
filter[0][data][type] list
filter[0][data][value] value1, value2
filter[0][field] prod
     * </code></pre>
     * When GridFilters <code>@cfg encode = true</code>:
     * <pre><code>
// phpMode == false (default):
filter : [{"type":"list","value":["small","medium"],"field":"size"}]

// phpMode == true:
filter : [{"type":"list","value":"small,medium","field":"size"}]
     * </code></pre>
     */
    phpMode : false,
    /**
     * @cfg {Ext.data.Store} store
     * The {@link Ext.data.Store} this list should use as its data source
     * when the data source is <b>remote</b>. If the data for the list
     * is local, use the <code>{@link #options}</code> config instead.
     */

    /**
     * @private
     * Template method that is to initialize the filter.
     * @param {Object} config
     */
    init : function (config) {
        this.dt = Ext.create('Ext.util.DelayedTask', this.fireUpdate, this);
    },

    /**
     * @private @override
     * Creates the Menu for this filter.
     * @param {Object} config Filter configuration
     * @return {Ext.menu.Menu}
     */
    createMenu: function(config) {
        var menu = Ext.create('Ext.ux.grid.menu.ListMenu', config);
        menu.on('checkchange', this.onCheckChange, this);
        return menu;
    },

    /**
     * @private
     * Template method that is to get and return the value of the filter.
     * @return {String} The value of this filter
     */
    getValue : function () {
        return this.menu.getSelected();
    },
    /**
     * @private
     * Template method that is to set the value of the filter.
     * @param {Object} value The value to set the filter
     */
    setValue : function (value) {
        this.menu.setSelected(value);
        this.fireEvent('update', this);
    },

    /**
     * @private
     * Template method that is to return <tt>true</tt> if the filter
     * has enough configuration information to be activated.
     * @return {Boolean}
     */
    isActivatable : function () {
        return this.getValue().length > 0;
    },

    /**
     * @private
     * Template method that is to get and return serialized filter data for
     * transmission to the server.
     * @return {Object/Array} An object or collection of objects containing
     * key value pairs representing the current configuration of the filter.
     */
    getSerialArgs : function () {
        return {type: 'list', value: this.phpMode ? this.getValue().join(',') : this.getValue()};
    },

    /** @private */
    onCheckChange : function(){
        this.dt.delay(this.updateBuffer);
    },


    /**
     * Template method that is to validate the provided Ext.data.Record
     * against the filters configuration.
     * @param {Ext.data.Record} record The record to validate
     * @return {Boolean} true if the record is valid within the bounds
     * of the filter, false otherwise.
     */
    validateRecord : function (record) {
        var valuesArray = this.getValue();
        return Ext.Array.indexOf(valuesArray, record.get(this.dataIndex)) > -1;
    }
});


/*

This file is part of Ext JS 4

Copyright (c) 2011 Sencha Inc

Contact:  http://www.sencha.com/contact

GNU General Public License Usage
This file may be used under the terms of the GNU General Public License version 3.0 as published by the Free Software Foundation and appearing in the file LICENSE included in the packaging of this file.  Please review the following information to ensure the GNU General Public License version 3.0 requirements will be met: http://www.gnu.org/copyleft/gpl.html.

If you are unsure which license is appropriate for your use, please contact the sales department at http://www.sencha.com/contact.

*/
/**
 * @class Ext.ux.grid.filter.NumericFilter
 * @extends Ext.ux.grid.filter.Filter
 * Filters using an Ext.ux.grid.menu.RangeMenu.
 * <p><b><u>Example Usage:</u></b></p>
 * <pre><code>
var filters = Ext.create('Ext.ux.grid.GridFilters', {
    ...
    filters: [{
        type: 'numeric',
        dataIndex: 'price'
    }]
});
 * </code></pre>
 * <p>Any of the configuration options for {@link Ext.ux.grid.menu.RangeMenu} can also be specified as
 * configurations to NumericFilter, and will be copied over to the internal menu instance automatically.</p>
 */
Ext.define('Ext.ux.grid.filter.NumericFilter', {
    extend: 'Ext.ux.grid.filter.Filter',
    alias: 'gridfilter.numeric',
    uses: ['Ext.form.field.Number'],

    /**
     * @private @override
     * Creates the Menu for this filter.
     * @param {Object} config Filter configuration
     * @return {Ext.menu.Menu}
     */
    createMenu: function(config) {
        var me = this,
            menu;
        menu = Ext.create('Ext.ux.grid.menu.RangeMenu', config);
        menu.on('update', me.fireUpdate, me);
        return menu;
    },

    /**
     * @private
     * Template method that is to get and return the value of the filter.
     * @return {String} The value of this filter
     */
    getValue : function () {
        return this.menu.getValue();
    },

    /**
     * @private
     * Template method that is to set the value of the filter.
     * @param {Object} value The value to set the filter
     */
    setValue : function (value) {
        this.menu.setValue(value);
    },

    /**
     * @private
     * Template method that is to return <tt>true</tt> if the filter
     * has enough configuration information to be activated.
     * @return {Boolean}
     */
    isActivatable : function () {
        var values = this.getValue(),
            key;
        for (key in values) {
            if (values[key] !== undefined) {
                return true;
            }
        }
        return false;
    },

    /**
     * @private
     * Template method that is to get and return serialized filter data for
     * transmission to the server.
     * @return {Object/Array} An object or collection of objects containing
     * key value pairs representing the current configuration of the filter.
     */
    getSerialArgs : function () {
        var key,
            args = [],
            values = this.menu.getValue();
        for (key in values) {
            args.push({
                type: 'numeric',
                comparison: key,
                value: values[key]
            });
        }
        return args;
    },

    /**
     * Template method that is to validate the provided Ext.data.Record
     * against the filters configuration.
     * @param {Ext.data.Record} record The record to validate
     * @return {Boolean} true if the record is valid within the bounds
     * of the filter, false otherwise.
     */
    validateRecord : function (record) {
        var val = record.get(this.dataIndex),
            values = this.getValue(),
            isNumber = Ext.isNumber;
        if (isNumber(values.eq) && val != values.eq) {
            return false;
        }
        if (isNumber(values.lt) && val >= values.lt) {
            return false;
        }
        if (isNumber(values.gt) && val <= values.gt) {
            return false;
        }
        return true;
    }
});


/*

This file is part of Ext JS 4

Copyright (c) 2011 Sencha Inc

Contact:  http://www.sencha.com/contact

GNU General Public License Usage
This file may be used under the terms of the GNU General Public License version 3.0 as published by the Free Software Foundation and appearing in the file LICENSE included in the packaging of this file.  Please review the following information to ensure the GNU General Public License version 3.0 requirements will be met: http://www.gnu.org/copyleft/gpl.html.

If you are unsure which license is appropriate for your use, please contact the sales department at http://www.sencha.com/contact.

*/
/**
 * @class Ext.ux.grid.filter.StringFilter
 * @extends Ext.ux.grid.filter.Filter
 * Filter by a configurable Ext.form.field.Text
 * <p><b><u>Example Usage:</u></b></p>
 * <pre><code>
var filters = Ext.create('Ext.ux.grid.GridFilters', {
    ...
    filters: [{
        // required configs
        type: 'string',
        dataIndex: 'name',

        // optional configs
        value: 'foo',
        active: true, // default is false
        iconCls: 'ux-gridfilter-text-icon' // default
        // any Ext.form.field.Text configs accepted
    }]
});
 * </code></pre>
 */
Ext.define('Ext.ux.grid.filter.StringFilter', {
    extend: 'Ext.ux.grid.filter.Filter',
    alias: 'gridfilter.string',

    /**
     * @cfg {String} iconCls
     * The iconCls to be applied to the menu item.
     * Defaults to <tt>'ux-gridfilter-text-icon'</tt>.
     */
    iconCls : 'ux-gridfilter-text-icon',

    emptyText: 'Enter Filter Text...',
    selectOnFocus: true,
    width: 125,

    /**
     * @private
     * Template method that is to initialize the filter and install required menu items.
     */
    init : function (config) {
        Ext.applyIf(config, {
            enableKeyEvents: true,
            iconCls: this.iconCls,
            hideLabel: true,
            listeners: {
                scope: this,
                keyup: this.onInputKeyUp,
                el: {
                    click: function(e) {
                        e.stopPropagation();
                    }
                }
            }
        });

        this.inputItem = Ext.create('Ext.form.field.Text', config);
        this.menu.add(this.inputItem);
        this.updateTask = Ext.create('Ext.util.DelayedTask', this.fireUpdate, this);
    },

    /**
     * @private
     * Template method that is to get and return the value of the filter.
     * @return {String} The value of this filter
     */
    getValue : function () {
        return this.inputItem.getValue();
    },

    /**
     * @private
     * Template method that is to set the value of the filter.
     * @param {Object} value The value to set the filter
     */
    setValue : function (value) {
        this.inputItem.setValue(value);
        this.fireEvent('update', this);
    },

    /**
     * @private
     * Template method that is to return <tt>true</tt> if the filter
     * has enough configuration information to be activated.
     * @return {Boolean}
     */
    isActivatable : function () {
        return this.inputItem.getValue().length > 0;
    },

    /**
     * @private
     * Template method that is to get and return serialized filter data for
     * transmission to the server.
     * @return {Object/Array} An object or collection of objects containing
     * key value pairs representing the current configuration of the filter.
     */
    getSerialArgs : function () {
        return {type: 'string', value: this.getValue()};
    },

    /**
     * Template method that is to validate the provided Ext.data.Record
     * against the filters configuration.
     * @param {Ext.data.Record} record The record to validate
     * @return {Boolean} true if the record is valid within the bounds
     * of the filter, false otherwise.
     */
    validateRecord : function (record) {
        var val = record.get(this.dataIndex);

        if(typeof val != 'string') {
            return (this.getValue().length === 0);
        }

        return val.toLowerCase().indexOf(this.getValue().toLowerCase()) > -1;
    },

    /**
     * @private
     * Handler method called when there is a keyup event on this.inputItem
     */
    onInputKeyUp : function (field, e) {
        var k = e.getKey();
        if (k == e.RETURN && field.isValid()) {
            e.stopEvent();
            this.menu.hide();
            return;
        }
        // restart the timer
        this.updateTask.delay(this.updateBuffer);
    }
});


/*

This file is part of Ext JS 4

Copyright (c) 2011 Sencha Inc

Contact:  http://www.sencha.com/contact

GNU General Public License Usage
This file may be used under the terms of the GNU General Public License version 3.0 as published by the Free Software Foundation and appearing in the file LICENSE included in the packaging of this file.  Please review the following information to ensure the GNU General Public License version 3.0 requirements will be met: http://www.gnu.org/copyleft/gpl.html.

If you are unsure which license is appropriate for your use, please contact the sales department at http://www.sencha.com/contact.

*/
/**
 * @class Ext.ux.grid.FiltersFeature
 * @extends Ext.grid.Feature

FiltersFeature is a grid {@link Ext.grid.Feature feature} that allows for a slightly more
robust representation of filtering than what is provided by the default store.

Filtering is adjusted by the user using the grid's column header menu (this menu can be
disabled through configuration). Through this menu users can configure, enable, and
disable filters for each column.

#Features#

##Filtering implementations:##

Default filtering for Strings, Numeric Ranges, Date Ranges, Lists (which can be backed by a
{@link Ext.data.Store}), and Boolean. Additional custom filter types and menus are easily
created by extending {@link Ext.ux.grid.filter.Filter}.

##Graphical Indicators:##

Columns that are filtered have {@link #filterCls a configurable css class} applied to the column headers.

##Automatic Reconfiguration:##

Filters automatically reconfigure when the grid 'reconfigure' event fires.

##Stateful:##

Filter information will be persisted across page loads by specifying a `stateId`
in the Grid configuration.

The filter collection binds to the {@link Ext.grid.Panel#beforestaterestore beforestaterestore}
and {@link Ext.grid.Panel#beforestatesave beforestatesave} events in order to be stateful.

##GridPanel Changes:##

- A `filters` property is added to the GridPanel using this feature.
- A `filterupdate` event is added to the GridPanel and is fired upon onStateChange completion.

##Server side code examples:##

- [PHP](http://www.vinylfox.com/extjs/grid-filter-php-backend-code.php) - (Thanks VinylFox)</li>
- [Ruby on Rails](http://extjs.com/forum/showthread.php?p=77326#post77326) - (Thanks Zyclops)</li>
- [Ruby on Rails](http://extjs.com/forum/showthread.php?p=176596#post176596) - (Thanks Rotomaul)</li>
- [Python](http://www.debatablybeta.com/posts/using-extjss-grid-filtering-with-django/) - (Thanks Matt)</li>
- [Grails](http://mcantrell.wordpress.com/2008/08/22/extjs-grids-and-grails/) - (Thanks Mike)</li>

#Example usage:#

    var store = Ext.create('Ext.data.Store', {
        pageSize: 15
        ...
    });

    var filtersCfg = {
        ftype: 'filters',
        autoReload: false, //don't reload automatically
        local: true, //only filter locally
        // filters may be configured through the plugin,
        // or in the column definition within the headers configuration
        filters: [{
            type: 'numeric',
            dataIndex: 'id'
        }, {
            type: 'string',
            dataIndex: 'name'
        }, {
            type: 'numeric',
            dataIndex: 'price'
        }, {
            type: 'date',
            dataIndex: 'dateAdded'
        }, {
            type: 'list',
            dataIndex: 'size',
            options: ['extra small', 'small', 'medium', 'large', 'extra large'],
            phpMode: true
        }, {
            type: 'boolean',
            dataIndex: 'visible'
        }]
    };

    var grid = Ext.create('Ext.grid.Panel', {
         store: store,
         columns: ...,
         filters: [filtersCfg],
         height: 400,
         width: 700,
         bbar: Ext.create('Ext.PagingToolbar', {
             store: store
         })
    });

    // a filters property is added to the GridPanel
    grid.filters

 * @markdown
 */
Ext.define('Ext.ux.grid.FiltersFeature', {
    extend: 'Ext.grid.feature.Feature',
    alias: 'feature.filters',
    uses: [
        'Ext.ux.grid.menu.ListMenu',
        'Ext.ux.grid.menu.RangeMenu',
        'Ext.ux.grid.filter.BooleanFilter',
        'Ext.ux.grid.filter.DateFilter',
        'Ext.ux.grid.filter.ListFilter',
        'Ext.ux.grid.filter.NumericFilter',
        'Ext.ux.grid.filter.StringFilter'
    ],

    /**
     * @cfg {Boolean} autoReload
     * Defaults to true, reloading the datasource when a filter change happens.
     * Set this to false to prevent the datastore from being reloaded if there
     * are changes to the filters.  See <code>{@link updateBuffer}</code>.
     */
    autoReload : true,
    /**
     * @cfg {Boolean} encode
     * Specify true for {@link #buildQuery} to use Ext.util.JSON.encode to
     * encode the filter query parameter sent with a remote request.
     * Defaults to false.
     */
    /**
     * @cfg {Array} filters
     * An Array of filters config objects. Refer to each filter type class for
     * configuration details specific to each filter type. Filters for Strings,
     * Numeric Ranges, Date Ranges, Lists, and Boolean are the standard filters
     * available.
     */
    /**
     * @cfg {String} filterCls
     * The css class to be applied to column headers with active filters.
     * Defaults to <tt>'ux-filterd-column'</tt>.
     */
    filterCls : 'ux-filtered-column',
    /**
     * @cfg {Boolean} local
     * <tt>true</tt> to use Ext.data.Store filter functions (local filtering)
     * instead of the default (<tt>false</tt>) server side filtering.
     */
    local : false,
    /**
     * @cfg {String} menuFilterText
     * defaults to <tt>'Filters'</tt>.
     */
    menuFilterText : 'Filters',
    /**
     * @cfg {String} paramPrefix
     * The url parameter prefix for the filters.
     * Defaults to <tt>'filter'</tt>.
     */
    paramPrefix : 'filter',
    /**
     * @cfg {Boolean} showMenu
     * Defaults to true, including a filter submenu in the default header menu.
     */
    showMenu : true,
    /**
     * @cfg {String} stateId
     * Name of the value to be used to store state information.
     */
    stateId : undefined,
    /**
     * @cfg {Integer} updateBuffer
     * Number of milliseconds to defer store updates since the last filter change.
     */
    updateBuffer : 500,

    // doesn't handle grid body events
    hasFeatureEvent: false,


    /** @private */
    constructor : function (config) {
        var me = this;

        config = config || {};
        Ext.apply(me, config);

        me.deferredUpdate = Ext.create('Ext.util.DelayedTask', me.reload, me);

        // Init filters
        me.filters = me.createFiltersCollection();
        me.filterConfigs = config.filters;
    },

    attachEvents: function() {
        var me = this,
            view = me.view,
            headerCt = view.headerCt,
            grid = me.getGridPanel();

        me.bindStore(view.getStore(), true);

        // Listen for header menu being created
        headerCt.on('menucreate', me.onMenuCreate, me);

        view.on('refresh', me.onRefresh, me);
        grid.on({
            scope: me,
            beforestaterestore: me.applyState,
            beforestatesave: me.saveState,
            beforedestroy: me.destroy
        });

        // Add event and filters shortcut on grid panel
        grid.filters = me;
        grid.addEvents('filterupdate');
    },

    createFiltersCollection: function () {
        return Ext.create('Ext.util.MixedCollection', false, function (o) {
            return o ? o.dataIndex : null;
        });
    },

    /**
     * @private Create the Filter objects for the current configuration, destroying any existing ones first.
     */
    createFilters: function() {
        var me = this,
            hadFilters = me.filters.getCount(),
            grid = me.getGridPanel(),
            filters = me.createFiltersCollection(),
            model = grid.store.model,
            fields = model.prototype.fields,
            field,
            filter,
            state;

        if (hadFilters) {
            state = {};
            me.saveState(null, state);
        }

        function add (dataIndex, config, filterable) {
            if (dataIndex && (filterable || config)) {
                field = fields.get(dataIndex);
                filter = {
                    dataIndex: dataIndex,
                    type: (field && field.type && field.type.type) || 'auto'
                };

                if (Ext.isObject(config)) {
                    Ext.apply(filter, config);
                }

                filters.replace(filter);
            }
        }

        // We start with filters from our config and then merge on filters from the columns
        // in the grid. The Grid columns take precedence.
        Ext.Array.each(me.filterConfigs, function (fc) {
            add(fc.dataIndex, fc);
        });

        Ext.Array.each(grid.columns, function (column) {
            if (column.filterable === false) {
                filters.removeAtKey(column.dataIndex);
            } else {
                add(column.dataIndex, column.filter, column.filterable);
            }
        });

        me.removeAll();
        me.addFilters(filters.items);

        if (hadFilters) {
            me.applyState(null, state);
        }
    },

    /**
     * @private Handle creation of the grid's header menu. Initializes the filters and listens
     * for the menu being shown.
     */
    onMenuCreate: function(headerCt, menu) {
        var me = this;
        me.createFilters();
        menu.on('beforeshow', me.onMenuBeforeShow, me);
    },

    /**
     * @private Handle showing of the grid's header menu. Sets up the filter item and menu
     * appropriate for the target column.
     */
    onMenuBeforeShow: function(menu) {
        var me = this,
            menuItem, filter;

        if (me.showMenu) {
            menuItem = me.menuItem;
            if (!menuItem || menuItem.isDestroyed) {
                me.createMenuItem(menu);
                menuItem = me.menuItem;
            }

            filter = me.getMenuFilter();

            if (filter) {
                menuItem.menu = filter.menu;
                menuItem.setChecked(filter.active);
                // disable the menu if filter.disabled explicitly set to true
                menuItem.setDisabled(filter.disabled === true);
            }
            menuItem.setVisible(!!filter);
            this.sep.setVisible(!!filter);
        }
    },


    createMenuItem: function(menu) {
        var me = this;
        me.sep  = menu.add('-');
        me.menuItem = menu.add({
            checked: false,
            itemId: 'filters',
            text: me.menuFilterText,
            listeners: {
                scope: me,
                checkchange: me.onCheckChange,
                beforecheckchange: me.onBeforeCheck
            }
        });
    },

    getGridPanel: function() {
        return this.view.up('gridpanel');
    },

    /**
     * @private
     * Handler for the grid's beforestaterestore event (fires before the state of the
     * grid is restored).
     * @param {Object} grid The grid object
     * @param {Object} state The hash of state values returned from the StateProvider.
     */
    applyState : function (grid, state) {
        var key, filter;
        this.applyingState = true;
        this.clearFilters();
        if (state.filters) {
            for (key in state.filters) {
                filter = this.filters.get(key);
                if (filter) {
                    filter.setValue(state.filters[key]);
                    filter.setActive(true);
                }
            }
        }
        this.deferredUpdate.cancel();
        if (this.local) {
            this.reload();
        }
        delete this.applyingState;
        delete state.filters;
    },

    /**
     * Saves the state of all active filters
     * @param {Object} grid
     * @param {Object} state
     * @return {Boolean}
     */
    saveState : function (grid, state) {
        var filters = {};
        this.filters.each(function (filter) {
            if (filter.active) {
                filters[filter.dataIndex] = filter.getValue();
            }
        });
        return (state.filters = filters);
    },

    /**
     * @private
     * Handler called by the grid 'beforedestroy' event
     */
    destroy : function () {
        var me = this;
        Ext.destroyMembers(me, 'menuItem', 'sep');
        me.removeAll();
        me.clearListeners();
    },

    /**
     * Remove all filters, permanently destroying them.
     */
    removeAll : function () {
        if(this.filters){
            Ext.destroy.apply(Ext, this.filters.items);
            // remove all items from the collection
            this.filters.clear();
        }
    },


    /**
     * Changes the data store bound to this view and refreshes it.
     * @param {Store} store The store to bind to this view
     */
    bindStore : function(store, initial){
        if(!initial && this.store){
            if (this.local) {
                store.un('load', this.onLoad, this);
            } else {
                store.un('beforeload', this.onBeforeLoad, this);
            }
        }
        if(store){
            if (this.local) {
                store.on('load', this.onLoad, this);
            } else {
                store.on('beforeload', this.onBeforeLoad, this);
            }
        }
        this.store = store;
    },


    /**
     * @private
     * Get the filter menu from the filters MixedCollection based on the clicked header
     */
    getMenuFilter : function () {
        var header = this.view.headerCt.getMenu().activeHeader;
        return header ? this.filters.get(header.dataIndex) : null;
    },

    /** @private */
    onCheckChange : function (item, value) {
        this.getMenuFilter().setActive(value);
    },

    /** @private */
    onBeforeCheck : function (check, value) {
        return !value || this.getMenuFilter().isActivatable();
    },

    /**
     * @private
     * Handler for all events on filters.
     * @param {String} event Event name
     * @param {Object} filter Standard signature of the event before the event is fired
     */
    onStateChange : function (event, filter) {
        if (event !== 'serialize') {
            var me = this,
                grid = me.getGridPanel();

            if (filter == me.getMenuFilter()) {
                me.menuItem.setChecked(filter.active, false);
            }

            if ((me.autoReload || me.local) && !me.applyingState) {
                me.deferredUpdate.delay(me.updateBuffer);
            }
            me.updateColumnHeadings();

            if (!me.applyingState) {
                grid.saveState();
            }
            grid.fireEvent('filterupdate', me, filter);
        }
    },

    /**
     * @private
     * Handler for store's beforeload event when configured for remote filtering
     * @param {Object} store
     * @param {Object} options
     */
    onBeforeLoad : function (store, options) {
        options.params = options.params || {};
        this.cleanParams(options.params);
        var params = this.buildQuery(this.getFilterData());
        Ext.apply(options.params, params);
    },

    /**
     * @private
     * Handler for store's load event when configured for local filtering
     * @param {Object} store
     * @param {Object} options
     */
    onLoad : function (store, options) {
        store.filterBy(this.getRecordFilter());
    },

    /**
     * @private
     * Handler called when the grid's view is refreshed
     */
    onRefresh : function () {
        this.updateColumnHeadings();
    },

    /**
     * Update the styles for the header row based on the active filters
     */
    updateColumnHeadings : function () {
        var me = this,
            headerCt = me.view.headerCt;
        if (headerCt) {
            headerCt.items.each(function(header) {
                var filter = me.getFilter(header.dataIndex);
                header[filter && filter.active ? 'addCls' : 'removeCls'](me.filterCls);
            });
        }
    },

    /** @private */
    reload : function () {
        var me = this,
            store = me.view.getStore(),
            start;

        if (me.local) {
            store.clearFilter(true);
            store.filterBy(me.getRecordFilter());
        } else {
            me.deferredUpdate.cancel();
            store.loadPage(1);
        }
    },

    /**
     * Method factory that generates a record validator for the filters active at the time
     * of invokation.
     * @private
     */
    getRecordFilter : function () {
        var f = [], len, i;
        this.filters.each(function (filter) {
            if (filter.active) {
                f.push(filter);
            }
        });

        len = f.length;
        return function (record) {
            for (i = 0; i < len; i++) {
                if (!f[i].validateRecord(record)) {
                    return false;
                }
            }
            return true;
        };
    },

    /**
     * Adds a filter to the collection and observes it for state change.
     * @param {Object/Ext.ux.grid.filter.Filter} config A filter configuration or a filter object.
     * @return {Ext.ux.grid.filter.Filter} The existing or newly created filter object.
     */
    addFilter : function (config) {
        var Cls = this.getFilterClass(config.type),
            filter = config.menu ? config : (new Cls(config));
        this.filters.add(filter);

        Ext.util.Observable.capture(filter, this.onStateChange, this);
        return filter;
    },

    /**
     * Adds filters to the collection.
     * @param {Array} filters An Array of filter configuration objects.
     */
    addFilters : function (filters) {
        if (filters) {
            var i, len, filter;
            for (i = 0, len = filters.length; i < len; i++) {
                filter = filters[i];
                // if filter config found add filter for the column
                if (filter) {
                    this.addFilter(filter);
                }
            }
        }
    },

    /**
     * Returns a filter for the given dataIndex, if one exists.
     * @param {String} dataIndex The dataIndex of the desired filter object.
     * @return {Ext.ux.grid.filter.Filter}
     */
    getFilter : function (dataIndex) {
        return this.filters.get(dataIndex);
    },

    /**
     * Turns all filters off. This does not clear the configuration information
     * (see {@link #removeAll}).
     */
    clearFilters : function () {
        this.filters.each(function (filter) {
            filter.setActive(false);
        });
    },

    /**
     * Returns an Array of the currently active filters.
     * @return {Array} filters Array of the currently active filters.
     */
    getFilterData : function () {
        var filters = [], i, len;

        this.filters.each(function (f) {
            if (f.active) {
                var d = [].concat(f.serialize());
                for (i = 0, len = d.length; i < len; i++) {
                    filters.push({
                        field: f.dataIndex,
                        data: d[i]
                    });
                }
            }
        });
        return filters;
    },

    /**
     * Function to take the active filters data and build it into a query.
     * The format of the query depends on the <code>{@link #encode}</code>
     * configuration:
     * <div class="mdetail-params"><ul>
     *
     * <li><b><tt>false</tt></b> : <i>Default</i>
     * <div class="sub-desc">
     * Flatten into query string of the form (assuming <code>{@link #paramPrefix}='filters'</code>:
     * <pre><code>
filters[0][field]="someDataIndex"&
filters[0][data][comparison]="someValue1"&
filters[0][data][type]="someValue2"&
filters[0][data][value]="someValue3"&
     * </code></pre>
     * </div></li>
     * <li><b><tt>true</tt></b> :
     * <div class="sub-desc">
     * JSON encode the filter data
     * <pre><code>
filters[0][field]="someDataIndex"&
filters[0][data][comparison]="someValue1"&
filters[0][data][type]="someValue2"&
filters[0][data][value]="someValue3"&
     * </code></pre>
     * </div></li>
     * </ul></div>
     * Override this method to customize the format of the filter query for remote requests.
     * @param {Array} filters A collection of objects representing active filters and their configuration.
     *    Each element will take the form of {field: dataIndex, data: filterConf}. dataIndex is not assured
     *    to be unique as any one filter may be a composite of more basic filters for the same dataIndex.
     * @return {Object} Query keys and values
     */
    buildQuery : function (filters) {
        var p = {}, i, f, root, dataPrefix, key, tmp,
            len = filters.length;

        if (!this.encode){
            for (i = 0; i < len; i++) {
                f = filters[i];
                root = [this.paramPrefix, '[', i, ']'].join('');
                p[root + '[field]'] = f.field;

                dataPrefix = root + '[data]';
                for (key in f.data) {
                    p[[dataPrefix, '[', key, ']'].join('')] = f.data[key];
                }
            }
        } else {
            tmp = [];
            for (i = 0; i < len; i++) {
                f = filters[i];
                tmp.push(Ext.apply(
                    {},
                    {field: f.field},
                    f.data
                ));
            }
            // only build if there is active filter
            if (tmp.length > 0){
                p[this.paramPrefix] = Ext.JSON.encode(tmp);
            }
        }
        return p;
    },

    /**
     * Removes filter related query parameters from the provided object.
     * @param {Object} p Query parameters that may contain filter related fields.
     */
    cleanParams : function (p) {
        // if encoding just delete the property
        if (this.encode) {
            delete p[this.paramPrefix];
        // otherwise scrub the object of filter data
        } else {
            var regex, key;
            regex = new RegExp('^' + this.paramPrefix + '\[[0-9]+\]');
            for (key in p) {
                if (regex.test(key)) {
                    delete p[key];
                }
            }
        }
    },

    /**
     * Function for locating filter classes, overwrite this with your favorite
     * loader to provide dynamic filter loading.
     * @param {String} type The type of filter to load ('Filter' is automatically
     * appended to the passed type; eg, 'string' becomes 'StringFilter').
     * @return {Class} The Ext.ux.grid.filter.Class
     */
    getFilterClass : function (type) {
        // map the supported Ext.data.Field type values into a supported filter
        switch(type) {
            case 'auto':
              type = 'string';
              break;
            case 'int':
            case 'float':
              type = 'numeric';
              break;
            case 'bool':
              type = 'boolean';
              break;
        }
        return Ext.ClassManager.getByAlias('gridfilter.' + type);
    }
});


Ext.define('Imits.widget.grid.RansackFiltersFeature', {
    extend: 'Ext.ux.grid.FiltersFeature',
    alias: 'feature.ransack_filters',

    /**
     * @cfg {Boolean} encode
     * Unlike the base class, this parameter is totally ignored when
     * building a query
     */
    encode: false,

    buildQuerySingle: function (filter) {
        var param = {};
        switch (filter.data.type) {
            case 'string':
            case 'list':
                param['q[' + filter.field + '_ci_in][]'] = filter.data.value;
                break;

            case 'boolean':
                param['q[' + filter.field + '_eq]'] = filter.data.value;
                break;

            case 'date':
                var dateParts = filter.data.value.split('/');
                param['q[' + filter.field + '_' + filter.data.comparison + ']'] = [dateParts[2]+'-'+dateParts[0]+'-'+dateParts[1]];
                break;
        }
        return param;
    },

    buildQuery: function (filters) {
        var params = {};

        var self = this;

        Ext.each(filters, function (filter) {
            var p = self.buildQuerySingle(filter);
            for (var i in p) {
                params[i] = p[i];
            }
        });

        return params;
    },

    cleanParams: function (params) {
        var regex, key;
        regex = new RegExp('^q\\[\\w+_ci_in\\]$');
        for (key in params) {
            if (regex.test(key)) {
                delete params[key];
            }
        }
    }
});

Ext.define('Imits.widget.grid.MiPlanRansackFiltersFeature', {
    extend: 'Imits.widget.grid.RansackFiltersFeature',
    alias: 'feature.mi_plan_ransack_filters',

    encode: false,

    /** @private */
    constructor : function(config) {
        this.callParent([config]);

        var production_centre_name = window.USER_PRODUCTION_CENTRE;

        this.addFilter({
            type: 'string',
            dataIndex: 'production_centre_name',
            value: production_centre_name
        });
    }
});

Ext.define('Imits.widget.Window', {
    extend: 'Ext.window.Window',

    plain: true,

    showLoadMask: function() {
        this.loadMask = new Ext.LoadMask(this.getComponent(0).getEl());
        this.loadMask.show();
    },

    hideLoadMask: function() {
        this.loadMask.hide();
    }
});

Ext.define('Imits.widget.MiPlanEditor', {
    extend: 'Imits.widget.Window',

    requires: [
    'Imits.model.MiPlan',
    'Imits.widget.SimpleCombo',
    'Imits.widget.SimpleCheckbox'
    ],

    title: 'Change Gene Interest',
    resizable: false,
    layout: 'fit',
    closeAction: 'hide',
    cls: 'plan editor',

    constructor: function (config) {
        if(Ext.isIE7 || Ext.isIE8) {
            config.width = 400;
        }
        return this.callParent([config]);
    },

    initComponent: function () {
        var editor = this;
        this.callParent();

        var isSubProjectHidden = true;
        if(window.CAN_SEE_SUB_PROJECT) {
            isSubProjectHidden = false;
        }

        this.form = Ext.create('Ext.form.Panel', {
            ui: 'plain',
            margin: '0 0 10 0',
            width: 360,

            layout: 'anchor',
            defaults: {
                anchor: '100%',
                labelWidth: 150,
                labelAlign: 'right',
                labelPad: 10
            },

            items: [
            {
                id: 'marker_symbol',
                xtype: 'textfield',
                fieldLabel: 'Gene marker symbol',
                name: 'marker_symbol',
                readOnly: true
            },
            {
                id: 'consortium_name',
                xtype: 'textfield',
                fieldLabel: 'Consortium',
                name: 'consortium_name',
                readOnly: true
            },
            {
                id: 'production_centre_name',
                xtype: 'simplecombo',
                fieldLabel: 'Production Centre',
                name: 'production_centre_name',
                storeOptionsAreSpecial: true,
                store: window.CENTRE_OPTIONS
            },
            {
                id: 'status_name',
                xtype: 'textfield',
                fieldLabel: 'Status',
                name: 'status_name',
                readOnly: true
            },
            {
                id: 'priority_name',
                xtype: 'simplecombo',
                fieldLabel: 'Priority',
                name: 'priority_name',
                store: window.PRIORITY_OPTIONS
            },
            {
                id: 'is_bespoke_allele',
                xtype: 'simplecheckbox',
                fieldLabel: 'Bespoke allele?',
                name: 'is_bespoke_allele',
                hidden: isSubProjectHidden
            },
            {
                id: 'sub_project_name',
                xtype: 'simplecombo',
                fieldLabel: 'Sub-Project',
                name: 'sub_project_name',
                storeOptionsAreSpecial: true,
                store: window.SUB_PROJECT_OPTIONS,
                hidden: isSubProjectHidden
            },
            {
                id: 'number_of_es_cells_starting_qc',
                xtype: 'simplenumberfield',
                fieldLabel: '# of ES Cells starting QC',
                name: 'number_of_es_cells_starting_qc'
            },
            {
                id: 'number_of_es_cells_passing_qc',
                xtype: 'simplenumberfield',
                fieldLabel: '# of ES Cells passing QC',
                name: 'number_of_es_cells_passing_qc'
            }
            ],

            buttons: [
            {
                id: 'update-button',
                text: '<strong>Update</strong>',
                handler: function (button) {
                    button.disable();

                    var message = null;

                    if(Ext.isEmpty(editor.miPlan.get('number_of_es_cells_passing_qc')) &&
                        !Ext.isEmpty(editor.form.getComponent('number_of_es_cells_passing_qc').getValue())) {
                        if(editor.form.getComponent('number_of_es_cells_passing_qc').getValue() == 0) {
                            message = 'Saving these changes will force the status to "Aborted - ES Cell QC Failed"';
                        } else {
                            message = 'Saving these changes will force the status to "Assigned - ES Cell QC Complete"';
                        }

                    } else if(Ext.isEmpty(editor.miPlan.get('number_of_es_cells_starting_qc')) &&

                        !Ext.isEmpty(editor.form.getComponent('number_of_es_cells_starting_qc').getValue())) {

                        message = 'Saving these changes will force the status to "Assigned - ES Cell QC In Progress"';
                    }

                    if(!Ext.isEmpty(message)) {
                        Ext.Msg.show({
                            title:'Notice',
                            msg: message + " - is that OK?",
                            buttons: Ext.Msg.YESNO,
                            icon: Ext.Msg.QUESTION,
                            closable: false,
                            fn: function (clicked) {
                                if(clicked === 'yes') {
                                    editor.updateAndHide();
                                } else {
                                    button.enable();
                                }
                            }
                        });
                    } else {
                        editor.updateAndHide();
                    }
                }
            },
            {
                text: 'Cancel',
                handler: function () {
                    editor.hide();
                }
            }
            ]
        });

        var deleteContainer = Ext.create('Ext.panel.Panel', {
            ui: 'plain',
            layout: {
                type: 'hbox',
                align: 'stretchmax'
            },
            margin: '0 0 10 0',
            items: [
            {
                xtype: 'label',
                text: "Delete interest?",
                cls: 'x-form-item-label',
                margin: '0 5 0 0'
            },
            {
                xtype: 'button',
                id: 'delete-button',
                text: 'Delete',
                width: 60,
                handler: function (button) {
                    button.hide();
                    deleteContainer.getComponent('delete-confirmation-button').show();
                }
            },
            {
                xtype: 'button',
                id: 'delete-confirmation-button',
                text: 'Are you sure?',
                width: 100,
                hidden: true,
                handler: function (button) {
                    editor.setLoading(true);
                    editor.miPlan.destroy({
                        success: function () {
                            editor.setLoading(false);
                            editor.hide();
                        }
                    });
                    button.hide();
                    deleteContainer.getComponent('delete-button').show();
                }
            }
            ]
        });

        var withdrawContainer = Ext.create('Ext.panel.Panel', {
            ui: 'plain',
            layout: {
                type: 'hbox',
                align: 'stretchmax'
            },
            margin: '0 0 10 0',
            items: [
            {
                xtype: 'label',
                text: "Withdraw interest",
                cls: 'x-form-item-label',
                margin: '0 5 0 0'
            },
            {
                xtype: 'button',
                id: 'withdraw-button',
                text: 'Withdraw',
                width: 60,
                handler: function (button) {
                    button.hide();
                    withdrawContainer.getComponent('withdraw-confirmation-button').show();
                }
            },
            {
                xtype: 'button',
                id: 'withdraw-confirmation-button',
                text: 'Are you sure?',
                width: 100,
                hidden: true,
                handler: function (button) {
                    editor.setLoading(true);
                    var miPlan = editor.miPlan;

                    miPlan.set('withdrawn', true);
                    editor.miPlan.save({
                        success: function () {
                            editor.setLoading(false);
                            editor.hide();
                        }
                    });
                    button.hide();
                    withdrawContainer.getComponent('withdraw-button').show();
                }
            }
            ]
        });

        var inactivateContainer = Ext.create('Ext.panel.Panel', {
            ui: 'plain',
            layout: {
                type: 'hbox',
                align: 'stretchmax'
            },
            margin: '0 0 10 0',
            items: [
            {
                xtype: 'label',
                text: "Inactivate plan?",
                cls: 'x-form-item-label',
                margin: '0 5 0 0'
            },
            {
                xtype: 'button',
                id: 'inactivate-button',
                text: 'Inactivate',
                width: 60,
                handler: function (button) {
                    button.hide();
                    inactivateContainer.getComponent('inactivate-confirmation-button').show();
                }
            },
            {
                xtype: 'button',
                id: 'inactivate-confirmation-button',
                text: 'Are you sure?',
                width: 100,
                hidden: true,
                handler: function (button) {
                    editor.setLoading(true);
                    var miPlan = editor.miPlan;

                    miPlan.set('is_active', false);
                    editor.miPlan.save({
                        success: function () {
                            editor.setLoading(false);
                            editor.hide();
                        }
                    });
                    button.hide();
                    inactivateContainer.getComponent('inactivate-button').show();
                }
            }
            ]
        });
        var panelHeight = 420;
        if(window.CAN_SEE_SUB_PROJECT) {
            panelHeight = 440;
        }

        this.add(Ext.create('Ext.panel.Panel', {
            height: panelHeight,
            ui: 'plain',
            layout: {
                type: 'vbox',
                align: 'stretchmax'
            },
            padding: 15,
            items: [
            editor.form,
            deleteContainer,
            withdrawContainer,
            inactivateContainer
            ]
        }));

        editor.updateButton = Ext.getCmp('update-button');
        this.addListener('hide', function () {
            editor.updateButton.enable();
        });

        editor.withdrawButton = Ext.getCmp('withdraw-button');
        editor.inactivateButton = Ext.getCmp('inactivate-button');

        this.fields = this.form.items.keys;
        this.updateableFields = this.form.items.filterBy(function (i) {
            return i.readOnly != true;
        }).keys;
    },

    edit: function (miPlanId) {
        var editor = this;

        Imits.model.MiPlan.load(miPlanId, {
            success: function (miPlan) {
                editor.miPlan = miPlan;
                Ext.each(editor.fields, function (attr) {
                    var component = editor.form.getComponent(attr);
                    if(component) {
                        component.setValue(editor.miPlan.get(attr));
                    }
                });
                editor.show();

                if(Ext.Array.indexOf(window.WITHDRAWABLE_STATUSES, miPlan.get('status_name')) == -1) {
                    editor.withdrawButton.disable();
                } else {
                    editor.withdrawButton.enable();
                }
            }
        });
    },

    updateAndHide: function () {
        var editor = this;
        Ext.each(this.updateableFields, function (attr) {
            var component = editor.form.getComponent(attr);
            if(component) {
                editor.miPlan.set(attr, component.getValue());
            }
        });

        editor.miPlan.save({
            success: function () {
                editor.hide();
            },

            failure: function () {
                editor.updateButton.enable();
            }
        });
    }

});

Ext.define('Imits.widget.MiPlansGrid', {
    extend: 'Imits.widget.Grid',

    requires: [
    'Imits.model.MiPlan',
    'Imits.widget.grid.MiPlanRansackFiltersFeature',
    'Imits.widget.MiPlanEditor'
    ],

    title: 'Your Plans',
    iconCls: 'icon-grid',
    columnLines: true,

    store: {
        model: 'Imits.model.MiPlan',
        autoLoad: true,
        remoteSort: true,
        remoteFilter: true,
        pageSize: 20
    },

    selType: 'rowmodel',


    features: [
    {
        ftype: 'mi_plan_ransack_filters',
        local: false
    }
    ],

    initComponent: function () {
        var self = this;

        self.callParent();

        self.addDocked(Ext.create('Ext.toolbar.Paging', {
            store: self.getStore(),
            dock: 'bottom',
            displayInfo: true
        }));

        self.miPlanEditor = Ext.create('Imits.widget.MiPlanEditor', {
            listeners: {
                'hide': {
                    fn: function () {
                        self.reloadStore();
                        self.setLoading(false);
                    }
                }
            }
        });

        self.addListener('itemclick', function (theView, record) {
            var id = record.data['id'];
            self.setLoading("Editing plan....");
            self.miPlanEditor.edit(id);
        });

        self.addListener('afterrender', function () {
            if(window.CAN_SEE_SUB_PROJECT) {
                var subProjectColumn = Ext.Array.filter(self.columns, function (i) {
                    return i.dataIndex === 'sub_project_name';
                })[0];
                subProjectColumn.setVisible(true);
                var isBespokeColumn = Ext.Array.filter(self.columns, function (i) {
                    return i.dataIndex === 'is_bespoke_allele';
                })[0];
                isBespokeColumn.setVisible(true);
            }
        });
    },

    columns: [
    {
        dataIndex: 'marker_symbol',
        header: 'Marker Symbol',
        readOnly: true,
        filter: {
            type: 'string'
        }
    },
    {
        dataIndex: 'id',
        header: 'ID',
        readOnly: true,
        hidden: true
    },
    {
        dataIndex: 'consortium_name',
        header: 'Consortium',
        readOnly: true,
        width: 115,
        filter: {
            type: 'list',
            options: window.CONSORTIUM_OPTIONS
        }
    },
    {
        dataIndex: 'is_bespoke_allele',
        header: 'Bespoke allele?',
        xtype: 'boolgridcolumn',
        readOnly: true,
        hidden: true
    },
    {
        dataIndex: 'sub_project_name',
        header: 'Sub-Project',
        readOnly: true,
        width: 150,
        filter: {
            type: 'list',
            options: window.SUB_PROJECT_OPTIONS
        },
        hidden: true
    },
    {
        dataIndex: 'production_centre_name',
        header: 'Production Centre',
        readOnly: true,
        width: 115,
        filter: {
            type: 'list',
            options: window.CENTRE_OPTIONS
        }
    },
    {
        dataIndex: 'priority_name',
        header: 'Priority',
        readOnly: true,
        filter: {
            type: 'list',
            options: window.PRIORITY_OPTIONS
        }
    },
    {
        dataIndex: 'status_name',
        header: 'Status',
        readOnly: true,
        flex: 1,
        filter: {
            type: 'list',
            options: window.STATUS_OPTIONS
        }
    }
    ]
});

Ext.define('Imits.widget.grid.BoolGridColumn', {
    extend: 'Ext.grid.Column',
    alias: 'widget.boolgridcolumn',

    editor: {
        xtype: 'checkbox',
        cls: 'x-grid-checkheader-editor'
    },

    renderer: function (value) {
        var classes = "x-grid-checkheader";
        if(value === true) {
            classes += ' x-grid-checkheader-checked';
        }
        return "<div class=\"" + classes + "\"></div>";
    },

    filter: {
        type: 'boolean',
        defaultValue: null
    }
});

Ext.define('Imits.widget.grid.PhenotypeAttemptRansackFiltersFeature', {
    extend: 'Imits.widget.grid.RansackFiltersFeature',
    alias: 'feature.phenotype_attempt_ransack_filters',

    encode: false,

    /** @private */
    constructor : function (config) {
        this.callParent([config]);

        var production_centre_name = window.PHENOTYPE_ATTEMPT_SEARCH_PARAMS.production_centre_name;

        if(!Ext.isEmpty(production_centre_name)) {
            this.addFilter({
                type: 'string',
                dataIndex: 'production_centre_name',
                value: production_centre_name
            });
        }

    },

    buildQuery: function (filters) {
        var params = this.callParent([filters]);
        var terms = window.PHENOTYPE_ATTEMPT_SEARCH_PARAMS.terms;

        if(!Ext.isEmpty(terms)) {
            terms = terms.split("\n");
            params['q[marker_symbol_ci_in][]'] = terms;
        }

        return params;
    }
});

Ext.define('Imits.widget.grid.MiAttemptRansackFiltersFeature', {
    extend: 'Imits.widget.grid.RansackFiltersFeature',
    alias: 'feature.mi_attempt_ransack_filters',

    encode: false,

    /** @private */
    constructor : function (config) {
        this.callParent([config]);

        var production_centre_name = window.MI_ATTEMPT_SEARCH_PARAMS.production_centre_name;
        var statusName = window.MI_ATTEMPT_SEARCH_PARAMS.status_name;

        if(!Ext.isEmpty(production_centre_name)) {
            this.addFilter({
                type: 'string',
                dataIndex: 'production_centre_name',
                value: production_centre_name
            });
        }

        if(!Ext.isEmpty(statusName)) {
            this.addFilter({
                type: 'string',
                dataIndex: 'status_name',
                value: statusName
            });
        }
    },

    buildQuery: function (filters) {
        var params = this.callParent([filters]);
        var terms = window.MI_ATTEMPT_SEARCH_PARAMS.terms;

        if(!Ext.isEmpty(terms)) {
            terms = terms.split("\n");
            params['q[es_cell_marker_symbol_or_es_cell_name_or_colony_name_ci_in][]'] = terms;
        }

        return params;
    }
});

Ext.define('Imits.widget.grid.SimpleDateColumn', {
    extend: 'Ext.grid.column.Date',
    alias: 'widget.simpledatecolumn',

    format: 'd-m-Y',
    editor: {
        xtype: 'datefield',
        format: 'd-m-Y'
    },
    filter: {
        type: 'date'
    }
});

Ext.define('Imits.widget.SimpleNumberField', {
    extend: 'Ext.form.field.Number',
    alias: 'widget.simplenumberfield',
    minValue: 0,
    hideTrigger: true,
    keyNavEnabled: false,
    mouseWheelEnabled: false,
    allowDecimals: false
});

Ext.define('Imits.widget.QCCombo', {
    extend: 'Imits.widget.SimpleCombo',
    alias: 'widget.qccombo',
    store: window.MI_ATTEMPT_QC_OPTIONS
});

Ext.define('Imits.model.MiAttempt', {
    extend: 'Ext.data.Model',
    requires: ['Imits.data.Proxy'],

    fields: [
    {
        name: 'id',
        type: 'int',
        persist: false
    },
    {
        name: 'es_cell_name',
        persist: false
    },
    {
        name: 'es_cell_marker_symbol',
        persist: false
    },
    {
        name: 'es_cell_allele_symbol',
        persist: false
    },
    {
        name: 'mi_date',
        type: 'date'
    },
    {
        name: 'status_name',
        persist: false
    },
    'colony_name',
    {
        name: 'consortium_name',
        persist: false
    },
    {
        name: 'production_centre_name',
        persist: false
    },
    'distribution_centres_attributes',
    {
        name: 'pretty_print_distribution_centres',
        readOnly: true
    },
    'blast_strain_name',
    {
        name: 'total_blasts_injected',
        type: 'int'
    },
    {
        name: 'total_transferred',
        type: 'int'
    },
    {
        name: 'number_surrogates_receiving',
        type: 'int'
    },
    {
        name: 'total_pups_born',
        type: 'int'
    },
    {
        name: 'total_female_chimeras',
        type: 'int'
    },
    {
        name: 'total_male_chimeras',
        type: 'int'
    },
    {
        name: 'total_chimeras',
        type: 'int',
        persist: false
    },
    {
        name: 'number_of_males_with_0_to_39_percent_chimerism',
        type: 'int'
    },
    {
        name: 'number_of_males_with_40_to_79_percent_chimerism',
        type: 'int'
    },
    {
        name: 'number_of_males_with_80_to_99_percent_chimerism',
        type: 'int'
    },
    {
        name: 'number_of_males_with_100_percent_chimerism',
        type: 'int'
    },

    // Chimera Mating Details
    {
        name: 'emma_status'
    },
    {
        name: 'test_cross_strain_name'
    },
    {
        name: 'colony_background_strain_name'
    },
    {
        name: 'date_chimeras_mated',
        type: 'date'
    },
    {
        name: 'number_of_chimera_matings_attempted',
        type: 'int'
    },
    {
        name: 'number_of_chimera_matings_successful',
        type: 'int'
    },
    {
        name: 'number_of_chimeras_with_glt_from_cct',
        type: 'int'
    },
    {
        name: 'number_of_chimeras_with_glt_from_genotyping',
        type: 'int'
    },
    {
        name: 'number_of_chimeras_with_0_to_9_percent_glt',
        type: 'int'
    },
    {
        name: 'number_of_chimeras_with_10_to_49_percent_glt',
        type: 'int'
    },
    {
        name: 'number_of_chimeras_with_50_to_99_percent_glt',
        type: 'int'
    },
    {
        name: 'number_of_chimeras_with_100_percent_glt',
        type: 'int'
    },
    {
        name: 'total_f1_mice_from_matings',
        type: 'int'
    },
    {
        name: 'number_of_cct_offspring',
        type: 'int'
    },
    {
        name: 'number_of_het_offspring',
        type: 'int'
    },
    {
        name: 'number_of_live_glt_offspring',
        type: 'int'
    },
    {
        name: 'mouse_allele_type',
        readOnly: true
    },
    {
        name: 'mouse_allele_symbol',
        readOnly: true
    },

    // QC Details
    'qc_southern_blot_result',
    'qc_five_prime_lr_pcr_result',
    'qc_five_prime_cassette_integrity_result',
    'qc_tv_backbone_assay_result',
    'qc_neo_count_qpcr_result',
    'qc_neo_sr_pcr_result',
    'qc_loa_qpcr_result',
    'qc_homozygous_loa_sr_pcr_result',
    'qc_lacz_sr_pcr_result',
    'qc_mutant_specific_sr_pcr_result',
    'qc_loxp_confirmation_result',
    'qc_three_prime_lr_pcr_result',
    {
        name: 'report_to_public',
        type: 'boolean'
    },
    {
        name: 'is_active',
        type: 'boolean'
    },
    {
        name: 'is_released_from_genotyping',
        type: 'boolean'
    }
    ],

    proxy: Ext.create('Imits.data.Proxy', {
        resource: 'mi_attempt'
    })
});

function splitString(prettyPrintDistributionCentres) {
    var distributionCentres = [];
    Ext.Array.each(prettyPrintDistributionCentres.split(', '), function(dc) {
        distributionCentres.push({
            distributionCentre: dc
        });
    });

    return distributionCentres;
}

Ext.define('Imits.widget.MiGrid', {
    extend: 'Imits.widget.Grid',

    requires: [
    'Imits.model.MiAttempt',
    'Imits.widget.SimpleNumberField',
    'Imits.widget.SimpleCombo',
    'Imits.widget.QCCombo',
    'Imits.widget.grid.BoolGridColumn',
    'Imits.widget.grid.MiAttemptRansackFiltersFeature',
    'Imits.widget.grid.SimpleDateColumn'
    ],

    title: 'Micro-Injection Attempts',
    store: {
        model: 'Imits.model.MiAttempt',
        autoLoad: true,
        autoSync: true,
        remoteSort: true,
        pageSize: 20
    },

    selType: 'rowmodel',

    plugins: [
    Ext.create('Ext.grid.plugin.RowEditing', {
        autoCancel: false,
        clicksToEdit: 1
    })
    ],

    features: [
    {
        ftype: 'mi_attempt_ransack_filters',
        local: false
    }
    ],

    /** @private */
    generateColumns: function(config) {
        var columns = [];

        Ext.Object.each(this.groupedColumns, function(viewName, viewColumns) {
            Ext.Array.each(viewColumns, function(column) {
                var existing;
                Ext.each(columns, function(i) {
                    if(i.dataIndex == column.dataIndex && i.header == column.header) {
                        existing = i;
                    }
                });
                if(!existing) {
                    column.tdCls = 'column-' + column.dataIndex;
                    columns.push(column);
                }
            });
        });

        config.columns = columns;
    },

    /** @private */
    generateViews: function() {
        var views = {};

        var commonColumns = Ext.pluck(this.groupedColumns.common, 'dataIndex');
        var everythingView = Ext.Array.merge(commonColumns, []);

        // First generate the groups from the groupedColumns
        Ext.Object.each(this.groupedColumns, function(viewName, viewColumnConfigs) {
            if(viewName === 'common' || viewName === 'none') {
                return;
            }

            var viewColumns = Ext.pluck(viewColumnConfigs, 'dataIndex');
            views[viewName] = Ext.Array.merge(commonColumns, viewColumns);
            everythingView = Ext.Array.merge(everythingView, viewColumns);
        });

        views['Everything'] = everythingView;

        var grid = this;
        Ext.Object.each(this.additionalViewColumns, function(viewName) {
            views[viewName] = Ext.Array.merge(commonColumns, grid.additionalViewColumns[viewName]);
        });
        this.views = views;
    },

    constructor: function(config) {
        if(config == undefined) {
            config = {};
        }
        this.generateColumns(config);
        this.generateViews();
        this.callParent([config]);
    },

    switchViewButtonConfig: function(text, pressedByDefault) {
        var grid = this;
        return {
            text: text,
            enableToggle: true,
            allowDepress: false,
            toggleGroup: 'mi_grid_view_config',
            minWidth: 100,
            pressed: (pressedByDefault === true),
            listeners: {
                'toggle': function(button, pressed) {
                    if(!pressed) {
                        return;
                    }
                    function intensiveOperation() {
                        var columnsToShow = grid.views[text];
                        Ext.each(grid.columns, function(column) {
                            if(Ext.Array.indexOf(columnsToShow, column.dataIndex) == -1) {
                                column.setVisible(false);
                            } else {
                                column.setVisible(true);
                            }
                        });

                        mask.hide();
                        Ext.getBody().removeCls('wait');
                    }

                    var mask = new Ext.LoadMask(grid.getEl(),
                    {
                        msg: 'Please wait&hellip;',
                        removeMask: true
                    });

                    Ext.getBody().addCls('wait');
                    mask.show();
                    setTimeout(intensiveOperation, 100);
                }
            }
        };
    },

    initComponent: function() {
        this.callParent();

        this.addDocked(Ext.create('Ext.toolbar.Paging', {
            store: this.getStore(),
            dock: 'bottom',
            displayInfo: true
        }));

        this.addDocked(Ext.create('Ext.container.ButtonGroup', {
            layout: 'hbox',
            dock: 'top',
            items: [
            this.switchViewButtonConfig('Everything', true),
            this.switchViewButtonConfig('Transfer Details'),
            this.switchViewButtonConfig('Litter Details'),
            this.switchViewButtonConfig('Chimera Mating Details'),
            this.switchViewButtonConfig('QC Details'),
            this.switchViewButtonConfig('Summary')
            ]
        }));
    },

    // BEGIN COLUMN DEFINITION

    groupedColumns: {
        'none': [
        {
            dataIndex: 'id',
            header: 'ID',
            readOnly: true,
            hidden: true
        }
        ],
        'common': [
        {
            header: 'Edit In Form',
            dataIndex: 'edit_link',
            renderer: function(value, metaData, record) {
                var miId = record.getId();
                return Ext.String.format('<a href="{0}/mi_attempts/{1}">Edit in Form</a>', window.basePath, miId);
            },
            sortable: false
        },
        {
          header: 'Phenotype',
          dataIndex: 'phenotype_attempt_new_link',
          renderer: function(value, metaData, record){
            var miId = record.getId();
            var statusName = record.get('status_name');
            if (statusName == "Genotype confirmed") {
              return Ext.String.format('<a href="{0}/mi_attempts/{1}/phenotype_attempts/new">Create</a>', window.basePath, miId);
            } else {
              return Ext.String.format('', window.basePath, miId);
            }
          },
          sortable: false
        },
        {
            dataIndex: 'consortium_name',
            header: 'Consortium',
            readOnly: true,
            width: 115,
            filter: {
                type: 'list',
                options: window.MI_ATTEMPT_CONSORTIUM_OPTIONS
            },
            sortable: false
        },
        {
            dataIndex: 'production_centre_name',
            header: 'Production Centre',
            readOnly: true,
            filter: {
                type: 'list',
                options: window.MI_ATTEMPT_CENTRE_OPTIONS
            },
            sortable: false
        },
        {
            dataIndex: 'es_cell_name',
            header: 'ES Cell',
            readOnly: true,
            sortable: false,
            filter: {
                type: 'string'
            }
        },
        {
            dataIndex: 'es_cell_marker_symbol',
            header: 'Marker Symbol',
            width: 75,
            readOnly: true,
            sortable: false,
            filter: {
                type: 'string'
            }
        },
        {
            dataIndex: 'es_cell_allele_symbol',
            header: 'Allele symbol',
            readOnly: true,
            sortable: false
        },
        {
            xtype: 'simpledatecolumn',
            dataIndex: 'mi_date',
            header: 'MI Date'
        },
        {
            dataIndex: 'status_name',
            header: 'Status',
            width: 150,
            readOnly: true,
            sortable: false,
            filter: {
                type: 'list',
                options: window.MI_ATTEMPT_STATUS_OPTIONS
            }
        },
        {
            dataIndex: 'colony_name',
            header: 'Colony Name',
            editor: 'textfield',
            filter: {
                type: 'string'
            }
        },
        {
            dataIndex: 'pretty_print_distribution_centres',
            header: 'Distribution Centres',
            readOnly: true,
            width: 180,
            xtype: 'templatecolumn',
            tpl: new Ext.XTemplate(
                '<tpl for="this.processedDistributionCentres(pretty_print_distribution_centres)">',
                '<a href="' + window.basePath + '/mi_attempts/{parent.id}#distribution_centres" target="_blank">{distributionCentre}</a></br>',
                '</tpl>',
                {
                    processedDistributionCentres: splitString
                }
            )
        }
        ],

        'Transfer Details': [
        {
            dataIndex: 'blast_strain_name',
            header: 'Blast Strain',
            sortable: false,
            renderer: 'safeTextRenderer',
            width: 200,
            editor: {
                xtype: 'simplecombo',
                store: Ext.Array.merge([''], window.MI_ATTEMPT_STRAIN_OPTIONS),
                storeOptionsAreSpecial: true,
                listConfig: {
                    minWidth: 200
                }
            }
        },
        {
            dataIndex: 'total_blasts_injected',
            header: 'Total Blasts Injected',
            editor: 'simplenumberfield'
        },
        {
            dataIndex: 'total_transferred',
            header: 'Total Transferred',
            editor: 'simplenumberfield'
        },
        {
            dataIndex: 'number_surrogates_receiving',
            header: '# Surrogates Receiving',
            editor: 'simplenumberfield'
        }
        ],

        'Litter Details': [
        {
            dataIndex: 'total_pups_born',
            header: 'Total Pups Born',
            editor: 'simplenumberfield'
        },
        {
            dataIndex: 'total_female_chimeras',
            header: 'Total Female Chimeras',
            editor: 'simplenumberfield'
        },
        {
            dataIndex: 'total_male_chimeras',
            header: 'Total Male Chimeras',
            editor: 'simplenumberfield'
        },
        {
            dataIndex: 'total_chimeras',
            header: 'Total Chimeras',
            readOnly: true
        },
        {
            dataIndex: 'number_of_males_with_100_percent_chimerism',
            header: '100% Male Chimerism Levels',
            editor: 'simplenumberfield'
        },
        {
            dataIndex: 'number_of_males_with_80_to_99_percent_chimerism',
            header: '99-80% Male Chimerism Levels',
            editor: 'simplenumberfield'
        },
        {
            dataIndex: 'number_of_males_with_40_to_79_percent_chimerism',
            header: '79-40% Male Chimerism Levels',
            editor: 'simplenumberfield'
        },
        {
            dataIndex: 'number_of_males_with_0_to_39_percent_chimerism',
            header: '39-0% Male Chimerism Levels',
            editor: 'simplenumberfield'
        }
        ],
        'Chimera Mating Details': [
        {
            dataIndex: 'test_cross_strain_name',
            header: 'Test Cross Strain',
            readOnly: true,
            sortable: false,
            renderer: 'safeTextRenderer',
            width: 200,
            editor: {
                xtype: 'simplecombo',
                store: Ext.Array.merge([''], window.MI_ATTEMPT_STRAIN_OPTIONS),
                storeOptionsAreSpecial: true,
                listConfig: {
                    minWidth: 200
                }
            }
        },
        {
            dataIndex: 'colony_background_strain_name',
            header: 'Colony Background Strain',
            readOnly: true,
            sortable: false,
            renderer: 'safeTextRenderer',
            width: 200,
            editor: {
                xtype: 'simplecombo',
                store: Ext.Array.merge([''], window.MI_ATTEMPT_STRAIN_OPTIONS),
                storeOptionsAreSpecial: true,
                listConfig: {
                    minWidth: 200
                }
            }
        },
        {
            xtype: 'simpledatecolumn',
            dataIndex: 'date_chimeras_mated',
            header: 'Date Chimeras Mated'
        },
        {
            dataIndex: 'number_of_chimera_matings_attempted',
            header: '# Chimera Mating Attempted',
            editor: 'simplenumberfield'
        },
        {
            dataIndex: 'number_of_chimera_matings_successful',
            header: '# Chimera Matings Successful',
            editor: 'simplenumberfield'
        },
        {
            dataIndex: 'number_of_chimeras_with_glt_from_cct',
            header: '# Chimeras with Germline Transmission from CCT',
            editor: 'simplenumberfield'
        },
        {
            dataIndex: 'number_of_chimeras_with_glt_from_genotyping',
            header: 'No. Chimeras with Germline Transmission from Genotyping',
            editor: 'simplenumberfield'
        },
        {
            dataIndex: 'number_of_chimeras_with_0_to_9_percent_glt',
            header: '# Chimeras with 0-9% GLT',
            editor: 'simplenumberfield'
        },
        {
            dataIndex: 'number_of_chimeras_with_10_to_49_percent_glt',
            header: '# Chimeras with 10-49% GLT',
            editor: 'simplenumberfield'
        },
        {
            dataIndex: 'number_of_chimeras_with_50_to_99_percent_glt',
            header: 'No. Chimeras with 50-99% GLT',
            editor: 'simplenumberfield'
        },
        {
            dataIndex: 'number_of_chimeras_with_100_percent_glt',
            header: 'No. Chimeras with 100% GLT',
            editor: 'simplenumberfield'
        },
        {
            dataIndex: 'total_f1_mice_from_matings',
            header: 'Total F1 Mice from Matings',
            editor: 'simplenumberfield'
        },
        {
            dataIndex: 'number_of_cct_offspring',
            header: '# Coat Colour Transmission Offspring',
            editor: 'simplenumberfield'
        },
        {
            dataIndex: 'number_of_het_offspring',
            header: '# Het Offspring',
            editor: 'simplenumberfield'
        },
        {
            dataIndex: 'number_of_live_glt_offspring',
            header: '# Live GLT Offspring',
            editor: 'simplenumberfield'
        },
        {
            dataIndex: 'mouse_allele_type',
            header: 'Mouse Allele Type',
            editor: {
                xtype: 'simplecombo',
                store: window.MI_ATTEMPT_MOUSE_ALLELE_TYPE_OPTIONS,
                listConfig: {
                    minWidth: 300
                }
            }
        },
        {
            dataIndex: 'mouse_allele_symbol',
            header: 'Mouse Allele Symbol',
            readOnly: true
        }
        ],

        'QC Details': [
        {
            dataIndex: 'qc_southern_blot_result',
            header: 'Southern Blot',
            sortable: false,
            editor: 'qccombo'
        },
        {
            dataIndex: 'qc_five_prime_lr_pcr_result',
            header: 'Five Prime LR PCR',
            sortable: false,
            editor: 'qccombo'
        },
        {
            dataIndex: 'qc_five_prime_cassette_integrity_result',
            header: 'Five Prime Cassette Integrity',
            sortable: false,
            editor: 'qccombo'
        },
        {
            dataIndex: 'qc_tv_backbone_assay_result',
            header: 'TV Backbone Assay',
            sortable: false,
            editor: 'qccombo'
        },
        {
            dataIndex: 'qc_neo_count_qpcr_result',
            header: 'Neo Count QPCR',
            sortable: false,
            editor: 'qccombo'
        },
        {
            dataIndex: 'qc_neo_sr_pcr_result',
            header: 'Neo SR PCR',
            sortable: false,
            editor: 'qccombo'
        },
        {
            dataIndex: 'qc_loa_qpcr_result',
            header: 'LOA QPCR',
            sortable: false,
            editor: 'qccombo'
        },
        {
            dataIndex: 'qc_homozygous_loa_sr_pcr_result',
            header: 'Homozygous LOA SR PCR',
            sortable: false,
            editor: 'qccombo'
        },
        {
            dataIndex: 'qc_lacz_sr_pcr_result',
            header: 'LacZ SR PCR',
            sortable: false,
            editor: 'qccombo'
        },
        {
            dataIndex: 'qc_mutant_specific_sr_pcr_result',
            header: 'Mutant Specific SR PCR',
            sortable: false,
            editor: 'qccombo'
        },
        {
            dataIndex: 'qc_loxp_confirmation_result',
            header: 'LoxP Confirmation',
            sortable: false,
            editor: 'qccombo'
        },
        {
            dataIndex: 'qc_three_prime_lr_pcr_result',
            header: 'Three Prime LR PCR',
            sortable: false,
            editor: 'qccombo'
        },
        {
            dataIndex: 'report_to_public',
            header: 'Report to Public',
            xtype: 'boolgridcolumn'
        },
        {
            dataIndex: 'is_active',
            header: 'Active?',
            xtype: 'boolgridcolumn'
        },
        {
            dataIndex: 'is_released_from_genotyping',
            header: 'Released From Genotyping',
            xtype: 'boolgridcolumn'
        }
        ]
    },

    additionalViewColumns: {
        'Summary': [
        'emma_status',
        'mouse_allele_type',
        'mouse_allele_symbol'
        ]
    }
// END COLUMN DEFINITION - ALWAYS keep at bottom of file for easier organization

});

Ext.define('Imits.model.PhenotypeAttempt', {
    extend: 'Ext.data.Model',
    requires: ['Imits.data.Proxy'],

    fields: [
    {
        name: 'id',
        type: 'int',
        persist: false
    },
    {
        name: 'colony_name'
    },
    {
        name: 'consortium_name'
    },
    {
        name: 'production_centre_name'
    },
    'distribution_centres_attributes',
    {
        name: 'pretty_print_distribution_centres',
        readOnly: true
    },
    {
        name: 'mi_attempt_colony_name',
        readOnly: true,
        persist: false
    },
    {
        name: 'marker_symbol'
    },
    {
        name: 'is_active'
    },
    {
        name: 'status_name',
        persist: false,
        readOnly: true
    },
    {
        name: 'rederivation_started'
    },
    {
        name: 'rederivation_complete'
    },
    {
        name: 'deleter_strain_name'
    },
    {
        name: 'number_of_cre_matings_successful'
    },
    {
        name: 'phenotyping_started'
    },
    {
        name: 'phenotyping_complete'
    }
    ],

    proxy: Ext.create('Imits.data.Proxy', {
        resource: 'phenotype_attempt'
    })
});

function splitString(prettyPrintDistributionCentres) {
    var distributionCentres = [];
    Ext.Array.each(prettyPrintDistributionCentres.split(', '), function(dc) {
        distributionCentres.push({
            distributionCentre: dc
        });
    });

    return distributionCentres;
}

Ext.define('Imits.widget.PhenotypeAttemptsGrid', {
    extend: 'Imits.widget.Grid',

    requires: [
    'Imits.model.PhenotypeAttempt',
    'Imits.widget.SimpleNumberField',
    'Imits.widget.grid.PhenotypeAttemptRansackFiltersFeature',
    'Imits.widget.grid.BoolGridColumn'
    ],

    title: "Phenotype attempts",
    iconCls: 'icon-grid',
    columnLines: true,

    store: {
        model: 'Imits.model.PhenotypeAttempt',
        autoLoad: true,
        remoteSort: true,
        pageSize: 20
    },

    selType: 'rowmodel',

    features: [
    {
        ftype: 'phenotype_attempt_ransack_filters',
        local: false
    }
    ],

    initComponent: function () {
        var self = this;

        self.callParent();

        self.addDocked(Ext.create('Ext.toolbar.Paging', {
            store: self.getStore(),
            dock: 'bottom',
            displayInfo: true
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
        header: 'Edit In Form',
        dataIndex: 'edit_link',
        renderer: function(value, metaData, record) {
            var miId = record.getId();
            return Ext.String.format('<a href="{0}/phenotype_attempts/{1}">Edit in Form</a>', window.basePath, miId);
        },
        sortable: false
    },
    {
        dataIndex: 'colony_name',
        header: 'Colony Name',
        editor: 'textfield',
        filter: {
            type: 'string'
        }
    },
    {
        dataIndex: 'consortium_name',
        header: 'Consortium',
        readOnly: true,
        width: 115,
        filter: {
            type: 'list',
            options: window.PHENOTYPE_CONSORTIUM_OPTIONS
        }
    },
    {
        dataIndex: 'production_centre_name',
        header: 'Production Centre',
        readOnly: true,
        width: 150,
        filter: {
            type: 'list',
            options: window.PHENOTYPE_CENTRE_OPTIONS
        }
    },
    {
        dataIndex: 'pretty_print_distribution_centres',
        header: 'Distribution Centres',
        readOnly: true,
        width: 180,
        xtype: 'templatecolumn',
        tpl: new Ext.XTemplate(
                '<tpl for="this.processedDistributionCentres(pretty_print_distribution_centres)">',
                '<a href="' + window.basePath + '/phenotype_attempts/{parent.id}#distribution_centres" target="_blank">{distributionCentre}</a></br>',
                '</tpl>',
                {
                    processedDistributionCentres: splitString
                }
        )
    },
    {
        dataIndex: 'marker_symbol',
        header: 'Marker Symbol',
        readOnly: true,
        filter: {
            type: 'string'
        }
    },
    {
        dataIndex: 'is_active',
        header: 'Active?',
        readOnly: true,
        width: 55,
        xtype: 'boolgridcolumn',
        filter: {
            type: 'boolean'
        }
    },
    {
        dataIndex: 'status_name',
        header: 'Status',
        readOnly: true,
        filter: {
            type: 'list',
            options: window.PHENOTYPE_STATUS_OPTIONS
        }
    },
    {
        dataIndex: 'rederivation_started',
        header: 'Rederivation started',
        readOnly: true,
        xtype: 'boolgridcolumn',
        width: 115,
        filter: {
            type: 'boolean'
        }
    },
    {
        dataIndex: 'rederivation_complete',
        header: 'Rederivation complete',
        readOnly: true,
        xtype: 'boolgridcolumn',
        width: 120,
        filter: {
            type: 'boolean'
        }
    },
    {
        dataIndex: 'deleter_strain_name',
        header: 'Cre-deleter strain',
        readOnly: true,
        filter: {
            type: 'list',
            options: window.PHENOTYPE_DELETER_STRAIN_OPTIONS
        }
    },
    {
        dataIndex: 'number_of_cre_matings_successful',
        header: '# Cre Matings successful',
        readOnly: true,
        editor: 'simplenumberfield',
        width: 140
    },
    {
        dataIndex: 'phenotyping_started',
        header: 'Phenotyping Started',
        readOnly: true,
        xtype: 'boolgridcolumn',
        width: 115,
        filter: {
            type: 'boolean'
        }
    },
    {
        dataIndex: 'phenotyping_complete',
        header: 'Phenotyping Complete',
        readOnly: true,
        xtype: 'boolgridcolumn',
        width: 120,
        filter: {
            type: 'boolean'
        }
    }
    ]
});

Ext.define('Imits.model.Gene', {
    extend: 'Ext.data.Model',
    requires: ['Imits.data.Proxy'],

fields: [
    {
        name: 'id',
        type: 'int',
        readOnly: true
    },

    {
        name: 'marker_symbol',
        readOnly: true
    },

    {
        name: 'mgi_accession_id',
        readOnly: true
    },

    {
        name: 'ikmc_projects_count',
        readOnly: true
    },

    {
        name: 'pretty_print_types_of_cells_available',
        readOnly: true
    },

    {
        name: 'non_assigned_mi_plans',
        readOnly: true
    },

    {
        name: 'assigned_mi_plans',
        readOnly: true
    },

    {
        name: 'pretty_print_aborted_mi_attempts',
        readOnly: true
    },

    {
        name: 'pretty_print_mi_attempts_in_progress',
        readOnly: true
    },

    {
        name: 'pretty_print_mi_attempts_genotype_confirmed',
        readOnly: true
    },

    {
        name: 'pretty_print_phenotype_attempts',
        readOnly: true
    }

    ],
    proxy: Ext.create('Imits.data.Proxy', {
        resource: 'gene'
    })
});

/*

This file is part of Ext JS 4

Copyright (c) 2011 Sencha Inc

Contact:  http://www.sencha.com/contact

GNU General Public License Usage
This file may be used under the terms of the GNU General Public License version 3.0 as published by the Free Software Foundation and appearing in the file LICENSE included in the packaging of this file.  Please review the following information to ensure the GNU General Public License version 3.0 requirements will be met: http://www.gnu.org/copyleft/gpl.html.

If you are unsure which license is appropriate for your use, please contact the sales department at http://www.sencha.com/contact.

*/
// feature idea to enable Ajax loading and then the content
// cache would actually make sense. Should we dictate that they use
// data or support raw html as well?

/**
 * @class Ext.ux.RowExpander
 * @extends Ext.AbstractPlugin
 * Plugin (ptype = 'rowexpander') that adds the ability to have a Column in a grid which enables
 * a second row body which expands/contracts.  The expand/contract behavior is configurable to react
 * on clicking of the column, double click of the row, and/or hitting enter while a row is selected.
 *
 * @ptype rowexpander
 */
Ext.define('Ext.ux.RowExpander', {
    extend: 'Ext.AbstractPlugin',

    requires: [
        'Ext.grid.feature.RowBody',
        'Ext.grid.feature.RowWrap'
    ],

    alias: 'plugin.rowexpander',

    rowBodyTpl: null,

    /**
     * @cfg {Boolean} expandOnEnter
     * <tt>true</tt> to toggle selected row(s) between expanded/collapsed when the enter
     * key is pressed (defaults to <tt>true</tt>).
     */
    expandOnEnter: true,

    /**
     * @cfg {Boolean} expandOnDblClick
     * <tt>true</tt> to toggle a row between expanded/collapsed when double clicked
     * (defaults to <tt>true</tt>).
     */
    expandOnDblClick: true,

    /**
     * @cfg {Boolean} selectRowOnExpand
     * <tt>true</tt> to select a row when clicking on the expander icon
     * (defaults to <tt>false</tt>).
     */
    selectRowOnExpand: false,

    rowBodyTrSelector: '.x-grid-rowbody-tr',
    rowBodyHiddenCls: 'x-grid-row-body-hidden',
    rowCollapsedCls: 'x-grid-row-collapsed',



    renderer: function(value, metadata, record, rowIdx, colIdx) {
        if (colIdx === 0) {
            metadata.tdCls = 'x-grid-td-expander';
        }
        return '<div class="x-grid-row-expander">&#160;</div>';
    },

    /**
     * @event expandbody
     * <b<Fired through the grid's View</b>
     * @param {HtmlElement} rowNode The &lt;tr> element which owns the expanded row.
     * @param {Ext.data.Model} record The record providing the data.
     * @param {HtmlElement} expandRow The &lt;tr> element containing the expanded data.
     */
    /**
     * @event collapsebody
     * <b<Fired through the grid's View.</b>
     * @param {HtmlElement} rowNode The &lt;tr> element which owns the expanded row.
     * @param {Ext.data.Model} record The record providing the data.
     * @param {HtmlElement} expandRow The &lt;tr> element containing the expanded data.
     */

    constructor: function() {
        this.callParent(arguments);
        var grid = this.getCmp();
        this.recordsExpanded = {};
        // <debug>
        if (!this.rowBodyTpl) {
            Ext.Error.raise("The 'rowBodyTpl' config is required and is not defined.");
        }
        // </debug>
        // TODO: if XTemplate/Template receives a template as an arg, should
        // just return it back!
        var rowBodyTpl = Ext.create('Ext.XTemplate', this.rowBodyTpl),
            features = [{
                ftype: 'rowbody',
                columnId: this.getHeaderId(),
                recordsExpanded: this.recordsExpanded,
                rowBodyHiddenCls: this.rowBodyHiddenCls,
                rowCollapsedCls: this.rowCollapsedCls,
                getAdditionalData: this.getRowBodyFeatureData,
                getRowBodyContents: function(data) {
                    return rowBodyTpl.applyTemplate(data);
                }
            },{
                ftype: 'rowwrap'
            }];

        if (grid.features) {
            grid.features = features.concat(grid.features);
        } else {
            grid.features = features;
        }

        // NOTE: features have to be added before init (before Table.initComponent)
    },

    init: function(grid) {
        this.callParent(arguments);

        // Columns have to be added in init (after columns has been used to create the
        // headerCt). Otherwise, shared column configs get corrupted, e.g., if put in the
        // prototype.
        grid.headerCt.insert(0, this.getHeaderConfig());
        grid.on('render', this.bindView, this, {single: true});
    },

    getHeaderId: function() {
        if (!this.headerId) {
            this.headerId = Ext.id();
        }
        return this.headerId;
    },

    getRowBodyFeatureData: function(data, idx, record, orig) {
        var o = Ext.grid.feature.RowBody.prototype.getAdditionalData.apply(this, arguments),
            id = this.columnId;
        o.rowBodyColspan = o.rowBodyColspan - 1;
        o.rowBody = this.getRowBodyContents(data);
        o.rowCls = this.recordsExpanded[record.internalId] ? '' : this.rowCollapsedCls;
        o.rowBodyCls = this.recordsExpanded[record.internalId] ? '' : this.rowBodyHiddenCls;
        o[id + '-tdAttr'] = ' valign="top" rowspan="2" ';
        if (orig[id+'-tdAttr']) {
            o[id+'-tdAttr'] += orig[id+'-tdAttr'];
        }
        return o;
    },

    bindView: function() {
        var view = this.getCmp().getView(),
            viewEl;

        if (!view.rendered) {
            view.on('render', this.bindView, this, {single: true});
        } else {
            viewEl = view.getEl();
            if (this.expandOnEnter) {
                this.keyNav = Ext.create('Ext.KeyNav', viewEl, {
                    'enter' : this.onEnter,
                    scope: this
                });
            }
            if (this.expandOnDblClick) {
                view.on('itemdblclick', this.onDblClick, this);
            }
            this.view = view;
        }
    },

    onEnter: function(e) {
        var view = this.view,
            ds   = view.store,
            sm   = view.getSelectionModel(),
            sels = sm.getSelection(),
            ln   = sels.length,
            i = 0,
            rowIdx;

        for (; i < ln; i++) {
            rowIdx = ds.indexOf(sels[i]);
            this.toggleRow(rowIdx);
        }
    },

    toggleRow: function(rowIdx) {
        var rowNode = this.view.getNode(rowIdx),
            row = Ext.get(rowNode),
            nextBd = Ext.get(row).down(this.rowBodyTrSelector),
            record = this.view.getRecord(rowNode),
            grid = this.getCmp();

        if (row.hasCls(this.rowCollapsedCls)) {
            row.removeCls(this.rowCollapsedCls);
            nextBd.removeCls(this.rowBodyHiddenCls);
            this.recordsExpanded[record.internalId] = true;
            this.view.fireEvent('expandbody', rowNode, record, nextBd.dom);
        } else {
            row.addCls(this.rowCollapsedCls);
            nextBd.addCls(this.rowBodyHiddenCls);
            this.recordsExpanded[record.internalId] = false;
            this.view.fireEvent('collapsebody', rowNode, record, nextBd.dom);
        }


        // If Grid is auto-heighting itself, then perform a component layhout to accommodate the new height
        if (!grid.isFixedHeight()) {
            grid.doComponentLayout();
        }
        this.view.up('gridpanel').invalidateScroller();
    },

    onDblClick: function(view, cell, rowIdx, cellIndex, e) {

        this.toggleRow(rowIdx);
    },

    getHeaderConfig: function() {
        var me                = this,
            toggleRow         = Ext.Function.bind(me.toggleRow, me),
            selectRowOnExpand = me.selectRowOnExpand;

        return {
            id: this.getHeaderId(),
            width: 24,
            sortable: false,
            resizable: false,
            draggable: false,
            hideable: false,
            menuDisabled: true,
            cls: Ext.baseCSSPrefix + 'grid-header-special',
            renderer: function(value, metadata) {
                metadata.tdCls = Ext.baseCSSPrefix + 'grid-cell-special';

                return '<div class="' + Ext.baseCSSPrefix + 'grid-row-expander">&#160;</div>';
            },
            processEvent: function(type, view, cell, recordIndex, cellIndex, e) {
                if (type == "mousedown" && e.getTarget('.x-grid-row-expander')) {
                    var row = e.getTarget('.x-grid-row');
                    toggleRow(row);
                    return selectRowOnExpand;
                }
            }
        };
    }
});


// Helper functions for cell templates - see in the grid below...
function splitResultString(mi_string) {
    var mis = [];
    var pattern = /^\[(.+)\:(.+)\:(\d+)\]$/;
    Ext.Array.each(mi_string.split('<br/>'), function(mi) {
        var match = pattern.exec(mi);
        mis.push({
            consortium: match[1],
            production_centre: match[2],
            count: match[3]
        });
    });
    return mis;
}

function printMiPlanString(mi_plan) {
    var str = '[' + mi_plan['consortium'];
    if (!Ext.isEmpty(mi_plan['production_centre'])) {
        str = str + ':' + mi_plan['production_centre'];
    }
    if (!Ext.isEmpty(mi_plan['status_name'])) {
        str = str + ':' + mi_plan['status_name'];
    }
    str = str + ']';
    return str;
}

Ext.define('Imits.widget.GeneGrid', {
    extend: 'Imits.widget.Grid',
    requires: [
    'Imits.model.Gene',
    'Imits.widget.grid.RansackFiltersFeature',
    'Imits.widget.SimpleCombo',
    'Imits.widget.MiPlanEditor',
    'Ext.ux.RowExpander',
    'Ext.selection.CheckboxModel'
    ],
    title: 'Please Select the Genes You Would Like to Register Interest In*',
    iconCls: 'icon-grid',
    columnLines: true,
    store: {
        model: 'Imits.model.Gene',
        autoLoad: true,
        remoteSort: true,
        remoteFilter: true,
        pageSize: 20
    },
    selModel: Ext.create('Ext.selection.CheckboxModel'),
    features: [
    {
        ftype: 'ransack_filters',
        local: false
    }
    ],
    columns: [
    {
        header: 'Gene',
        dataIndex: 'marker_symbol',
        readOnly: true,
        renderer: function(symbol) {
            return Ext.String.format('<a href="http://www.knockoutmouse.org/martsearch/search?query={0}" target="_blank">{0}</a>', symbol);
        }
    },
    {
        header: '# IKMC Projects',
        dataIndex: 'ikmc_projects_count',
        readOnly: true
    },
    {
        header: '# Clones',
        dataIndex: 'pretty_print_types_of_cells_available',
        readOnly: true,
        sortable: false
    },
    {
        header: 'Non-Assigned Plans',
        dataIndex: 'non_assigned_mi_plans',
        readOnly: true,
        sortable: false,
        width: 250,
        flex: 1,
        xtype: 'templatecolumn',
        tpl: new Ext.XTemplate(
            '<tpl for="non_assigned_mi_plans">',
            '<a class="mi-plan" data-marker_symbol="{parent.marker_symbol}" data-id="{id}" data-string="{[this.prettyPrintMiPlan(values)]}" href="#">{[this.prettyPrintMiPlan(values)]}</a><br/>',
            '</tpl>',
            {
                prettyPrintMiPlan: printMiPlanString
            }
            )
    },
    {
        header: 'Assigned Plans',
        dataIndex: 'assigned_mi_plans',
        readOnly: true,
        sortable: false,
        width: 180,
        flex: 1,
        xtype: 'templatecolumn',
        tpl: new Ext.XTemplate(
            '<tpl for="assigned_mi_plans">',
            '<a class="mi-plan" data-marker_symbol="{parent.marker_symbol}" data-id="{id}" data-string="{[this.prettyPrintMiPlan(values)]}" href="#">{[this.prettyPrintMiPlan(values)]}</a><br/>',
            '</tpl>',
            {
                prettyPrintMiPlan: printMiPlanString
            }
            )
    },
    {
        header: 'Aborted MIs',
        dataIndex: 'pretty_print_aborted_mi_attempts',
        readOnly: true,
        sortable: false,
        width: 180,
        flex: 1,
        xtype: 'templatecolumn',
        tpl: new Ext.XTemplate(
            '<tpl for="this.processedMIs(pretty_print_aborted_mi_attempts)">',
            '<a href="' + window.basePath + '/mi_attempts?q[terms]={parent.marker_symbol}&q[production_centre_name]={production_centre}" target="_blank">[{consortium}:{production_centre}:{count}]</a></br>',
            '</tpl>',
            {
                processedMIs: splitResultString
            }
            )
    },
    {
        header: 'MIs in Progress',
        dataIndex: 'pretty_print_mi_attempts_in_progress',
        readOnly: true,
        sortable: false,
        width: 180,
        flex: 1,
        xtype: 'templatecolumn',
        tpl: new Ext.XTemplate(
            '<tpl for="this.processedMIs(pretty_print_mi_attempts_in_progress)">',
            '<a href="' + window.basePath + '/mi_attempts?q[terms]={parent.marker_symbol}&q[production_centre_name]={production_centre}" target="_blank">[{consortium}:{production_centre}:{count}]</a></br>',
            '</tpl>',
            {
                processedMIs: splitResultString
            }
            )
    },
    {
        header: 'Genotype Confirmed MIs',
        dataIndex: 'pretty_print_mi_attempts_genotype_confirmed',
        readOnly: true,
        sortable: false,
        width: 180,
        flex: 1,
        xtype: 'templatecolumn',
        tpl: new Ext.XTemplate(
            '<tpl for="this.processedMIs(pretty_print_mi_attempts_genotype_confirmed)">',
            '<a href="' + window.basePath + '/mi_attempts?q[terms]={parent.marker_symbol}&q[production_centre_name]={production_centre}" target="_blank">[{consortium}:{production_centre}:{count}]</a></br>',
            '</tpl>',
            {
                processedMIs: splitResultString
            }
            )
    },
    {
      header: 'Phenotype Attempts',
        dataIndex: 'pretty_print_phenotype_attempts',
        readOnly: true,
        sortable: false,
        width: 180,
        flex: 1,
        xtype: 'templatecolumn',
        tpl: new Ext.XTemplate(
            '<tpl for="this.processedMIs(pretty_print_phenotype_attempts)">',
            '<a href="' + window.basePath + '/phenotype_attempts?q[terms]={parent.marker_symbol}&q[production_centre_name]={production_centre}" target="_blank">[{consortium}:{production_centre}:{count}]</a></br>',
            '</tpl>',
            {
                processedMIs: splitResultString
            }
            )
    }
    ],

    /** @private **/
    createComboBox: function(id, label, labelWidth, store, includeBlank, isHidden) {
        if(includeBlank) {
            store = Ext.Array.merge([null], store);
        }
        return Ext.create('Imits.widget.SimpleCombo', {
            id: id + 'Combobox',
            store: store,
            fieldLabel: label,
            labelAlign: 'right',
            labelWidth: labelWidth,
            storeOptionsAreSpecial: true,
            hidden: isHidden
        });
    },

    registerInterestHandler: function() {
        var grid = this;
        var geneCounter = 0;
        var selectedGenes = grid.getSelectionModel().selected;
        var failedGenes = [];
        var consortiumName  = grid.consortiumCombo.getSubmitValue();
        var productionCentreName = grid.centreCombo.getSubmitValue();
        var subProjectName = grid.subprojectCombo.getSubmitValue();
        var priorityName = grid.priorityCombo.getSubmitValue();

        if(selectedGenes.length == 0) {
            alert('You must select some genes to register interest in');
            return;
        }
        if(consortiumName == null) {
            alert('You must select a consortium');
            return;
        }
        if(priorityName == null) {
            alert('You must selct a priority');
            return;
        }

        grid.setLoading(true);

        selectedGenes.each(function(geneRow) {
            var markerSymbol = geneRow.raw['marker_symbol'];
            var miPlan = Ext.create('Imits.model.MiPlan', {
                'marker_symbol': markerSymbol,
                'consortium_name': consortiumName,
                'production_centre_name': productionCentreName,
                'sub_project_name': subProjectName,
                'priority_name': priorityName
            });
            miPlan.save({
                failure: function() {
                    failedGenes.push(markerSymbol);
                },
                callback: function() {
                    geneCounter++;
                    if( geneCounter == selectedGenes.length ) {
                        if( !Ext.isEmpty(failedGenes) ) {
                            alert('An error occured trying to register interest on the following genes: ' + failedGenes.join(', ') + '. Please try again.');
                        }

                        grid.reloadStore();
                        grid.setLoading(false);
                    }
                }
            });
        });
    },

    initMiPlanEditor: function() {
        var grid = this;
        this.miPlanEditor = Ext.create('Imits.widget.MiPlanEditor', {
            listeners: {
                'hide': {
                    fn: function() {
                        grid.reloadStore();
                        grid.setLoading(false);
                    }
                }
            }
        });

        Ext.get(grid.renderTo).on('click', function(event, target) {
            var id = target.getAttribute('data-id');
            grid.setLoading("Editing gene interest....");
            grid.miPlanEditor.edit(id);
        },
        grid,
        {
            delegate: 'a.mi-plan'
        });
    },

    initComponent: function() {
        var grid = this;
        grid.callParent();

        // Add the bottom (pagination) toolbar
        grid.addDocked(Ext.create('Ext.toolbar.Paging', {
            store: grid.getStore(),
            dock: 'bottom',
            displayInfo: true
        }));

        var isSubProjectHidden = true;
        if(window.CAN_SEE_SUB_PROJECT) {
            isSubProjectHidden = false;
        }

        // Add the top (gene selection) toolbar
        grid.consortiumCombo = grid.createComboBox('consortium', 'Consortium', 65, window.CONSORTIUM_OPTIONS, false, false);
        grid.centreCombo     = grid.createComboBox('production_centre', 'Production Centre', 100, window.CENTRE_OPTIONS, true, false);
        grid.subprojectCombo = grid.createComboBox('sub_project', 'Sub Project', 65, window.SUB_PROJECT_OPTIONS, false, isSubProjectHidden);
        grid.priorityCombo   = grid.createComboBox('priority', 'Priority', 47, window.PRIORITY_OPTIONS, false, false);

        grid.addDocked(Ext.create('Ext.toolbar.Toolbar', {
            dock: 'top',
            items: [
            grid.consortiumCombo,
            grid.centreCombo,
            grid.subprojectCombo,
            grid.priorityCombo,
            '  ',
            {
                id: 'register_interest_button',
                text: 'Register Interest',
                cls:'x-btn-text-icon',
                iconCls: 'icon-add',
                grid: grid,
                handler: function() {
                    grid.registerInterestHandler();
                }
            }
            ]
        }));

        this.initMiPlanEditor();
    }
});
