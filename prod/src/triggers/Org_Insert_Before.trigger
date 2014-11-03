trigger Org_Insert_Before on Org__c (before insert) {

	list<org__c> orgs = [select id, name from org__c];

	for(org__c org : Trigger.new){
		
		for(org__c orgs_org : orgs){
			if(org.name == orgs_org.name ){				
				throw new ClayException('Org Name must be unique');
			}
		}
		
	}

}