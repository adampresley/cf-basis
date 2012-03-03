<cfcomponent extends="Service" output="false">
	
	<cfset this.name = "Plugin name" />
	<cfset this.scope = "application" />
	<cfset this.referenceName = "plugin" />


	<cffunction name="init" output="false">
		<cfset initPlugin() />
		<cfreturn super.init(argumentCollection = arguments) />
	</cffunction>


	<cffunction name="initPlugin" output="false">
		
	</cffunction>

</cfcomponent>