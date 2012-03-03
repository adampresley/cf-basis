<!---
	Class: ajaxProxy
	This is an example AJAX proxy that has fake validation for a logged in user.
	In real life you would put in your own validation to ensure that the AJAX caller
	is valid in your system.
--->
<cfcomponent extends="Basis.AjaxProxy" output="false">
	
	<cffunction name="validateAccess" access="private" output="false">
		<cfif 1 NEQ 1>
			<cfthrow type="custom" message="You are an invalid user, and must be logged in." />
		</cfif>
	</cffunction>

</cfcomponent>
