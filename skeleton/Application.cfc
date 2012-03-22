<cfcomponent extends="Basis.App" output="false">
	
	<cfset this.name = "skeleton" />
	<cfset this.applicationTimeout = createTimeSpan(0, 2, 0, 0) />
	<cfset this.clientManagement = false />
	<cfset this.sessionManagement = true />
	<cfset this.sessionTimeout = createTimeSpan(0, 1, 0, 0) />
	
	<cffunction name="applicationStart" output="false">
		<cfset application.dsn = "" />
	</cffunction>

	<cfset variables.frameworkSettings.reloadFrameworkEveryRequest = true />

</cfcomponent>