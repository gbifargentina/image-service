modules = {

    ala {
        dependsOn 'bootstrap'
        resource url: grailsApplication.config.headerAndFooter.baseURL + '/css/font-awesome.min.css', attrs:[media:'all']
        resource url: grailsApplication.config.headerAndFooter.baseURL + '/css/roboto-fontface.css', attrs:[media:'all']
        resource url: grailsApplication.config.headerAndFooter.baseURL + '/css/poncho.css', attrs:[media:'all']
    }

    bootstrap {
        dependsOn 'core' //, 'font-awesome'
        resource url: grailsApplication.config.headerAndFooter.baseURL + '/css/bootstrap.min.css', attrs:[media:'all']
        resource url: grailsApplication.config.headerAndFooter.baseURL + '/css/bootstrap-responsive.min.css', attrs:[media:'all']
        resource url: grailsApplication.config.headerAndFooter.baseURL + '/js/bootstrap.js'
    }

    core {
        dependsOn 'jquery', 'autocomplete'
        resource url:[plugin: 'ala-bootstrap2', dir: 'js',file:'html5.js'], wrapper: { s -> "<!--[if lt IE 9]>$s<![endif]-->" }
        resource url: grailsApplication.config.headerAndFooter.baseURL + '/js/application.js'
    }

    autocomplete {
        // This is a legacy component that do not work with latest versions of jQuery (1.11+, maybe others)
        dependsOn 'jquery-migration'
        // Important note!!: To use this component along side jQuery UI, you need to download a custom jQuery UI compilation that
        // do not include the autocomplete widget
        resource url:[plugin: 'ala-bootstrap2', dir: 'css',file:'jquery.autocomplete.css'], attrs:[media:'all']
        resource url:[plugin: 'ala-bootstrap2', dir: 'js',file:'jquery.autocomplete.js']
    }

    'jquery-migration' {
        // Needed to support legacy js components that do not work with latest versions of jQuery
        dependsOn 'jquery'
        resource url:[plugin: 'ala-bootstrap2', dir: 'js', file:'jquery-migrate-1.2.1.min.js']
    }

//    'font-awesome' {
//
//    }

}