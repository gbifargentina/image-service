package au.org.ala.images

import au.org.ala.cas.util.AuthenticationUtils
import au.org.ala.web.AlaSecured
import au.org.ala.web.CASRoles
import org.apache.commons.io.IOUtils
import org.apache.commons.lang.StringUtils
import org.codehaus.groovy.grails.web.servlet.mvc.GrailsParameterMap
import org.springframework.web.multipart.MultipartFile
import org.springframework.web.multipart.MultipartHttpServletRequest

import javax.servlet.http.HttpServletResponse
import java.util.regex.Pattern

class ImageController {

    def imageService
    def imageStoreService
    def searchService
    def selectionService
    def logService
    def imageStagingService
    def batchService
    def collectoryService

    def index() { }

//    @AlaSecured(value = [CASRoles.ROLE_ADMIN], redirectUri = '/')
    def upload() { }

//    @AlaSecured(value = [CASRoles.ROLE_ADMIN], redirectUri = '/')
    def storeImage() {

        MultipartFile file = request.getFile('image')

        if (!file || file.size == 0) {
            flash.errorMessage = "You need to select a file to upload!"
            redirect(action:'upload')
            return
        }

        def pattern = Pattern.compile('^image/(.*)$|^audio/(.*)$')

        def m = pattern.matcher(file.contentType)
        if (!m.matches()) {
            flash.errorMessage = "Invalid file type for upload. Must be an image or audio file (content is ${file.contentType})"
            redirect(action:'upload')
            return
        }

        def userId = AuthenticationUtils.getUserId(request) ?: "<anonymous>"
        def image = imageService.storeImage(file, userId)
        if (image) {
            imageService.scheduleArtifactGeneration(image.id, userId)
        }
        flash.message = "Image uploaded with identifier: ${image?.imageIdentifier}"
        redirect(controller:'image', action:'upload')
    }

    def list() {

        def ct = new CodeTimer("Image list")
        QueryResults<Image> results

        params.offset = params.offset ?: 0
        params.max = params.max ?: 15
        params.sort = params.sort ?: 'dateUploaded'
        params.order = params.order ?: 'desc'

        def query = params.q as String

        if (query) {
            results = searchService.simpleSearch(query, params)
        } else {
            results = searchService.allImages(params)
        }

        def userId = AuthenticationUtils.getUserId(request)

        def isLoggedIn = StringUtils.isNotEmpty(userId)
        def selectedImageMap = selectionService.getSelectedImageIdsAsMap(userId)

        ct.stop(true)
        [images: results.list, q: query, totalImageCount: results.totalCount, isLoggedIn: isLoggedIn, selectedImageMap: selectedImageMap]
    }

    def proxyImage() {
        def imageInstance = imageService.getImageFromParams(params)
        if (imageInstance) {
            def imageUrl = imageService.getImageUrl(imageInstance.imageIdentifier)
            boolean contentDisposition = params.boolean("contentDisposition")
            proxyImageRequest(response, imageInstance, imageUrl, (int) imageInstance.fileSize ?: 0, contentDisposition)
        }
    }

    def proxyImageThumbnail() {
        def imageInstance = imageService.getImageFromParams(params)
        if (imageInstance) {
            def imageUrl = imageService.getImageThumbUrl(imageInstance.imageIdentifier)
            proxyImageRequest(response, imageInstance, imageUrl, 0)
        }
    }

    def proxyImageThumbnailLarge() {
        def imageInstance = imageService.getImageFromParams(params)
        if (imageInstance) {
            def imageUrl = imageService.getImageThumbLargeUrl(imageInstance.imageIdentifier)
            proxyImageRequest(response, imageInstance, imageUrl, 0)
        }
    }

    def proxyImageTile() {
        def imageIdentifier = params.id
        def url = imageService.getImageTilesRootUrl(imageIdentifier)
        url += "/${params.z}/${params.x}/${params.y}.png"
        proxyUrl(new URL(url), response)
    }

    private void proxyImageRequest(HttpServletResponse response, Image imageInstance, String imageUrl, int contentLength, boolean addContentDisposition = false) {

        def u = new URL(imageUrl)
        response.setContentType(imageInstance.mimeType ?: "image/jpeg")
        if (addContentDisposition) {
            response.setHeader("Content-disposition", "attachment;filename=${imageInstance.imageIdentifier}.${imageInstance.extension ?: "jpg"}")
        }

        if (contentLength) {
            response.setContentLength(contentLength)
        }

        proxyUrl(u, response)
    }

    private void proxyUrl(URL u, HttpServletResponse response) {
        InputStream is = null
        try {
            is = u.openStream()
        } catch (Exception ex) {
            logService.error("Failed it proxy URL", ex)
        }

        if (is) {
            try {
                IOUtils.copy(u.openStream(), response.outputStream)
            } finally {
                is.close()
                response.flushBuffer()
            }
        }
    }

    def scheduleArtifactGeneration() {

        def imageInstance = imageService.getImageFromParams(params)
        def userId = AuthenticationUtils.getUserId(request)

        if (imageInstance) {
            imageService.scheduleArtifactGeneration(imageInstance.id, userId)
            flash.message = "Image artifact generation scheduled for image ${imageInstance.id}"
        } else {
            def imageList = Image.findAll()
            long count = 0
            imageList.each { image ->
                imageService.scheduleArtifactGeneration(image.id, userId)
                count++
            }
            flash.message = "Image artifact generation scheduled for ${count} images."
        }

        redirect(action:'list')
    }

    def details() {
        def image = imageService.getImageFromParams(params)
        if (!image) {
            flash.errorMessage = "Could not find image with id ${params.int("id") ?: params.imageId }!"
            redirect(action:'list')
        }
        def subimages = Subimage.findAllByParentImage(image)*.subimage
        def sizeOnDisk = imageStoreService.getConsumedSpaceOnDisk(image.imageIdentifier)

        def userId = AuthenticationUtils.getUserId(request)
        def albums = []
        if (userId) {
            albums = Album.findAllByUserId(userId, [sort:'name'])
        }

        def thumbUrls = imageService.getAllThumbnailUrls(image.imageIdentifier)

        boolean isImage = imageService.isImageType(image)

        //add additional metadata
        def resourceLevel = collectoryService.getResourceLevelMetadata(image.dataResourceUid)

        [imageInstance: image, subimages: subimages, sizeOnDisk: sizeOnDisk, albums: albums, squareThumbs:
                thumbUrls, isImage: isImage, resourceLevel: resourceLevel]
    }

    def view() {
        def image = imageService.getImageFromParams(params)
        if (!image) {
            flash.errorMessage = "Could not find image with id ${params.int("id")}!"
        }
        def subimages = Subimage.findAllByParentImage(image)*.subimage
        render (view: 'viewer', model: [imageInstance: image, subimages: subimages])
    }

    def tagsFragment() {
        def imageInstance = imageService.getImageFromParams(params)
        def imageTags = ImageTag.findAllByImage(imageInstance)
        def tags = imageTags?.collect { it.tag }
        def leafTags = TagUtils.getLeafTags(tags)

        [imageInstance: imageInstance, tags: leafTags]
    }

    @AlaSecured(value = [CASRoles.ROLE_ADMIN])
    def imageAuditTrailFragment() {
        def imageInstance = Image.get(params.int("id"))
        def messages = []
        if (imageInstance) {
            messages = AuditMessage.findAllByImageIdentifier(imageInstance.imageIdentifier, [order:'asc', sort:'dateCreated'])
        }
        [messages: messages]
    }

    def imageMetadataTableFragment() {

        def imageInstance = imageService.getImageFromParams(params)
        def metaData = []
        def source = params.source as MetaDataSourceType
        if (imageInstance) {

            if (source) {
                metaData = imageInstance.metadata?.findAll { it.source == source }
            } else {
                metaData = imageInstance.metadata
            }
        }

        [imageInstance: imageInstance, metaData: metaData?.sort { it.name }, source: source]
    }

    def imageTooltipFragment() {
        def imageInstance = imageService.getImageFromParams(params)
        [imageInstance: imageInstance]
    }

    def imageTagsTooltipFragment() {
        def imageInstance = imageService.getImageFromParams(params)

        def imageTags = ImageTag.findAllByImage(imageInstance)
        def tags = imageTags?.collect { it.tag }
        def leafTags = TagUtils.getLeafTags(tags)

        [imageInstance: imageInstance, tags: leafTags]
    }

    def createSubimageFragment() {
        def imageInstance = imageService.getImageFromParams(params)
        def metadata = ImageMetaDataItem.findAllByImage(imageInstance)

        [imageInstance: imageInstance, x: params.x, y: params.y, width: params.width, height: params.height, metadata: metadata]
    }

    def viewer() {
        def imageInstance = imageService.getImageFromParams(params)
        [imageInstance: imageInstance, auxDataUrl: params.infoUrl]
    }

    @AlaSecured(value = [CASRoles.ROLE_USER, CASRoles.ROLE_ADMIN], anyRole = true, redirectUri = "/")
    def stagedImages() {
        def userId = AuthenticationUtils.getUserId(request)
        if (!userId) {
            throw new Exception("Must be logged in to use this service")
        }

        def stagedFiles = imageStagingService.buildStagedImageData(userId, params)
        def columns = StagingColumnDefinition.findAllByUserId(userId, [sort:'id', order:'asc'])

        [stagedFiles: stagedFiles, userId: userId, hasDataFile: imageStagingService.hasDataFileUploaded(userId),
         dataFileUrl: imageStagingService.getDataFileUrl(userId), dataFileColumns: columns]
    }

    @AlaSecured(value = [CASRoles.ROLE_USER, CASRoles.ROLE_ADMIN], anyRole = true, redirectUri = "/")
    def stageImages() {
        def userId = AuthenticationUtils.getUserId(request)
        if (!userId) {
            throw new Exception("Must be logged in to use this service")
        }
        if(request instanceof MultipartHttpServletRequest) {
            def filelist = []
            def errors = []

            ((MultipartHttpServletRequest) request).getMultiFileMap().imageFile.each { f ->
                if (f != null) {
                    try {
                        def stagedFile = imageStagingService.stageFile(userId, f)
                        if (stagedFile) {
                            filelist << stagedFile
                        } else {
                            errors << f
                        }
                    } catch (Exception ex) {
                        flash.message = "Failed to upload image file: " + ex.message;
                    }
                }

            }
        }
        redirect(action:'stagedImages')
    }

    @AlaSecured(value = [CASRoles.ROLE_USER, CASRoles.ROLE_ADMIN], anyRole = true, redirectUri = "/")
    def deleteStagedImage(int stagedImageId) {
        def userId = AuthenticationUtils.getUserId(request)
        if (!userId) {
            throw new Exception("Must be logged in to use this service")
        }
        def stagedFile = StagedFile.get(stagedImageId)
        if (stagedFile) {
            imageStagingService.deleteStagedFile(stagedFile)
        }
        redirect(action:'stagedImages')
    }

    @AlaSecured(value = [CASRoles.ROLE_USER, CASRoles.ROLE_ADMIN], anyRole = true, redirectUri = "/")
    def uploadStagingDataFile() {

        def userId = AuthenticationUtils.getUserId(request)
        if (!userId) {
            throw new Exception("Must be logged in to use this service")
        }

        if(request instanceof MultipartHttpServletRequest) {
            MultipartFile f = ((MultipartHttpServletRequest) request).getFile('dataFile')
            if (f != null) {
                def allowedMimeTypes = ['text/plain','text/csv', 'application/octet-stream', 'application/vnd.ms-excel']
                if (!allowedMimeTypes.contains(f.getContentType())) {
                    flash.message = "The data file must be one of: ${allowedMimeTypes}, recieved '${f.getContentType()}'}"
                    redirect(action:'stagedImages')
                    return
                }

                if (f.size == 0 || !f.originalFilename) {
                    flash.message = "You must select a file to upload"
                    redirect(action:'stagedImages')
                    return
                }
                imageStagingService.uploadDataFile(userId, f)
            }
        }
        redirect(action:'stagedImages')
    }

    @AlaSecured(value = [CASRoles.ROLE_USER, CASRoles.ROLE_ADMIN], anyRole = true, redirectUri = "/")
    def clearStagingDataFile() {
        def userId = AuthenticationUtils.getUserId(request)
        if (!userId) {
            throw new Exception("Must be logged in to use this service")
        }
        imageStagingService.deleteDataFile(userId)
        redirect(action:'stagedImages')
    }

    @AlaSecured(value = [CASRoles.ROLE_USER, CASRoles.ROLE_ADMIN], anyRole = true, redirectUri = "/")
    def saveStagingColumnDefinition() {
        def userId = AuthenticationUtils.getUserId(request)
        if (!userId) {
            throw new Exception("Must be logged in to use this service")
        }

        def fieldName = params.fieldName
        if (fieldName) {

            def fieldType = (params.fieldType as StagingColumnType) ?: StagingColumnType.Literal
            def format = params.definition ?: ""
            def fieldDefinition = StagingColumnDefinition.get(params.int("columnDefinitionId"))
            if (fieldDefinition) {
                // this is a 'save', not a 'create'
                fieldDefinition.fieldName = fieldName
                fieldDefinition.fieldDefinitionType = fieldType
                fieldDefinition.format = format
            } else {
                new StagingColumnDefinition(userId: userId, fieldDefinitionType: fieldType, format: format,
                        fieldName: fieldName).save(failOnError: true)
            }

        }
        redirect(action: 'stagedImages')
    }

    @AlaSecured(value = [CASRoles.ROLE_USER, CASRoles.ROLE_ADMIN], anyRole = true, redirectUri = "/")
    def editStagingColumnFragment() {
        def fieldDefinition = StagingColumnDefinition.get(params.int("columnDefinitionId"))
        def userId = AuthenticationUtils.getUserId(request)
        if (!userId) {
            throw new Exception("Must be logged in to use this service")
        }

        def hasDataFile = imageStagingService.hasDataFileUploaded(userId)

        def dataFileColumns = []
        if (hasDataFile) {
            dataFileColumns = ['']
            dataFileColumns.addAll(imageStagingService.getDataFileColumns(userId))
        }

        [fieldDefinition: fieldDefinition, hasDataFile: hasDataFile, dataFileColumns: dataFileColumns]
    }

    @AlaSecured(value = [CASRoles.ROLE_USER, CASRoles.ROLE_ADMIN], anyRole = true, redirectUri = "/")
    def deleteStagingColumnDefinition() {
        def userId = AuthenticationUtils.getUserId(request)
        if (!userId) {
            throw new Exception("Must be logged in to use this service")
        }
        def fieldDefinition = StagingColumnDefinition.get(params.int("columnDefinitionId"))
        if (fieldDefinition) {
            fieldDefinition.delete()
        }
        redirect(action:"stagedImages")
    }

    @AlaSecured(value = [CASRoles.ROLE_USER, CASRoles.ROLE_ADMIN], anyRole = true, redirectUri = "/")
    def uploadStagedImages() {
        def userId = AuthenticationUtils.getUserId(request)
        if (!userId) {
            throw new Exception("Must be logged in to use this service")
        }

        def harvestable = params.boolean("harvestable")

        def stagedFiles = imageStagingService.buildStagedImageData(userId, [:])

        def batchId = batchService.createNewBatch()
        int imageCount = 0
        stagedFiles.each { stagedFileMap ->
            def stagedFile = StagedFile.get(stagedFileMap.id)
            batchService.addTaskToBatch(batchId, new UploadFromStagedFileTask(stagedFile, stagedFileMap,
                    imageStagingService, batchId, harvestable))
            imageCount++
        }

        redirect(action:"stagedImages")
    }

}
