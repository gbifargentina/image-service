<div>

    <g:form name="saveAlbumForm" class="form-horizontal" action="saveAlbum">
        <g:hiddenField name="id" value="${album?.id}" />

        <div class="control-group">
            <label for="name" class="control-label">Name</label>
            <div class="controls">
                <g:textField class="input-xlarge" name="name" id="name" value="${album?.name}" />
            </div>
        </div>

        <div class="control-group">
            <label for="description" class="control-label">Description</label>
            <div class="controls">
                <g:textArea name="description" id="description" class="input-xlarge" value="${album?.description}"/>
            </div>
        </div>

        <div class="control-group">
            <div class="controls">
                <button class="btn" id="btnCancelCreateAlbum">Cancel</button>
                <button class="btn btn-primary" type="submit">Save</button>
            </div>
        </div>

    </g:form>

</div>
<script>

    $("#btnCancelCreateAlbum").click(function(e) {
        e.preventDefault();
        imgvwr.hideModal();
    });

    $("#saveAlbumForm").submit(function(e) {
        var name = $("#name").val();
        if (!name) {
            alert("You need to supply a name!");
            e.preventDefault();
        }
    });

</script>