<%@ page import = 'java.sql.*' %>
<%@ page import = 'java.util.Map' %>
<%@ page import = 'java.util.HashMap' %>
<%@ page import = 'org.slamb.axamol.library.*' %>
<%@ page import = 'sqllogger.*' %>

<%
int meta_id;
meta_id = Util.checkInt(request.getParameter("meta_id"));

ResultSet rset = null;
String name = new String();

LibraryConnection lc = (LibraryConnection) request.getAttribute("lc-standard");
Map params = new HashMap();

try {

    params.put("meta_id", new Integer(meta_id));

    rset = lc.executeQuery("meta_info_all_keys", params);
    if(rset.isBeforeFirst()) {
        rset.next();
        name = rset.getString("name");
        rset.beforeFirst();
    }

%>
<html>
    <head><title>Edit Meta-Contact <%= name %></title></head>
    <link rel="stylesheet" type="text/css" href="styles/default.css" />
    <link rel="stylesheet" type="text/css" href="styles/users.css" />
    <body style="background :#fff">
        <form action="updateMeta.jsp" method="get">
            <table border="0" cellpadding="0" cellspacing="5">
            <tr>
            <td align="right" class="header">
            <label for="name">Name</label>
            </td>
            <td>
            <input type="text" name="name" size="20"
                value="<%= name %>"/>
            </td>
            </tr>
<%
    if(rset.isBeforeFirst()) {
        while(rset.next()) {
            out.println("<tr><td align=\"right\">");
            out.println("<label for=\"" + rset.getString("key_name") + "\">" +
                rset.getString("key_name") + "</label>");

            out.println("</td><td>");

            out.println("<input type=\"text\" name=\"" +
                rset.getString("key_id") + "\" size=\"20\" value=\"" +
                rset.getString("value") + "\">");

            out.println("</td></tr>");
        }
    }

%>
            </table>
            <input type="hidden" name="meta_id" value="<%= meta_id %>">
            <div align="right">
                <input type="reset" /><input type="submit" />
            </div>
        </form>
        <p><a href="manageFields.jsp?return=editMeta.jsp?meta_id=<%= meta_id%>">Manage ...</a></p>
    </body>
</html>
<%
} catch (SQLException e) {
    out.println("<br />" + e.getMessage());
}
%>
