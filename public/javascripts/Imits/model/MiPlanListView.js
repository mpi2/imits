Ext.define('MiPlanListViewModel', {
    extend: 'Ext.data.Model',
    fields: ['id', 'consortium_name', 'production_centre_name', 'sub_project_name', 'is_conditional_allele', 'is_deletion_allele', 'is_cre_knock_in_allele', 'is_cre_bac_allele', 'is_active']
});