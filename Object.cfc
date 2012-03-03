<cfcomponent output="false">
	
	<cffunction name="init" output="false">
		<cfset structAppend(variables, arguments) />
		<cfreturn this />
	</cffunction>

</cfcomponent>