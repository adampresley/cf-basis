<cfcomponent extends="Basis.Service" output="false">

	<cffunction name="process" output="false">
		<!---
			This is a test AJAX method handler. It lives in the folder 
			named "main", and is called "test.cfc". That means the 
			action "main.test" will route to here.
		--->
		<cfreturn {
			firstName: "Bob",
			lastName: "Bobes"
		} />
	</cffunction>

</cfcomponent>