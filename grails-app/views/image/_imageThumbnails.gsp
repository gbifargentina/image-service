<style>

    .pagination .step {
        background-color: transparent;
        border: 0;
        border-radius: 4px;
        color: #0695d6;
        line-height: 1.42857;
        margin: 0 2px;
        padding: 10px 17px;
        position: relative;
        text-decoration: none;
    }

    .image-caption, .image-thumbnail {
        text-align: center;
    }

    .row-fluid .thumbnails > li.span2:nth-child(6n+1),
    .row-fluid .thumbnails > li.span3:nth-child(4n+1),
    .row-fluid .thumbnails > li.span4:nth-child(3n+1),
    .row-fluid .thumbnails > li.span6:nth-child(2n+3){ margin-left: 0 !important; }

    .thumbnail-button-tray {
        display: block;
        margin-bottom: 5px;
        border: 1px solid #ddd;
    }

    input[type=checkbox] { display:none; } /* to hide the checkbox itself */
    input[type=checkbox] + label:before {
        font-family: FontAwesome, Arial, san-serif;
        font-size: 14px;
        display: inline-block;
        opacity: 0.50;
    }

    .selection-header label {
        margin-bottom: 0;
    }

    input[type=checkbox] + label:before { content: "\f096"; } /* unchecked icon */
    input[type=checkbox] + label:before { letter-spacing: 10px; } /* space between checkbox and label */

    input[type=checkbox]:checked + label:before {
        content: "\f046";
        opacity: 1;
    } /* checked icon */
    input[type=checkbox]:checked + label:before { letter-spacing: 5px; } /* allow space for check mark */

</style>

<table style="width: 100%;">
    <tr>
        <td class="text-center">
            <g:if test="${thumbsTitle}">
                    <div class="h4">
                        <span class="text-success">${thumbsTitle} </span>
                        <span>Imágenes encontradas</span>
                    </div>
            </g:if>
        </td>
        <td>
            <div class="">
                <g:if test="${allowSelection && images?.size() > 0 || toolButtons}">
                    <div class="btn-group pull-right">
                        <a class="btn btn-small dropdown-toggle" data-toggle="dropdown" href="#">
                            <i class="icon-cog"></i>&nbsp;
                            <span class="caret"></span>
                        </a>
                        <ul class="dropdown-menu pull-right">
                            <g:if test="${allowSelection && images?.size() > 0}">
                                <li>
                                    <a href="#" id="btnSelectAllOnPage">Select all on page</a>
                                </li>
                                <li>
                                    <a href="#" id="btnDeselectAllOnPage">Deselect all on page</a>
                                </li>
                                <li class="divider"></li>
                                <li>
                                    <a href="#" id="btnClearSelection">Clear selection</a>
                                </li>
                            </g:if>
                            <g:if test="${toolButtons}">
                                <g:if test="${allowSelection}">
                                    <li class="divider"></li>
                                </g:if>
                                <g:each in="${toolButtons}" var="tool">
                                    <g:if test="${tool.id == 'divider'}">
                                        <li class="divider"></li>
                                    </g:if>
                                    <g:else>
                                        <li>
                                            <a href="#" id="${tool.id}">${tool.label}</a>
                                        </li>
                                    </g:else>
                                </g:each>
                            </g:if>
                        </ul>
                    </div>
                </g:if>
            </div>
        </td>
    </tr>
</table>


<div class="row thumbnails">
    <g:each in="${images}" var="image">
        <div class="col-sm-6 col-md-4">
            <a class="panel panel-default thumbnail" imageId="${image.id}"
               href="${createLink(controller:'image', action:'details', id: image.id)}">
                <g:if test="${allowSelection == true}">
                    <div class="selection-header">
                        <g:checkBox class="chkSelectImage" name="chkSelectImage${image.id}"
                                    checked="${selectedImageMap?.containsKey(image.imageIdentifier)}" />
                        <label for="chkSelectImage${image.id}"></label>
                    </div>
                </g:if>
%{--                <g:if test="${headerTemplate}">--}%
%{--                    <g:render template="${headerTemplate}" model="${[image: image]}" />--}%
%{--                </g:if>--}%
                <div class="panel-heading image-thumbnail" style="background-image:url('<img:imageSquareThumbUrl imageId='${image.imageIdentifier}' backgroundColor="white"/>')">
                </div>
                <div class="panel-body">
                    <h4>${image.title}</h4>
%{--                    <div class="text-muted">--}%
%{--                        <p>${image.uploader}</p>--}%
%{--                    </div>--}%
                </div>
%{--                <g:if test="${footerTemplate}" class="panel-body">--}%
%{--                    <g:render template="${footerTemplate}" model="${[image: image]}" />--}%
%{--                </g:if>--}%
            </a>
        </div>
    </g:each>
</div>

<div class="pagination text-center" style="display: block;">
    <g:paginate total="${totalImageCount}" prev="" next="" params="${[q:params.q]}" id="${paginateActionId}" />
</div>

<r:script>
    $(document).ready(function() {

        $("#btnClearSelection").click(function(e) {
            e.preventDefault();
            imgvwr.showSpinner("Clearing selection...");
            $.ajax("${createLink(controller: 'selection', action: 'clearSelection')}").done(function() {
                location.reload(true);
                imgvwr.hideSpinner();
            });
        });

        $(".chkSelectImage").change(function(e) {
            var imageId = $(this).closest("[imageId]").attr("imageId");
            if (imageId) {
                if ($(this).is(":checked")) {
                    $.ajax("${createLink(controller: 'selection', action:'ajaxSelectImage')}/" + imageId).done(function(results) {
                        updateSelectionContext();
                    });
                } else {
                    $.ajax("${createLink(controller: 'selection', action:'ajaxDeselectImage')}/" + imageId).done(function(results) {
                        updateSelectionContext();
                    });
                }
            }
        });

        $("#btnSelectAllOnPage").click(function(e) {
            e.preventDefault();
            selectAllOnPage();
        });

        $("#btnDeselectAllOnPage").click(function(e) {
            e.preventDefault();
            deselectAllOnPage();
        });


        $(".image-thumbnail").each(function() {
            var imageId = $(this).closest("[imageId]").attr("imageId");
            if (imageId) {
                $(this).qtip({
                    content: {
                        text: function(event, api) {
                            $.ajax("${createLink(controller:'image', action:"imageTooltipFragment")}/" + imageId).then(function(content) {
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

    });

    function selectAllOnPage() {

        imgvwr.showSpinner("Selecting images on page...");
        var imageList = $(".thumbnail[imageId]").map(function() {
            return $(this).attr("imageId");
        }).get();

        $.post("${createLink(controller:'selection', action:'ajaxSelectImages')}", { imageList: imageList } ).done(function() {
            updateSelectionContext();
            $(".thumbnail[imageId]").each(function(e) {
                $(this).find(".chkSelectImage").prop('checked', true);
            });
            imgvwr.hideSpinner();
        });
    }

    function deselectAllOnPage() {

        imgvwr.showSpinner("Deselecting images...");

        var imageList = $(".thumbnail[imageId]").map(function() {
            return $(this).attr("imageId");
        }).get();

        $.post("${createLink(controller:'selection', action:'ajaxDeselectImages')}", { imageList: imageList } ).done(function() {
            updateSelectionContext();
            $(".thumbnail[imageId]").each(function(e) {
                $(this).find(".chkSelectImage").prop('checked', false);
            });
            imgvwr.hideSpinner();
        });

    }
</r:script>