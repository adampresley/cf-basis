<cfcomponent extends="Object" output="false">
	
	<cffunction name="redirect" output="false">
		<cfargument name="action" required="true" />
		<cfargument name="params" default="" />

		<cflocation url="#buildUrl(action, params)#" />
	</cffunction>

</cfcomponent>

