<%@ page import='java.sql.*' %>
<%@ page import='javax.sql.*' %>
<%@ page import='javax.naming.*' %>
<%@ page import='java.util.Properties' %>
<%@ page import='java.util.Enumeration' %>
<%@ page import='java.util.List' %>
<%@ page import='java.util.ArrayList' %>
<%@ page import = 'org.slamb.axamol.library.*' %>
<%@ page import = 'java.io.File' %>
<%@ page import = 'java.util.Map' %>
<%@ page import = 'java.util.HashMap' %>

<!--$URL: http://svn.visualdistortion.org/repos/projects/sqllogger/jsp/updateLogin.jsp $-->
<!--$Rev: 922 $ $Date$-->
<%

Context env = (Context) new InitialContext().lookup("java:comp/env/");
DataSource source = (DataSource) env.lookup("jdbc/postgresql");
Connection conn = source.getConnection();

File queryFile = new File(session.getServletContext().getRealPath("queries/update.xml"));

LibraryConnection lc = new LibraryConnection(queryFile, conn);
Map params = new HashMap();

Enumeration e = request.getParameterNames();

List l = new ArrayList();

while(e.hasMoreElements()) {
    l.add(new Integer((String) e.nextElement()));
}

int rowsAffected = 0;

try {
    params.put("user_list", l);
    rowsAffected = lc.executeUpdate("remove_login_user", params);

    out.println(rowsAffected + "<br />");

    rowsAffected = lc.executeUpdate("add_login_user", params);

    out.println(rowsAffected + "<br />");

    response.sendRedirect("users.jsp");
} catch(SQLException err) {
    out.println("<br />Error!\n");
    out.print(err.getMessage());
}

finally {
conn.close();
}

%>
</body>
</html>
