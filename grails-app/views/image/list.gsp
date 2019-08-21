<!doctype html>
<html>
    <head>
        <meta name="layout" content="images"/>
        <meta name="section" content="home"/>
        <title>Image Service | ${grailsApplication.config.skin.orgNameLong}</title>
    </head>
    <body>
%{--    <body class="content">--}%

%{--        <img:headerContent title="Images" hideCrumbs="${true}">--}%
%{--        </img:headerContent>--}%

%{--        <div class="">--}%
%{--            <input type="text" class="input-xlarge" id="keyword" style="margin-bottom: 0" value="${q}" />--}%
%{--            <button class="btn" id="btnFindImagesByKeyword"><i class="icon-search"></i>&nbsp;Search</button>--}%
%{--            <a class="btn btn-info" id="btnAdvancedSearch" href="${createLink(controller:'search', action:'index')}"><i class="icon-cog icon-white"></i>&nbsp;Advanced Search</a>--}%
%{--        </div>--}%
        <br/>
        <div class="input-group">
            <input id="keyword" aria-label="Buscar imágenes" class="form-control form-text" type="text"
                placeholder="Buscar..."
                   value="${q}" size="20" maxlength="255">
            <span class="input-group-btn">
                <button class="btn-primary btn form-submit" id="btnFindImagesByKeyword">
                    <i id="fa fa-search" class="fa fa-search icono-4x text-white" data-clipboard-text="fa-search"></i>
                </button>
            </span>
            <span class="input-group-btn">
                <a href="${createLink(controller:'search', action:'index')}">
                    <button class="btn-primary btn"  id="btnAdvancedSearch" style="white-space: nowrap;">
                        <i id="fa fa-search" class="fa fa-search-plus icono-2x text-white" data-clipboard-text="fa-search"></i>
                        Búsqueda avanzada
                    </button>
                </a>
            </span>
        </div>

        <g:render template="imageThumbnails" model="${[images: images, totalImageCount: totalImageCount, allowSelection: isLoggedIn, selectedImageMap: selectedImageMap, thumbsTitle:"${totalImageCount}"]}" />

    <r:script>
            $(document).ready(function() {

                $("#btnFindImagesByKeyword").click(function(e) {
                    e.preventDefault();
                    doSearch();
                });

                $("#keyword").keydown(function(e) {
                    if (e.which == 13) {
                        e.preventDefault();
                        doSearch();
                    }
                }).focus();

            });

            function doSearch() {
                var q = $("#keyword").val();
                if (q) {
                    window.location = "${createLink(action:'list')}?q=" + q
                } else {
                    window.location = "${createLink(action:'list')}";
                }
            }

        </r:script>

    </body>
</html>
