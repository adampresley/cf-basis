<cfcomponent>

	<cfset variables.__cache = {} />
	<cfset variables.__frameworkSettings = {} />


	<cffunction name="init" output="false">
		<cfargument name="frameworkSettings" type="struct" required="true" />
		
		<cfset variables.__cache = { service = {}, dao = {} } />
		<cfset variables.__frameworkSettings = arguments.frameworkSettings />
		<cfreturn this />
	</cffunction>


	<!---
		Function: getService
		Returns an instance of a service component.

		Parameters:
			name - The name of the service object to retreive
			args - Additional arguments to pass to this service's constructor

		Returns:
			An instance of the requested service object
	--->
	<cffunction name="getService" output="false">
		<cfargument name="name" type="string" required="true" />
		<cfargument name="args" default="#structNew()#" />

		<cfreturn __loadObject("Service", arguments.name, arguments.args) />		
	</cffunction>


	<!---
		Function: getDAO
		Returns an instance of a DAO component.

		Parameters:
			name - The name of the DAO object to retreive
			args - Additional arguments to pass to this DAO's constructor

		Returns:
			An instance of the requested DAO object
	--->
	<cffunction name="getDAO" output="false">
		<cfargument name="name" type="string" required="true" />
		<cfargument name="args" default="#structNew()#" />

		<cfset arguments.args.dsn = variables.__frameworkSettings.dsn />
		<cfreturn __loadObject("DAO", arguments.name, arguments.args) />
	</cffunction>


	<!---
		Function: getLog4j
		Returns an instance of the server logger. This is fairly OpenBD specific, 
		as they use Apache Commons logger. Adobe CF has Log4J.

		Returns:
			An instance of the log4j object
	--->
	<cffunction name="getLog4j" access="public" output="false">
		<cfreturn createObject("java", "org.apache.commons.logging.LogFactory").getLog("") />
	</cffunction>


	<!---
		Function: __loadObject
		Returns an instance of a singleton bean/object. This is used for loading
		and caching services.

		Parameters:
			type - The type of object to load: Service, DAO
			name - The name of the object to load
			args - Additional arguments to pass to this object's constructor

		Returns:
			An instance of the requested object
	--->
	<cffunction name="__loadObject" access="private" output="false">
		<cfargument name="type" type="string" required="true" />
		<cfargument name="name" type="string" required="true" />
		<cfargument name="args" default="#structNew()#" />
		
		<cfset var result = "" />
		<cfset var finalPath = "#variables.__frameworkSettings.modelPath#.#arguments.name#.#arguments.name##arguments.type#" />

		<cfif variables.__frameworkSettings.cacheModel && !structKeyExists(variables.__cache.service, arguments.name)>
			<cfset variables.__cache.service[arguments.name] = createObject("component", finalPath).init(
				argumentCollection = arguments.args
			) />
			<cfset result = variables.__cache.service[arguments.name] />

		<cfelse>
			<cfset result = createObject("component", finalPath).init(
				argumentCollection = arguments.args
			) />
		</cfif>

		<cfreturn result />
	</cffunction>

</cfcomponent>

