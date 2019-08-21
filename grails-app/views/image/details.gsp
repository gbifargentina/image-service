<%@ page import="au.org.ala.web.CASRoles" %>
<g:set var="mediaTitle" value="${isImage ? 'Image' : 'Media'}" />
<!doctype html>
<html>
    <head>
        <meta name="layout" content="images"/>
        <title>${mediaTitle} details | Atlas of Living Australia</title>
        <style>

            .property-value {
                font-weight: bold;
            }

            .audiojs {
                width: 100%;
            }

        </style>
        <r:require modules="bootstrap,jstree,audiojs,bootstrap-switch" />
    </head>
    <body class="content">
        <img:headerContent title="${mediaTitle} details ${imageInstance?.id}">
            <%
                pageScope.crumbs = []
            %>
        </img:headerContent>

    <br/>
        <div class="row-fluid">
            <div class="span4">
                <div class="well well-small">
                    <div id="panel panel-default">
                        <div class="panel-heading image-thumbnail" style="text-align: center">
                            <g:if test="${isImage}">
                            <a href="${grailsApplication.config.serverName}${createLink(action:'view', id:imageInstance.id)}">
                                <img src="<img:imageThumbUrl imageId="${imageInstance?.imageIdentifier}"/>" />
                            </a>
                            </g:if>
                            <g:if test="${imageInstance.mimeType?.toLowerCase()?.startsWith("audio/")}">
                                <audio src="<img:imageUrl imageId="${imageInstance.imageIdentifier}" />"></audio>
                            </g:if>
                        </div>
                    </div>
                </div>
                <div class="well well-small">
                    <div id="tagsSection">
                        Loading&nbsp;<img:spinner />
                    </div>
                </div>
                <g:if test="${isImage}">
                <div class="well well-small">
                    <h4>Thumbnails</h4>
                    <g:each in="${squareThumbs}" var="thumbUrl">
                        <a href="${thumbUrl}" target="thumbnail">
                            <image class="img-polaroid" src="${thumbUrl}" width="50px" title="${thumbUrl}" style="margin: 5px"></image>
                        </a>
                    </g:each>
                </div>
                </g:if>
            </div>
            <div class="span8">
                <div class="well well-small">
                    <div class="tabbable">
                        <ul class="nav nav-tabs">
                            <li class="active">
                                <a href="#tabProperties" data-toggle="tab">${mediaTitle} properties</a>
                            </li>
                            <li>
                                <a href="#tabExif" data-toggle="tab">Embedded</a>
                            </li>
                            <li>
                                <a href="#tabUserDefined" data-toggle="tab">User Defined Metadata</a>
                            </li>
                            <li>
                                <a href="#tabSystem" data-toggle="tab">System</a>
                            </li>
                            <auth:ifAnyGranted roles="${CASRoles.ROLE_ADMIN}">
                                <li>
                                    <a href="#tabAuditMessages" data-toggle="tab">Audit trail</a>
                                </li>
                            </auth:ifAnyGranted>
                        </ul>

                        <div class="tab-content">
                            <div class="tab-pane active" id="tabProperties">
                                <table class="table table-bordered table-condensed table-striped">
                                    <tr>
                                        <td class="property-name">Image Identifier</td>
                                        <td class="property-value">${imageInstance.imageIdentifier}</td>
                                    </tr>
                                    <tr>
                                        <td class="property-name">Title</td>
                                        <td class="property-value">${imageInstance.title}</td>
                                    </tr>
                                    <tr>
                                        <td class="property-name">Creator</td>
                                        <td class="property-value"><img:imageMetadata image="${imageInstance}" resource="${resourceLevel}" field="creator"/></td>
                                    </tr>
                                    <tr>
                                        <td class="property-name">Data resource UID</td>
                                        <td class="property-value">${imageInstance.dataResourceUid}</td>
                                    </tr>
                                    <tr>
                                        <td class="property-name">Filename</td>
                                        <td class="property-value">${imageInstance.originalFilename}</td>
                                    </tr>
                                    <g:if test="${imageInstance.parent}">
                                        <tr>
                                            <td>Parent image</td>
                                            <td imageId="${imageInstance.parent.id}">
                                                <g:link controller="image" action="details" id="${imageInstance.parent.id}">${imageInstance.parent.originalFilename ?: imageInstance.parent.id}</g:link>
                                                <i class="icon-info-sign image-info-button"></i>
                                            </td>
                                        </tr>
                                    </g:if>
                                    <g:if test="${isImage}">
                                    <tr>
                                        <td class="property-name">Dimensions (w x h)</td>
                                        <td class="property-value">${imageInstance.width} x ${imageInstance.height}</td>
                                    </tr>
                                    </g:if>
                                    <tr>
                                        <td class="property-name">File size</td>
                                        <td class="property-value"><img:sizeInBytes size="${imageInstance.fileSize}" /></td>
                                    </tr>
                                    <tr>
                                        <td class="property-name">Date uploaded</td>
                                        <td class="property-value"><img:formatDateTime date="${imageInstance.dateUploaded}" /></td>
                                    </tr>
                                    <tr>
                                        <td class="property-name">Uploaded by</td>
                                        <td class="property-value"><img:userDisplayName userId="${imageInstance.uploader}" /></td>
                                    </tr>
                                    <g:if test="${imageInstance.dateTaken}">
                                        <tr>
                                            <td class="property-name">Date taken/created</td>
                                            <td class="property-value"><img:formatDateTime date="${imageInstance.dateTaken}" /></td>
                                        </tr>
                                    </g:if>
                                    <tr>
                                        <td class="property-name">Mime type</td>
                                        <td class="property-value">${imageInstance.mimeType}</td>
                                    </tr>
                                    <g:if test="${isImage}">
                                    <tr>
                                        <td class="property-name">Zoom levels</td>
                                        <td class="property-value">${imageInstance.zoomLevels}</td>
                                    </tr>
                                    <tr>
                                        <td class="property-name">Linear scale</td>
                                        <td class="property-value">
                                            <g:if test="${imageInstance.mmPerPixel}">
                                            ${imageInstance.mmPerPixel} mm per pixel
                                            <button id="btnResetLinearScale" type="button" class="btn btn-small pull-right" title="Reset calibation"><i class="icon-remove"></i></button>
                                            </g:if>
                                            <g:else>
                                                &lt;not calibrated&gt;
                                            </g:else>
                                        </td>
                                    </tr>
                                    </g:if>
                                    <tr>
                                        <td class="property-name">${mediaTitle} URL</td>
                                        <td class="property-value"><img:imageUrl imageId="${imageInstance.imageIdentifier}" />
                                    </tr>
                                    <tr>
                                        <td class="property-name">MD5 Hash</td>
                                        <td class="property-value">${imageInstance.contentMD5Hash}</td>
                                    </tr>
                                    <tr>
                                        <td class="property-name">SHA1 Hash</td>
                                        <td class="property-value">${imageInstance.contentSHA1Hash}</td>
                                    </tr>
                                    <tr>
                                        <td class="property-name">Size on disk (including all artifacts)</td>
                                        <td class="property-value"><img:sizeInBytes size="${sizeOnDisk}" /></td>
                                    </tr>
                                    <tr>
                                        <td class="property-name">Rights</td>
                                        <td class="property-value"><img:imageMetadata image="${imageInstance}" resource="${resourceLevel}" field="rights"/></td>
                                    </tr>
                                    <tr>
                                        <td class="property-name">Rights holder</td>
                                        <td class="property-value"><img:imageMetadata image="${imageInstance}" resource="${resourceLevel}" field="rightsHolder"/></td>
                                    </tr>
                                    <tr>
                                        <td class="property-name">Licence</td>
                                        <td class="property-value"><img:imageMetadata image="${imageInstance}" resource="${resourceLevel}" field="license"/></td>
                                    </tr>
                                    <g:if test="${subimages}">
                                        <tr>
                                            <td>Sub-images</td>
                                            <td>
                                                <ul>
                                                    <g:each in="${subimages}" var="subimage">
                                                        <li imageId="${subimage.id}">
                                                            <g:link controller="image" action="details" id="${subimage.id}">${subimage.originalFilename ?: subimage.id}</g:link>
                                                            <i class="icon-info-sign image-info-button"></i>
                                                        </li>
                                                    </g:each>
                                                </ul>
                                            </td>
                                        </tr>
                                    </g:if>

                                    <tr>
                                        <td class="property-name">Harvested as occurrence record?</td>
                                        <auth:ifAnyGranted roles="${CASRoles.ROLE_ADMIN}">
                                            <td>
                                                <g:checkBox name="chkIsHarvestable" data-size="small" data-on-text="Yes" data-off-text="No" checked="${imageInstance.harvestable}" />
                                            </td>
                                        </auth:ifAnyGranted>
                                        <auth:ifNotGranted roles="${CASRoles.ROLE_ADMIN}">
                                            <td class="property-value">${imageInstance.harvestable ? "Yes" : "No"}</td>
                                        </auth:ifNotGranted>
                                    </tr>

                                    <tr>
                                        <td colspan="2">
                                            <div class="row" style="margin:0px">
                                                <div class="col-md-4 ">
                                                    <g:link controller="webService" action="getImageInfo" params="[id:imageInstance.imageIdentifier]" title="View JSON metadata" class="panel panel-default panel-icon">
                                                        <div class="panel-heading"><i id="fa fa-cloud-download" class="fa fa-cloud-download icono-2x text-gray" data-clipboard-text="fa-cloud-download"></i></div>
                                                        <div class="panel-body">
                                                            <h3>JSON</h3>
                                                        </div>
                                                    </g:link>
                                                </div>
                                            <g:if test="${isImage}">
                                                <div class="col-md-4">
                                                    <div class="panel panel-default panel-icon" id="btnViewImage" title="View zoomable image">
                                                        <a class="panel panel-default panel-icon" href="#">
                                                            <div class="panel-heading"><i id="fa fa-search-plus" class="fa fa-search-plus icono-2x text-gray" data-clipboard-text="fa-search-plus"></i></div>
                                                            <div class="panel-body">
                                                                <h3>Zoom</h3>
                                                            </div>
                                                        </a>
                                                    </div>
                                                </div>
                                            </g:if>
                                                <div class="col-md-4">
                                                    <a class="panel panel-default panel-icon" href="${grailsApplication.config.serverName}${createLink(controller:'image', action:'proxyImage', id:imageInstance.id, params:[contentDisposition: 'true'])}" title="Download full image" target="imageWindow">
                                                            <div class="panel-heading"><i id="fa fa-download" class="fa fa-download icono-2x text-gray" data-clipboard-text="fa-download"></i></div>
                                                            <div class="panel-body">
                                                                <h3>Descarga</h3>
                                                            </div>
                                                    </a>
                                                </div>
                                            </div>
                                            <auth:ifAnyGranted roles="${au.org.ala.web.CASRoles.ROLE_USER}, ${au.org.ala.web.CASRoles.ROLE_USER}">
                                                <g:if test="${albums}">
                                                    <button class="btn btn-small" title="Add this image to an album" id="btnAddToAlbum"><i class="icon-book"></i></button>
                                                </g:if>
                                            </auth:ifAnyGranted>

                                            <auth:ifAnyGranted roles="${CASRoles.ROLE_ADMIN}">
                                                <button class="btn btn-small" id="btnRegen" title="Regenerate artifacts"><i class="icon-refresh"></i></button>
                                            </auth:ifAnyGranted>

                                            <auth:ifAnyGranted roles="${CASRoles.ROLE_ADMIN}" creatorUserId="${imageInstance.uploader}">
                                                <button class="btn btn-small btn-danger" id="btnDeleteImage" title="Delete image (admin)"><i class="icon-remove icon-white"></i></button>
                                            </auth:ifAnyGranted>
                                            <auth:ifNotGranted roles="${CASRoles.ROLE_ADMIN}">
                                                <img:userIsUploader image="${imageInstance}">
                                                    <button class="btn btn-small btn-danger" id="btnDeleteImage" title="Delete your image"><i class="icon-remove icon-white"></i></button>
                                                </img:userIsUploader>
                                            </auth:ifNotGranted>


                                        </td>
                                    </tr>

                                </table>
                            </div>
                            <div class="tab-pane" id="tabExif" metadataSource="${au.org.ala.images.MetaDataSourceType.Embedded}">
                            </div>
                            <div class="tab-pane" id="tabUserDefined" metadataSource="${au.org.ala.images.MetaDataSourceType.UserDefined}">
                            </div>
                            <div class="tab-pane" id="tabSystem" metadataSource="${au.org.ala.images.MetaDataSourceType.SystemDefined}">
                            </div>
                            <auth:ifAnyGranted roles="${CASRoles.ROLE_ADMIN}">
                            <div class="tab-pane" id="tabAuditMessages">
                            </div>
                            </auth:ifAnyGranted>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </body>
</html>

<r:script>

    function refreshMetadata(tabDiv) {
        var dest = $(tabDiv);
        dest.html("Loading...");
        var source = dest.attr("metadataSource");
        $.ajax("${grailsApplication.config.serverName}${createLink(controller:'image', action:'imageMetadataTableFragment', id: imageInstance.id)}?source=" + source).done(function(content) {
            dest.html(content);
        });
    }

    <auth:ifAnyGranted roles="${CASRoles.ROLE_ADMIN}">

        function refreshAuditTrail() {
            $.ajax("${grailsApplication.config.serverName}${createLink(controller: 'image', action:'imageAuditTrailFragment', id: imageInstance.id)}").done(function(content) {
                $("#tabAuditMessages").html(content);
            });
        }

    </auth:ifAnyGranted>

    $(document).ready(function() {

        $('input:checkbox').bootstrapSwitch();

        $('input:checkbox').on('switchChange.bootstrapSwitch', function(event, state) {
            var name = $(this).attr("name");
            if (name) {
                if (name == 'chkIsHarvestable') {
                    $.ajax("${grailsApplication.config.serverName}${createLink(controller:'webService', action:'setHarvestable', params: [imageId: imageInstance.imageIdentifier])}").done(function(data) {
                        console.log(data);
                    });
                }
            }
        });

        audiojs.createAll();

        $("#btnAddToAlbum").click(function(e) {

            e.preventDefault();
            imgvwr.selectAlbum(function(albumId) {
                $.ajax("${grailsApplication.config.serverName}${createLink(controller:'album', action:'ajaxAddImageToAlbum')}/" + albumId + "?imageId=${imageInstance.id}").done(function(result) {
                    if (result.success) {
                    }
                });
            });

        });

        $("#btnResetLinearScale").click(function(e) {
            e.preventDefault();
            imgvwr.areYouSure({
                title:"Reset calibration for this image?",
                message:"Are you sure you wish to reset the linear scale for this image?",
                affirmativeAction: function() {
                    var url = "${grailsApplication.config.serverName}${createLink(controller:'webService', action:'resetImageCalibration')}?imageId=${imageInstance.imageIdentifier}";
                    $.ajax(url).done(function(result) {
                        window.location.reload(true);
                    });
                }
            });

        });

        $('a[data-toggle="tab"]').on('shown', function (e) {
            var dest = $($(this).attr("href"));
            if (dest.attr("metadataSource")) {
                refreshMetadata(dest);
            } else {
                if (dest.attr("id") == "tabAuditMessages") {
                    refreshAuditTrail();
                }
            }
        });

        $("#btnViewImage").click(function(e) {
            e.preventDefault();
            window.location = "${grailsApplication.config.serverName}${createLink(controller:'image', action:'view', id: imageInstance.id)}";
        });

        $("#btnRegen").click(function(e) {
            e.preventDefault();
            $.ajax("${grailsApplication.config.serverName}${createLink(controller:'webService', action:'scheduleArtifactGeneration', id: imageInstance.imageIdentifier)}").done(function() {
                window.location = this.location.href; // reload
            });
        });

        $("#btnDeleteImage").click(function(e) {
            e.preventDefault();

            var options = {
                message: "Warning! This operation cannot be undone. Are you sure you wish to permanently delete this image?",
                affirmativeAction: function() {
                    $.ajax("${grailsApplication.config.serverName}${createLink(controller:'webService', action:'deleteImage', id: imageInstance.imageIdentifier)}").done(function() {
                        window.location = "${grailsApplication.config.serverName}${createLink(controller:'image', action:'list')}";
                    });
                }
            };

            imgvwr.areYouSure(options);
        });

        $(".image-info-button").each(function() {
            var imageId = $(this).closest("[imageId]").attr("imageId");
            if (imageId) {
                $(this).qtip({
                    content: {
                        text: function(event, api) {
                            $.ajax("${grailsApplication.config.serverName}${createLink(controller:'image', action:"imageTooltipFragment")}/" + imageId).then(function(content) {
                                api.set("content.text", content);
                            },
                            function(xhr, status, error) {
                                api.set("content.text", status + ": " + error);
                            });
                        }
                    }
                });
            }
        });

        loadTags();
    });

    function loadTags() {
        $.ajax("${grailsApplication.config.serverName}${createLink(action:'tagsFragment',id:imageInstance.id)}").done(function(html) {
            $("#tagsSection").html(html);
        });
    }

</r:script>