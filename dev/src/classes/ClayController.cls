@RestResource(urlMapping='/clay-api/*')
global class  ClayController {
	
	@HttpGet
    global static string authenticate() {
		return getRouter(RestContext.request.params.get('action'), RestContext.request.params.get('app_name'), RestContext.request.params.get('dev_code'), RestContext.request.params.get('app_org') );
    }

	public static string getRouter(string action, string app_name, string dev_code, string app_org){
		if(action == 'GET_APP'){
			app__c app = getApp(app_name, dev_code, app_org, true);
			return JSON.serialize(app);
		}
		else if(action == 'GET_VERSION'){
			app__c app = getApp(app_name, dev_code, app_org, false);
			if(app == null){ return '{}'; }
			else{ return JSON.serialize(app); }
		}else{
			return JSON.serializePretty( getDev(dev_code) );
		}
	}

	@HttpPost
    global static string upsertApp(string app_name, string dev_code, integer version) {	
    	dev__c dev = getDev(dev_code);
    	app__c app = getApp(app_name, dev_code,null,false);
    	if(app == null){
    		app__c new_app = new App__c();
    		new_app.name = app_name;
    		new_app.version__c = version;
    		new_app.org__c= dev.org__c;
    		new_app.Version_History__c = dev.Name;
    		insert new_app;	
    		app = new_app;
    	}else{
    		app.version__c = version;
    		app.Version_History__c = dev.Name;
    		update app;
    	}
    
    	return JSON.serialize(app);
    }
    
    public static dev__c getDev(string dev_code){
    	if(dev_code == null || dev_code.length() == 0){
    		throw new ClayException(RemoteTKController.makeError('dev_code must be provided','AUTH_DENIED'));
    	}
    	 
    	List<dev__c> devs = [select id,Name, Org__r.Name, org__c, Email__c from dev__c where code__c = :dev_code];
    	
    	if(devs.size() ==0){
    		throw new ClayException(RemoteTKController.makeError('No registered developers found with code: ' + dev_code, 'AUTH_DENIED'));
    	}
    	return devs.get(0);
    }

    public static app__c getApp(string app_name, string dev_code, string app_org, boolean strict){
    	dev__c dev = getDev(dev_code);

		if(app_org == null){ app_org = dev.org__r.Name; }

    	List<app__c> apps = [select id, name, org__r.Name,version__c,opensource__c,  Version_History__c from app__c where name = :app_name and org__r.name = :app_org];
    	
    	if(apps.size() == 0 && strict == true){
    		throw new ClayException(RemoteTKController.makeError('App ' + app_name + ' not found in organization ' + dev.Org__r.Name, 'APP_NOT_FOUND' ));
    	}
    	if(apps.size() ==0){
    		return null; 
    	}
    	
    	app__c app = apps.get(0);
    	if(app.opensource__c == false && app.org__r.Name != dev.Org__r.Name){
    		throw new ClayException(RemoteTKController.makeError('This App ' + app_name + ' is not Open Source and you have not access to it\'s owner: '  + app_org +  ' from ' + dev.Org__r.Name, 'APP_NO_ACCESS' ));
    	}
    	
    	return app;
    	
    	
    }
}