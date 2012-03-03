<cfcomponent extends="Object" output="false">
	
	<cffunction name="init" output="false">
		<cfargument name="dsn" type="string" required="true" />
		
		<cfset this = super.init(argumentCollection = arguments) />
		<cfreturn this />
	</cffunction>
	
</cfcomponent>