<html>
    <head><title>Add Meta-Contact</title></head>
    <body>
        <form action="insertNewMeta.jsp" method="get">
            <label for="name"><b>Name</b></label><br />
            <input type="text" name="name" size="30" /><br /><br />

            <label for="url"><b>URL</b></label><br />
            <input type="text" name="url" size="30"><br /><br />

            <label for="email"><b>Email</b></label><br />
            <input type="text" name="email" size="30"><br /><br />

            <label for="location"><b>Location</b></label><br />
            <input type="text" name="location" size="30"><br /><br />

            <label for="notes"><b>Notes</b></label><br />
            <textarea rows="6" cols="30" name="notes"></textarea><br />
            <br />

            <div align="right">
                <input type="submit">
            </div>
        </form>
    </body>
</html>
