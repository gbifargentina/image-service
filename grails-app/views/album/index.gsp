<%@ page import="au.org.ala.web.CASRoles" %>
<!doctype html>
<html>
<head>
    <meta name="layout" content="main"/>
    <title>ALA Image Service - My Albums</title>
    <style>
        #buttonsDiv {
            margin-bottom: 5px;
        }
    </style>
</head>

<body class="content">

<img:headerContent title="My Albums">
    <%
        pageScope.crumbs = [
        ]
    %>
</img:headerContent>

<div class="row-fluid">
    <div class="span3">
        <div id="buttonsDiv">
            <button class="btn btn-success" id="btnShowAddAlbum"><i class="icon-plus icon-white"></i>&nbsp;New album</button>
        </div>
        <div class="well well-small">
            <g:if test="${albums}">
                <ul class="nav nav-pills nav-stacked">
                    <g:each in="${albums}" var="album">
                        <li albumId="${album.id}">
                            <a href="#" class="albumLink" style="display: inline-block">${album.name} <small>(${countMap[album] ?: 0})</small></a>

                            <div class="pull-right">
                                <button class="btn btn-danger btn-mini btnDeleteAlbum"><i class="icon-remove icon-white"></i></button>
                                <button class="btn btn-mini"><i class="icon-edit"></i></button>
                            </div>
                        </li>
                    </g:each>
                </ul>
            </g:if>
            <g:else>
                <em class="muted">No albums</em>
            </g:else>
        </div>
    </div>
    <div class="span9">
        <div id="album-details">
        </div>
    </div>
</div>
</body>
</html>

<r:script>

    $(document).ready(function() {

        $("#btnShowAddAlbum").click(function(e) {
            e.preventDefault();
            var options = {
                url: "${createLink(action:'createAlbumFragment')}",
                title: "Create a new album"
            }
            showModal(options);
        });

        $(".albumLink").click(function(e) {
            e.preventDefault();
            var albumId = $(this).closest("[albumId]").attr("albumId");
            if (albumId) {
                updateAlbumDetails("${createLink(action: 'albumDetailsFragment')}/" + albumId);
            }
        });

        $(".btnDeleteAlbum").click(function(e) {
            e.preventDefault();
            var albumId = $(this).closest("[albumId]").attr("albumId");
            if (albumId) {
                $.ajax("${createLink(action:"ajaxDeleteAlbum")}/" + albumId).done(function(result) {
                    if (result.success) {
                        $("[albumId='" + albumId + "']").remove();
                    }
                });
            }
        });
    });

    function updateAlbumDetails(url) {
        $("#album-details").html(loadingSpinner());
        $.ajax(url).done(function(content) {
            $("#album-details").html(content);
            $(".pagination a").click(function(e) {
                e.preventDefault();
                var url = $(this).attr("href");
                updateAlbumDetails(url);
            });

        });
    }

</r:script>
