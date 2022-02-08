import { LightningElement, api } from 'lwc';
import sendEnvelope from '@salesforce/apex/CleverButtonController.sendEnvelope';
import getDocuSignTemplates from '@salesforce/apex/CleverButtonController.getDocuSignTemplates';

export default class CleverButton extends LightningElement {
    @api recordId;              //  Opportunity ID    
    @api objectApiName;         //  'Opportunity'
    
    options = [];
    value = '';

    isLoading = false;
    error = false;
    errorMessage = "";

    sent = false;
    sentMessage = "";

    //  Populate combobox with templates
    connectedCallback() {
        getDocuSignTemplates()
            .then(result => {
                for (var i = 0; i < result.length; i++) {
                    this.options.push({ label: result[i].name, value: result[i].id.value });
                }
                this.options = JSON.parse(JSON.stringify(this.options));        //  @track property rerenders when the value changes
            })
            .catch(error => {
                console.log(JSON.stringify(error));
            });
    }

    //  Update template ID
    handleChange(event) {
        this.value = event.detail.value;
    }

    handleClick() {
        this.isLoading = true;

        sendEnvelope({ recordId: '8004W00001YOwXUPB1', template: this.value, description: 'Template' })
            .then((envelopeId => {
                this.sent = true;
                this.sentMessage = "Envelope " + envelopeId + " successfully been sent.";
                this.isLoading = false;
            }))
            .catch( error => {
                console.log(error);
                this.error = true;
                this.errorMessage = "Envelope error. Contact Admin";
                this.isLoading = false;
            })
    }
}

