<cffunction name="buildUrl" output="false">
	<cfargument name="path" type="string" required="true" />
	<cfargument name="params" type="struct" requried="false" default="#structNew()#" />
	
	<cfset var temp = arguments.path />
	<cfset var defaultAction = "#variables.frameworkSettings.defaultController#.#variables.frameworkSettings.defaultAction#" />
	<cfset var breakdown = [] />
	<cfset var action = "/" />

	<cfif listLen(arguments.path, ".") LT 2>
		<cfif listLen(arguments.path, ".") LT 1>
			<cfset temp &= defaultAction />
		<cfelse>
			<cfset temp &= ".#variables.frameworkSettings.defaultAction#" />
		</cfif>
	</cfif>
	
	<cfif variables.frameworkSettings.useFriendlyUrls>
		<cfset action &= "#listGetAt(temp, 1, '.')#/#listGetAt(temp, 2, '.')#" />
	<cfelse>
		<cfset action &= "?action=#temp#" />
	</cfif>
	
	<cfif structCount(arguments.params)>
		<cfset action &= request.context.varDelimiter />

		<cfloop collection="#arguments.params#" item="temp">
			<cfset action &= temp />
			<cfset action &= request.context.kvpDelimiter />
			<cfset action &= arguments.params[temp] />
		</cfloop>
	</cfif>

	<cfreturn action />
</cffunction>
