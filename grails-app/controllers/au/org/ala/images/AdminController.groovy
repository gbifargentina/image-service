package au.org.ala.images

import au.org.ala.web.AlaSecured
import au.org.ala.web.CASRoles
import grails.converters.JSON
import groovy.json.JsonSlurper
import org.springframework.web.multipart.MultipartFile

import java.util.regex.Pattern

//@AlaSecured(value = [CASRoles.ROLE_ADMIN], redirectUri = "/")
//@AlaSecured(value = [CASRoles.ROLE_USER, CASRoles.ROLE_ADMIN], anyRole = true, redirectUri = "/")
class AdminController {

    def imageService
    def settingService
    def tagService
    def elasticSearchService
    def collectoryService

    def index() {
        redirect(action:'dashboard')
    }

    def searchCriteria() {
        def searchCriteriaDefinitions = SearchCriteriaDefinition.list()
        [criteriaDefinitions: searchCriteriaDefinitions]
    }

    def newSearchCriteriaDefinition() {
        SearchCriteriaDefinition criteriaDefinition = null
        render(view: 'editSearchCriteriaDefinition', model: [criteriaDefinition:  criteriaDefinition])
    }

    def editSearchCriteriaDefinition() {
        SearchCriteriaDefinition criteriaDefinition = SearchCriteriaDefinition.get(params.int("searchCriteriaDefinitionId"))
        render(view: 'editSearchCriteriaDefinition', model: [criteriaDefinition:  criteriaDefinition])
    }

    def saveSearchCriteriaDefinition() {
        def criteria = SearchCriteriaDefinition.get(params.int("searchCriteriaDefinitionId"))
        if (criteria == null) {
            criteria = new SearchCriteriaDefinition(params)
        } else {
            criteria.properties = params
        }

        criteria.save()

        redirect(action:"searchCriteria")
    }

    def deleteSearchCriteriaDefinition() {
        def criteria = SearchCriteriaDefinition.get(params.int("searchCriteriaDefinitionId"))
        if (criteria) {
            try {
                criteria.delete(flush: true)
            } catch (Exception ex) {
                flash.errorMessage = "Delete failed. This is probably because there exists search critera that use this definition<br/>" + ex.message
            }
        }

        redirect(action:"searchCriteria")
    }

    def dashboard() {
    }

    def tools() {
    }

    def localIngest() {
    }

    def reinitialiseImageIndex() {
        imageService.deleteIndex()
        redirect(action:'tools')
    }

    def reindexImages() {
        imageService.scheduleBackgroundTask(new ScheduleReindexAllImagesTask(imageService))
        redirect(action:'tools')
    }

    def fieldDefinitionsFragment() {
        def fieldDefinitions = ImportFieldDefinition.listOrderByFieldName()
        [fieldDefinitions: fieldDefinitions]
    }

    def inboxFileListFragment() {
        def fileList = imageService.listStagedImages()
        [fileList: fileList, fieldDefinitions: ImportFieldDefinition.listOrderByFieldName()]
    }

    def addFieldFragment() {
        render(view:'editFieldFragment')
    }

    def editFieldFragment() {
        def field = ImportFieldDefinition.get(params.int("id"))
        [fieldDefinition: field]
    }

    def saveFieldDefinition() {
        def name = params.name
        def type = params.type as ImportFieldType
        def value = params.value

        if (name && type && value) {

            if (type == ImportFieldType.FilenameRegex) {
                // try and compile the pattern

                try {
                    def pattern = Pattern.compile(value)
                } catch (Exception ex) {
                    render(['success': false, message: "Invalid regular Expression: ${ex.message}"] as JSON)
                    return
                }
            }
            // check existing
            def existing = ImportFieldDefinition.findByFieldName(name)
            if (existing) {
                existing.value = value
                existing.fieldType = type
            } else {
                def field = new ImportFieldDefinition(fieldType: type, fieldName: name, value: value)
                field.save(flush: true, failOnError: true)
            }
            render(['success': true, message: ""] as JSON)
        }

        render(['success': false, message: "Missing or incorrect parameters!"] as JSON)

    }

    def deleteFieldDefinition() {
        def fieldDefinition = ImportFieldDefinition.findById(params.int("id"))
        if (fieldDefinition) {
            fieldDefinition.delete()
        }
        render([success:true] as JSON)
    }

    def duplicates() {
        def queryParams = [:]
        queryParams.max = params.max ?: 10
        queryParams.offset = params.offset ?: 0

        def allCounts = Image.executeQuery("select count(contentMD5Hash) from Image group by contentMD5Hash having count(*) > 1")
        def c = Image.executeQuery("select contentMD5Hash, count(*) from Image group by contentMD5Hash having count(*) > 1 order by count(*) desc", queryParams)

        // find an exemplar image for each set of duplicates
        def results = []
        c.each {
            def hash = it[0]
            def image = Image.findByContentMD5Hash(hash)
            results << [image: image, hash: hash, count:it[1]]
        }

        [results: results, totalCount: allCounts.size()]
    }

    def settings() {
        def settings = Setting.list([sort:'name'])
        [settings: settings]
    }

    def setSettingValue() {
        def name = params.name
        def value = params.value
        if (name && value) {
            try {
                settingService.setSettingValue(name, value)
                flash.message = "${name} set to ${value}"
            } catch (Exception ex) {
                flash.errorMessage = ex.message
            }
        } else {
            flash.errorMessage = "Failed to set setting. Either name or value was not supplied"
        }
        redirect(action:'settings')
    }

    def tags() {

    }

    def uploadTagsFragment() {
    }

    def uploadTagsFile() {
        MultipartFile file = request.getFile('tagfile')

        if (!file || file.size == 0) {
            flash.errorMessage = "You need to select a file to upload!"
            redirect(action:'tags')
            return
        }

        def count = tagService.loadTagsFromFile(file)

        flash.message = "${count} tags loaded from file"

        redirect(action:'tags')
    }

    def indexSearch() {
        QueryResults<Image> results = null
        if (params.q) {
            Map map = null
            try {
                map = new JsonSlurper().parseText(params.q)
            } catch (Exception ex) {
                flash.message = "Invalid JSON! - " + ex.message
                return
            }

            params.max = params.max ?: 48
            params.offset = params.offset ?: 0

            results = elasticSearchService.search(map, params)
        }
        [results: results, query: params.q]
    }

    def clearCollectoryCache(){
        collectoryService.clearCache()
        redirect(action:'tools')
    }
}
