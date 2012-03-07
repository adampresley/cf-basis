<cfcomponent extends="Service" output="false">
	
	<cfset variables.frameworkSettings = {} />

	<cfset this.name = "Plugin name" />
	<cfset this.scope = "application" />
	<cfset this.referenceName = "plugin" />


	<cffunction name="init" output="false">
		<cfargument name="frameworkSettings" type="struct" required="true" />

		<cfset initPlugin() />
		<cfreturn super.init(argumentCollection = arguments) />
	</cffunction>

	<cffunction name="initPlugin" output="false">
		<cfthrow message="Invalid Basis plugin" detail="This plugin is invalid. Basis plugins must override the initPlugin() method and provide the following: name, scope, and referenceName" />
	</cffunction>

</cfcomponent>