Ext.namespace('Imits.PhenotypeAttempts.New');

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
