trigger ContactTrigger on Contact (before insert, after insert, before update, after update) {
    
    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            for (Contact con : Trigger.new) {
                if (con.Email == null || con.Email == '') {
                    con.Email = 'noemail@domain.com';
                }
            }
        }
        
        if (Trigger.isUpdate) {
            for (Contact con : Trigger.new) {
                if (con.Email == null || con.Email == '') {
                    con.Email = 'noemail@domain.com';
                }
            }
        }
    }
    
    if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            // After insert logic
            List<Opportunity> oppsToUpdate = new List<Opportunity>();
            for (Contact con : Trigger.new) {
                Opportunity opp = [SELECT Id, Name FROM Opportunity WHERE Id = :con.AccountId LIMIT 1];
                if (opp != null) {
                    opp.Name += ' - Contact Added';
                    oppsToUpdate.add(opp);
                }
            }
            update oppsToUpdate;
            
            for (Contact c : Trigger.new) {
                for (Account a : [SELECT Id FROM Account WHERE Id = :c.AccountId]) {
                    Http http = new Http();
                    HttpRequest request = new HttpRequest();
                    request.setEndpoint('https://th-apex-http-callout.herokuapp.com/myEndpoint');
                    request.setMethod('POST');
                    request.setHeader('Content-Type', 'application/json; charset=UTF-8');
                    request.setBody('{"name":"' + a.Name + '", "email":"' + c.Email + '"}');
                    HttpResponse response = http.send(request);
                    if (response.getStatusCode() != 201) {
                        System.debug('The status code returned was not expected: ' + response.getStatusCode() + ' ' + response.getStatus());
                    } else {
                        SendEmailClass.notifyAccountManagersByEmail(a);
                    }
                }
            }
        }
    }
}