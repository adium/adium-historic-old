<%@ page import = 'java.sql.*' %>
<%@ page import = 'javax.naming.*' %>
<%@ page import = 'javax.sql.*' %>

<%
Context env = (Context) new InitialContext().lookup("java:comp/env/");
DataSource source = (DataSource) env.lookup("jdbc/postgresql");
Connection conn = source.getConnection();

int meta_id, user_id;
String service, username, addAll;
boolean all = false;
boolean error = false;

service = request.getParameter("service");
username = request.getParameter("username");
addAll = request.getParameter("all");

try {
    meta_id = Integer.parseInt(request.getParameter("meta_id"));
} catch (NumberFormatException e) {
    meta_id = 0;
}

try {
    user_id = Integer.parseInt(request.getParameter("user_id"));
} catch (NumberFormatException e) {
    user_id = 0;
}

if(service != null && service.equals("")) {
    service = null;
}

if(username != null && username.equals("")) {
    username = null;
}

if(addAll != null && addAll.equals("on")) {
    all = true;
}

PreparedStatement pstmt = null;
ResultSet rs = null;

try {
    if((service != null || username != null) && !all) {
        if(service != null && username != null) {
            pstmt = conn.prepareStatement("select count(*) from users where service = ? and username ilike ?");

            pstmt.setString(1, service);
            pstmt.setString(2, username);
        } else if (service != null && username == null) {
            pstmt = conn.prepareStatement("select count(*) from users where service = ?");

            pstmt.setString(1, service);
        } else if (username != null && service == null) {
            pstmt = conn.prepareStatement("select count(*) from users where username ilike ?");
            pstmt.setString(1, username);
        }

        rs = pstmt.executeQuery();

        rs.next();

        if(rs.getInt(1) > 1) {
            if(username == null) username = "";
            if(service == null) service = "";
            username = username.replaceAll("%", "%25");

            response.sendRedirect("addContact.jsp?meta_id=" +
                meta_id + "&service=" + service + "&username=" +
                username);
        } else if (rs.getInt(1) == 1) {
            if(user_id != 0) {
                error = true;
                out.println("<span style=\"color: red\">Error.  Please de-select a user from the pulldown or remove the typed field.</span>");
            }

            if(service != null && username != null) {
                pstmt = conn.prepareStatement("select user_id from users where service = ? and username ilike ?");

                pstmt.setString(1, service);
                pstmt.setString(2, username);
            } else if (service != null && username == null) {
                pstmt = conn.prepareStatement("select user_id from users where service = ?");

                pstmt.setString(1, service);
            } else if (username != null && service == null) {
                pstmt = conn.prepareStatement("select user_id from users where username ilike ?");
                pstmt.setString(1, username);
            }

            rs = pstmt.executeQuery();

            rs.next();

            user_id = rs.getInt("user_id");
        }
    } else if ((service != null || username != null) && meta_id != 0 && all) {

        if(service != null && username != null) {
            pstmt = conn.prepareStatement("insert into meta_contact (meta_id, user_id) (select ?, user_id from users where service = ? and username ilike ?)");

            pstmt.setInt(1, meta_id);
            pstmt.setString(2, service);
            pstmt.setString(3, username);
        } else if (service != null && username == null) {
            pstmt = conn.prepareStatement("insert into meta_contact (meta_id, user_id) (select ?, user_id from users where service = ?)");

            pstmt.setInt(1, meta_id);
            pstmt.setString(2, service);

        } else if (username != null && service == null) {
            pstmt = conn.prepareStatement("insert into meta_contact (meta_id, user_id) (select ?, user_id from users where username ilike ?)");

            pstmt.setInt(1, meta_id);
            pstmt.setString(2, username);
        }

        pstmt.executeUpdate();
    }

    if(meta_id != 0 && user_id != 0) {

        pstmt = conn.prepareStatement("select count(*) from adium.meta_contact where user_id = ?");

        pstmt.setInt(1, user_id);

        rs = pstmt.executeQuery();

        rs.next();

        if(rs.getInt(1) != 0) {
            pstmt = conn.prepareStatement("insert into adium.meta_contact (meta_id, user_id) values (?, ?)");
        } else {
            pstmt = conn.prepareStatement("insert into adium.meta_contact (meta_id, user_id, preferred) values (?, ?, true)");
        }

        pstmt.setInt(1, meta_id);
        pstmt.setInt(2, user_id);

        pstmt.executeUpdate();
    }
    if(!error) {
%>
<html>
<body onLoad="window.opener.parent.location.reload(); window.close()"></body>
</html>
<%
    }
} catch (SQLException e) {
    out.println("<br />" + e.getMessage());
} finally {
    conn.close();
}
%>
