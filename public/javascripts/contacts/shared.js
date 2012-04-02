function  checkEmail() {
  Ext.Ajax.on('beforerequest', this.showLoader);
  Ext.Ajax.on('requestcomplete', this.hideLoader);

  Ext.Ajax.request({
    url: '/contact/check_email',
    method: 'GET',
    params: {
      name: Ext.fly('email').getValue()
    },
    success: function(response, opts) {
      Ext.fly('response-message').update(response.responseText);
    },
    failure: function(response, opts) {
      Ext.fly('response-message').update('Something went wrong...');
    }
  });
}

function showLoader() {
  Ext.fly('response-message').update('');
  Ext.fly('loading-message').show();
}

function hideLoader() {
  Ext.fly('loading-message').hide();
}
