<cfcomponent output="false" hint="Base object meant as a foundation for Application.cfc">

	<cfset variables.frameworkSettings = {
		dsn = "",
		reloadFrameworkEveryRequest = false,
		urlReloadVariableName = "reload",
		urlReloadPassword = "",
		urlReloadPasswordVariableName = "pw",
		useFriendlyUrls = true,
		removeIndexCfm = false,
		flushBufferBeforeOutput = true,

		defaultController = "main",
		defaultAction = "index",
		defaultLayoutName = "default",
		defaultPageTitle = "Home",

		controllerPath = "controllers",
		viewPath = "views",
		layoutPath = "layouts",
		modelPath = "model",
		pluginPath = "plugins",

		cacheModel = true
	} />

	<cfset variables.plugins = [] />


	<cffunction name="onApplicationStart" output="false">
		<cfset application.theFactory = createObject("component", "TheFactory").init(variables.frameworkSettings) />
		<cfset application.systemDelimiter = createObject("java", "java.lang.System").getProperty("file.separator").charAt(0) />
		<cfset __loadPlugins() />

		<cfset applicationStart() />
	</cffunction>
	
	<cffunction name="onApplicationEnd" output="false">
		<cfset applicationEnd() />
	</cffunction>

	<cffunction name="onRequestStart" output="false">
		<cfset var item = {} />

		<cfif variables.frameworkSettings.reloadFrameworkEveryRequest || structKeyExists(url, variables.frameworkSettings.urlReloadVariableName)>
			<cfif !len(variables.frameworkSettings.urlReloadPassword) || (len(variables.frameworkSettings.urlReloadPassword) && structKeyExists(url, variables.frameworkSettings.urlReloadPasswordVariableName) && variables.frameworkSettings.urlReloadPassword EQ url[variables.frameworkSettings.urlReloadPasswordVariableName])>
				<cfset onApplicationStart() />
			</cfif>
		</cfif>

		<cfif structKeyExists(url, variables.frameworkSettings.urlReloadVariableName)>
			<cfset onSessionStart() />
		</cfif>
		

		<!---
			The RC scope yo
		--->		
		<cfset request.rc = {} />
		<cfset structAppend(request.rc, url) />
		<cfset structAppend(request.rc, form) />

		<cfloop array="#variables.plugins#" index="item">
			<cfif item.scope EQ "request">
				<cfset request[item.referenceName] = item.cmp />
			</cfif>
		</cfloop>
	</cffunction>
	
	
	<cffunction name="onRequest" output="true">
		<cfargument name="targetPage" />

		<cfset var hdrs = getHTTPRequestData().headers />
		
		<cfparam name="request.context" default="#structNew()#" />
		<cfparam name="request.rc.action" default="#variables.frameworkSettings.defaultController#.#variables.frameworkSettings.defaultAction#" />
		<cfparam name="request.doLayout" default="true" />
		<cfparam name="request.layoutName" default="#variables.frameworkSettings.defaultLayoutName#" />
		<cfparam name="request.rc.title" default="#variables.frameworkSettings.defaultPageTitle#" />

		<cfset __parseRequest() />
		<cfset preRequest() />
		<cfset validateAccess() />
		
		<!---
			Parse browser-sent language and country information into the request context.
		--->
		<cfif structKeyExists(cgi, "http_accept_language")>
			<cfif listLen(cgi.http_accept_language) GT 0>
				<cfset request.context.browserLanguage = listGetAt(listGetAt(cgi.http_accept_language, 1), 1, "-") />
				<cfset request.context.browserCountry = listGetAt(listGetAt(cgi.http_accept_language, 1), 2, "-") />
			</cfif>
		</cfif>


		<!---
			Direct references to CFCs will be ignored. AJAX requests that send a header
			named X-Requested-With with a value of XMLHttpRequest will not render a layout.
		--->
		<cfif !arguments.targetPage CONTAINS ".cfc">
			<cfif structKeyExists(hdrs,'X-Requested-With') && hdrs['X-Requested-With'] EQ "XMLHttpRequest">
				<cfsetting showdebugoutput="false" />
				<cfset request.doLayout = false />
				<cfset request.context.ajaxRequest = true />
			
			<cfelse>
				<cfset request.context.ajaxRequest = false />
			</cfif>
			
			<cfset __buildOutput() />
		</cfif>

		<cfset postRequest() />
	</cffunction>


	<cffunction name="onSessionStart" output="false">
		<cfset var item = {} />

		<cfloop array="#variables.plugins#" index="item">
			<cfif item.scope EQ "session">
				<cfset session[item.referenceName] = item.cmp />
			</cfif>
		</cfloop>

		<cfset sessionStart() />
	</cffunction>

	<cffunction name="onSessionEnd" output="false">
		<cfset sessionEnd() />
	</cffunction>

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
			<cfif !variables.frameworkSettings.removeIndexCfm>
				<cfset action &= "index.cfm/" />
			</cfif>
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


	<cffunction name="__parseRequest" access="private" output="false">
		<cfset var pathInfo = cgi.path_info />
		<cfset var breakdown = [] />
		<cfset var index = 0 />

		<cfset var defaultAction = "#variables.frameworkSettings.defaultController#.#variables.frameworkSettings.defaultAction#" />

		<cfif !variables.frameworkSettings.useFriendlyUrls>
			<cfif structKeyExists(url, "action")>
				<cfset request.rc.action = url.action />
			<cfelse>
				<cfset request.rc.action = defaultAction />
			</cfif>

		<cfelse>
			<!---
				Get the URL breakdown
			--->
			<cfif pathInfo NEQ "/" && pathInfo NEQ "">
				<cfif left(pathInfo, 1) EQ "/">
					<cfset pathInfo = right(pathInfo, len(pathInfo) - 1) />
				</cfif>

				<cfset breakdown = pathInfo.trim().split("/") />

				<cfif arrayLen(breakdown) LT 2>
					<cfset arrayAppend(breakdown, variables.frameworkSettings.defaultAction) />
				</cfif>
				
				<cfset request.rc.action = "#breakdown[1]#.#breakdown[2]#" />

				<!---
					Get any remaining variables.
				--->
				<cfif len(breakdown) GT 2>
					<cfloop from="3" to="#arrayLen(breakdown)#" index="index" step="2">
						<cfif arrayLen(breakdown) GTE (index + 1)>
							<cfset request.rc[breakdown[index]] = breakdown[index + 1] />
						<cfelse>
							<cfset request.rc[breakdown[index]] = "" />
						</cfif>
					</cfloop>
				</cfif>

			<cfelse>
				<cfset request.rc.action = defaultAction />
			</cfif>
		</cfif>

		<cfset request.context.section = listGetAt(request.rc.action, 1, ".") />
		<cfset request.context.method = listGetAt(request.rc.action, 2, ".") />

		<cfif variables.frameworkSettings.useFriendlyUrls>
			<cfset request.context.varDelimiter = "/" />
			<cfset request.context.kvpDelimiter = "/" />
		<cfelse>
			<cfset request.context.varDelimiter = "&" />
			<cfset request.context.kvpDelimiter = "=" />
		</cfif>
	</cffunction>


	<cffunction name="validateAccess" access="private" output="false">
		<!---
			Override this method to provide custom access validation.
		--->	
	</cffunction>


	<cffunction name="applicationStart" output="false">
		<!---
			Override this method to provide custom application handling on application start
		--->	
	</cffunction>

	<cffunction name="applicationEnd" output="false">
		<!---
			Override this method to provide custom application handling on application end
		--->	
	</cffunction>

	<cffunction name="preRequest" output="false">
		<!---
			Override this method to provide custom request handling before access.
		--->	
	</cffunction>

	<cffunction name="postRequest" output="false">
		<!---
			Override this method to provide custom request handling at the end of the request cycle.
		--->	
	</cffunction>

	<cffunction name="sessionStart" output="false">
		<!---
			Override this method to provide custom session handling on session start
		--->	
	</cffunction>

	<cffunction name="sessionEnd" output="false">
		<!---
			Override this method to provide custom session handling on session end
		--->	
	</cffunction>

	<cffunction name="__buildOutput" access="private" output="true">
		<cfset var body = "" />
		<cfset var instance = "" />
		<cfset var rc = request.rc />
		
		<cfinvoke component="#variables.frameworkSettings.controllerPath#.#request.context.section#" method="init" returnvariable="instance" rc="#request.rc#" buildUrl="#buildUrl#" frameworkSettings="#variables.frameworkSettings#">
		
		<cfif !structKeyExists(instance, request.context.method)>
			<cfthrow type="InvalidAction" message="Invalid action" detail="The requested action #rc.action# is invalid." />
		</cfif>
		
		<cfinvoke component="#instance#" method="#request.context.method#">
		
 		<cfsavecontent variable="body"><cfoutput><cfinclude template="/#variables.frameworkSettings.viewPath#/#lCase(request.context.section)#/#lCase(request.context.method)#.cfm" /></cfoutput></cfsavecontent>
		<cfif request.doLayout>
			<cfif variables.frameworkSettings.flushBufferBeforeOutput><cfset getPageContext().getOut().clear() /></cfif>
			<cfinclude template="/#variables.frameworkSettings.layoutPath#/#request.layoutName#.cfm" />
		</cfif>
	</cffunction>


	<cffunction name="__loadPlugins" output="false">
		<cfset var qryDirs = "" />
		<cfset var holdMe = {} />
		<cfset var numPaths = 0 />
		<cfset var pluginPathPos = 0 />
		<cfset var index = 0 />
		<cfset var pathPrefix = "" />

		<cfif directoryExists(expandPath("/#variables.frameworkSettings.pluginPath#"))>
			<cfdirectory action="list" directory="#expandPath("/#variables.frameworkSettings.pluginPath#")#" name="qryDirs" filter="*.cfc" recurse="true" />

			<cfloop query="qryDirs">
				<cfset pluginPathPos = listFindNoCase(qryDirs.directory, variables.frameworkSettings.pluginPath, application.systemDelimiter) />
				<cfset numPaths = listLen(qryDirs.directory, application.systemDelimiter) - pluginPathPos />
		
				<cfset pathPrefix = variables.frameworkSettings.pluginPath />
				<cfif numPaths GT 0>
					<cfloop from="1" to="#numPaths#" index="index">
						<cfset pathPrefix &= ".#listGetAt(qryDirs.directory, index + pluginPathPos, application.systemDelimiter)#" />
					</cfloop>
				</cfif>
				
				<cfset holdMe = {
					cmp = createObject("component", "#pathPrefix#.#listDeleteAt(qryDirs.name, listLen(qryDirs.name, '.'), '.')#").init(
						frameworkSettings = duplicate(variables.frameworkSettings)
					)
				} />

				<cfset structAppend(holdMe, {
					name = holdMe.cmp.name,
					scope = holdMe.cmp.scope,
					referenceName = holdMe.cmp.referenceName
				}) />

				<cfif holdMe.cmp.scope EQ "application">
					<cfset application[holdMe.cmp.referenceName] = holdMe.cmp />
				</cfif>

				<cfset arrayAppend(variables.plugins, holdMe) />
			</cfloop>
		</cfif>
	</cffunction>

</cfcomponent>
