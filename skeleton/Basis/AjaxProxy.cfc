<!---
	Class: AjaxProxy
	Controller used for AJAX interactions in the system. Essentially all AJAX
	calls in your application should come through this controller and it's
	process() method.

	When a call is passed here it first will defer to the validateAccess method.
	Here is where you can ensure that the caller is authorized or logged in if 
	your application requires. After this it must pass action
	validation. All calls pass in the requested action. This action is validated
	to ensure it properly maps to a class in the "ajax" folder.

	If all ends well the correct class is instantiated, and the process() method
	on the target class is executed. The result from this call is sent back as
	JSON encoded data.
--->
<cfcomponent extends="Service" output="false">
	<cfsetting showdebugoutput="false" />
	
	<!---
		Function: process
		This is the main entry point for all AJAX calls. See the description for
		this class on how the AJAX proxy process works.

		Author:
			Adam Presley
	--->
	<cffunction name="process" access="remote" output="true">
		<cfset var rc = request.rc />
		<cfset var result = {} />
		<cfset var processResult = {} />
		<cfset var instance = {} />
		<cfset var logger = "" />
		
		<cfset init() />

		<cftry>
			<cfset validateAccess() />
			<cfset result = __validateAction() />

		<cfcatch type="any">
			<cfset result.success = false />
			<cfset result.message = cfcatch.message />
		</cfcatch>
		</cftry>
		
		<cfif result.success>
			
			<cftry>
				<cfinvoke component="#result.componentPath#" method="init" returnvariable="instance" rc="#request.rc#" />
				<cfset processResult = instance.process() />
				
				<cfset result =  processResult />
			
			<cfcatch type="any">
				<cfset result = {
					success = false,
					message = cfcatch.message
				} />

				<!--- 
					Call any custom error handling
				--->
				<cfset structAppend(result, onAjaxError(cfcatch)) />
			</cfcatch>
			</cftry>
			
		</cfif>
		<cfif isQuery(result)>
			<cfoutput>#serializeJson(result,true)#</cfoutput>
		<cfelse>
			<cfoutput>#serializeJson(result)#</cfoutput>
		</cfif>
	</cffunction>


	<!---
		Function: validateAccess
		This method is intended to be overridden. It is here you should
		do something like validate that there is a logged in user, for example.
		If the validation fails you need to throw an exception.
	--->
	<cffunction name="validateAccess" access="private" output="false">
			
	</cffunction>	
	

	<!---
		Function: onAjaxError
		Called in the event there is an error while processing the AJAX request.
		Override this in your version of AjaxProxy.cfc.
	--->
	<cffunction name="onAjaxError" access="private" output="false">
		<cfargument name="errorInfo" />

	</cffunction>


	<cffunction name="__validateAction" access="private" output="false">
		<cfset var rc = request.rc />
		<cfset var result = {
			success = true,
			message = ""
		} />
		
		<cfset var section = "" />
		<cfset var method = "" />
		<cfset var fullPath = "" />
		<cfset var filename = "" />
		
		<cftry>
			<cfif NOT structKeyExists(rc, "action") OR listLen(rc.action, ".") LT 2>
				<cfthrow type="custom" message="An action is required for AJAX processes." />
			</cfif>
		
			<cfset section = listGetAt(rc.action, 1, ".") />
			<cfset method = listGetAt(rc.action, 2, ".") />
			<cfset fullPath = "#section#" />
			<cfset filename = "#method#.cfc" />
			
			<cfif !fileExists("#expandPath('/')#/ajax/#fullPath#/#filename#")>
				<cfthrow type="custom" message="The action #rc.action# is invalid." />
			</cfif>
			
			<cfset result.fullPath = fullPath />
			<cfset result.method = method />
			<cfset result.componentPath = "ajax.#section#.#method#" />
			
		<cfcatch type="any">
			<cfset result = {
				success = false,
				message = cfcatch.message
			} />
		</cfcatch>
		</cftry>
		
		<cfreturn result />
	</cffunction>
	
</cfcomponent>

