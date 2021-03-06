class UrlMappings {

	static mappings = {
        "/$controller/$action?/$id?(.$format)?"{
            constraints {
                // apply constraints here
            }
        }

        "/ws/image/$id?(.$format)?"(controller: "webService", action: "getImageInfo")
        "/ws/updateMetadata/$imageIdentifier"(controller: "webService", action: "updateMetadata")

        "/ws/$action?/$id?(.$format)?" {
            controller = "webService"
        }

        "/"(controller:'image', action:'list')
        "500"(view:'/error')
	}
}
