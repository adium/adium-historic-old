<%@ page import = 'java.sql.*' %>
<%@ page import = 'javax.sql.*' %>
<%@ page import = 'javax.naming.*' %>
<%@ page import = 'java.util.ArrayList' %>

<!DOCTYPE HTML PUBLIC "-//W3C/DTD HTML 4.01 Transitional//EN">
<!--$URL: http://svn.visualdistortion.org/repos/projects/adium/jsp/search.jsp $-->
<!--$Rev: 684 $ $Date: 2004/04/23 04:26:27 $ -->
<%
Context env = (Context) new InitialContext().lookup("java:comp/env/");
DataSource source = (DataSource) env.lookup("jdbc/postgresql");
Connection conn = source.getConnection();

String searchFormURL = new String("saveSearchForm.jsp?action=saveSearch.jsp");
int search_id = 0;

try {
    search_id = Integer.parseInt(request.getParameter("search_id"));
} catch (NumberFormatException e) {
    search_id = 0;
}

String sender = request.getParameter("sender");
if (sender != null && sender.equals("")) {
    sender = null;
} else if (sender != null) {
    searchFormURL += "&sender=" + sender;
}

String recipient = request.getParameter("recipient");
if (recipient != null && recipient.equals("")) {
    recipient = null;
} else if (recipient != null) {
    searchFormURL += "&recipient=" + recipient;
}

String searchString = request.getParameter("search");
if (searchString == null || searchString.equals("")) {
    searchString = null;
} else {
    searchFormURL += "&searchString=" + searchString;
}

String orderBy = request.getParameter("order_by");

if (orderBy != null && orderBy.equals("")) {
    orderBy = null;
}

String ascDesc = request.getParameter("asc_desc");
if(orderBy != null){
    orderBy += ascDesc;
    searchFormURL += "&orderBy=" + orderBy;
}
String title = new String();
String notes = new String();

PreparedStatement pstmt = null;
ResultSet rset = null;

try {
    if(search_id != 0) {
        pstmt = conn.prepareStatement("select title, notes, sender, recipient, searchstring, orderby from adium.saved_searches where search_id = ?");
        
        pstmt.setInt(1, search_id);

        rset = pstmt.executeQuery();

        if(rset != null && rset.next()) {
            title = rset.getString("title");
            notes = rset.getString("notes");
            sender = rset.getString("sender");
            recipient = rset.getString("recipient");
            searchString = rset.getString("searchstring");
            orderBy = rset.getString("orderby");
        }
    }

%>
<html>
    <head>
        <title>Adium Search</title>
    </head>
    <body bgcolor="#ffffff">
    <form action="search.jsp" method="POST">
        <table border="0"><tr><td><fieldset>
            <legend>Text Search</legend>
            <label for="sender">Sender: </label>
            <input type="text" name="sender"
            <% if (sender != null) 
                out.print("value=\"" + sender + "\""); %> id="sender">
            <br />
            <label for="recipient">Recipient: </label>
            <input type="text" name="recipient"
            <% if (recipient != null)
                out.print("value=\"" + recipient + "\""); %> id="recipient">
            <br />
            <label for="searchstring">Search String: </label>
            <input type="text" name="search" 
            <%
            if (searchString != null) 
                out.print("value=\"" + searchString.replaceAll("\"","&quot;") +
                "\"");%> id="searchstring">
            
        </fieldset></td><td>
        <fieldset>
        <legend>Order By</legend>
        <table border="0">
        <tr>
            <td rowspan="2">
                <select name="order_by">
                    <option value="" 
                    <% if (orderBy == null) %> selected="" <% ; %>
                    >Choose One</option>
                    <option value="message_date"
                    <% if (orderBy != null &&
                    orderBy.startsWith("message_date"))
                    %> selected="" <% ; %> >Date</option>
                    <option value="sender_sn"
                    <% if (orderBy != null && orderBy.startsWith("sender_sn"))
                    %> selected="" <% ; %> >Sender</option>
                    <option value="recipient_sn"
                    <% if (orderBy != null &&
                    orderBy.startsWith("recipient_sn")) %> selected="" <% ; %> >Recipient</option>
                    <option value="message" 
                    <% if (orderBy != null && orderBy.startsWith("message")
                    && !orderBy.startsWith("message_date"))
                    %> selected="" <% ; %> >Message</option>

                    <option value="rank(idxfti, q)"
                    <% if (orderBy != null && orderBy.startsWith("rank"))
                    %> selected="" <% ; %> >Rank</option>
                </select>
            </td>
        <td><input type="radio" name="asc_desc" value=" asc"
        <% if (orderBy == null || orderBy.endsWith("asc")) %> checked="true"
        <%;%>>Ascending</td></tr>
        <tr><td>
        <input type="radio" name="asc_desc" value=" desc"
        <% if (orderBy != null && orderBy.endsWith("desc")) %> checked="true"
        <%;%>>Descending</td></tr></table>
        </fieldset></td></tr></table> 
        <input type="reset" />
        <input type="submit" />
    </form>
        <a href="#" onClick="window.open('<%= searchFormURL %>', 'Save Search', 'width=275,height=225')">
        Save Search
        </a>
    <%
SQLWarning warning;

long beginTime = 0;
long queryTime = 0;

String searchKey = new String();

searchKey = searchString;

    pstmt = conn.prepareStatement("select search_id, title from adium.saved_searches");
    rset = pstmt.executeQuery();

    out.println("<form>");
    
    out.println("<select name=\"search_id\" />");
    out.println("<option value=\"0\" selected=\"yes\">Choose One</option>");
    while(rset.next()) {
        out.println("<option value=\"" + rset.getString("search_id") +
            "\">" + rset.getString("title") + "</option>");
    }
    out.println("</select>");

    out.println("<input type=\"submit\">");

    out.println("</form>");

    if (searchString != null) {
        ArrayList exactMatch = new ArrayList();
        int quoteMatch = 1;
        String searchType = new String();

        pstmt = conn.prepareStatement("select typname " +
            " from pg_catalog.pg_type t "+
            " where typname ~ '^txtidx$' " +
            " or typname ~ '^tsquery$' and " +
            " pg_catalog.pg_type_is_visible(t.oid) " +
            " order by typname");

        rset = pstmt.executeQuery();

        if (rset != null && !rset.isBeforeFirst()) {
            searchType = "none";
        } else {
            rset.next();
            if(rset.getString(1).equals("txtidx")) {
                searchType = "tsearch1";
            } else if (rset.getString(1).equals("tsquery")) {
                searchType = "tsearch2";
            }
        }
        if(searchType.equals("none")) {
            out.print("<div align=\"center\">");
            out.print("<i>This query is case sensitive for speed.<br>");
            out.print("For a non-case-sensitive, faster query, "+
            "install the tsearch module.</i></div>");
            
            String shortQuery = new String("select scramble(sender_sn) "+
            "as sender_sn, scramble(recipient_sn) as recipient_sn, " +
            "message, message_date, message_id from message_v where " +
            "message ~ ? ");

            if (sender != null) {
                shortQuery += "and sender_sn like ? ";
            }
            
            if (recipient != null) {
                shortQuery += "and recipient_sn like ? ";
            }

            if (orderBy != null) {
                shortQuery += " order by " + orderBy;
            }

            pstmt = conn.prepareStatement(shortQuery);

            pstmt.setString(1, searchString);

            if (sender != null) {
                pstmt.setString(2, sender);
            }

            if (recipient != null) {
                pstmt.setString(3, recipient);
            }
        }
        else {

            searchKey = searchKey.trim();

            while(quoteMatch >= 0) {
                quoteMatch = searchKey.indexOf('"');
                if(quoteMatch >= 0) {
                    int quoteTwo = searchKey.indexOf('"', quoteMatch + 1);
                    exactMatch.add(searchKey.substring(
                        quoteMatch + 1,
                        quoteTwo));
                    searchKey = searchKey.replaceFirst("\"", "(");
                    searchKey = searchKey.replaceFirst("\"", ")");
                }
            }
            
            while(searchKey.indexOf("  ") >= 0) {
                searchKey = searchKey.replaceAll("  ", " ");
            }
            
            if(searchKey.indexOf("AND") > 0 || 
                searchKey.indexOf("OR") > 0 ||
                searchKey.indexOf("NOT") > 0) {
                searchKey = searchKey.replaceAll(" AND ", "&");
                searchKey = searchKey.replaceAll(" OR ", "|");
                searchKey = searchKey.replaceAll("NOT ", "!");
                searchKey = searchKey.replaceAll(" ", "&");
            } else if (searchKey.indexOf("|") > 0 ||
                        searchKey.indexOf("&") > 0) {
                searchKey = searchKey.replaceAll(" ", "");
            } else {
                searchKey = searchKey.replaceAll(" ", "&");
            }
            
            String cmdAry[] = new String[10]; 
            int cmdCntr = 0;
            String queryString = new String();
            
            if(searchType.equals("tsearch1")) {
            
                queryString = "select scramble(s.username) as sender_sn, "+
                    " scramble(r.username) as recipient_sn," +
                    " message, message_date, message_id " +
                    " from adium.messages, adium.users s, adium.users r " +
                    " where " +
                    " messages.sender_id = s.user_id " +
                    " and messages.recipient_id = r.user_id " +
                    " and message_idx ## ? ";
            } else if (searchType.equals("tsearch2")) {
                queryString = "select scramble(s.username) as sender_sn, "+
                    " scramble(r.username) as recipient_sn, " +
                    " headline(message, q) as message, message_date, " +
                    " message_id " +
                    " from adium.messages, adium.users s, adium.users r, "+
                    " to_tsquery(?) as q " +
                    " where messages.sender_id = s.user_id " +
                    " and messages.recipient_id = r.user_id " +
                    " and idxfti @@ q ";

                if (orderBy == null) {
                    orderBy = "rank(idxFTI, q) desc";
                }
            }

            cmdAry[cmdCntr++] = new String(searchKey);

            if (sender != null) {
                queryString += "and s.username like ?";
                cmdAry[cmdCntr++] = new String(sender);
            }

            if (recipient != null) {
                queryString += " and r.username like ? ";
                cmdAry[cmdCntr++] = new String(recipient);
            }

            for (int i=0; i < exactMatch.size(); i++) {
                queryString += " and message ~* ? ";
                cmdAry[cmdCntr++] = new String((String) exactMatch.get(i));
            }

            if (orderBy != null) {
                queryString += " order by " + orderBy;
            }

            pstmt = conn.prepareStatement(queryString);
            for(int i=0; i< cmdCntr;i++) {
                pstmt.setString(i+1,cmdAry[i]);
            }

        }
        beginTime = System.currentTimeMillis();

        rset = pstmt.executeQuery();

        queryTime = System.currentTimeMillis() - beginTime;
    }
    
    if(rset != null && rset.isBeforeFirst()) {
%>
<div align="center"><i>Query executed in <%=queryTime%> milliseconds</i></div>
    <table border=1>
        <tr>
            <td><b>Sender:Recipient</b><br><b>Date</b></td>
            <td><b>Message</b></td>
            <td><b>Minutes</b></td>
        </tr>
<%
    } else if (rset != null && !rset.isBeforeFirst()) {
        out.print("<div align=\"center\"><i>No results found.</i>");
        warning = conn.getWarnings();
        if(warning != null) {
            out.print("<br />" + warning.getMessage());
            while(warning.getNextWarning() != null) {
                out.print("<br>" + warning.getMessage());
            }
        }
        warning = rset.getWarnings();
        if(warning != null) {
            out.print("<br />" + warning.getMessage());
            while(warning.getNextWarning() != null) {
                out.print("<br />" + warning.getMessage());
            }
        }
        out.print("</div>");
    }

    while(rset != null && rset.next()) {
        warning = rset.getWarnings();
        if(warning != null) {
            out.print("<br />" + warning.getMessage());
            while(warning.getNextWarning() != null) {
                out.print("<br />" + warning.getMessage());
            }
        }
        String messageContent = rset.getString("message");
        messageContent = messageContent.replaceAll("\n", "<br>");
        messageContent = messageContent.replaceAll("   ", " &nbsp; ");
        
        out.print("<tr>");
        out.print("<td>" + rset.getString("sender_sn") + 
        ": " + rset.getString("recipient_sn") + "<br>");
        out.print(rset.getString("message_date") + "</td>");
        out.print("<td>" + messageContent + "</td>");
        
        Timestamp dateTime = rset.getTimestamp("message_date");
        long time = dateTime.getTime();
        long beforeTime = time + 15*60*1000;
        long afterTime = time - 15*60*1000;
        long beforeThirty = time + 30*60*1000;
        long afterThirty = time - 30*60*1000;

        Timestamp before = new Timestamp(beforeTime);
        Timestamp after = new Timestamp(afterTime);

        Timestamp thirtyBefore = new Timestamp(beforeThirty);
        Timestamp thirtyAfter = new Timestamp(afterThirty);

        String cleanString = searchKey;
        cleanString = cleanString.replaceAll("&", " ");
        cleanString = cleanString.replaceAll("!", " ");
        cleanString = cleanString.replaceAll("\\|", " ");

        out.print("<td><a href=\"index.jsp?from=" +
        rset.getString("sender_sn") +
        "&to=" + rset.getString("recipient_sn") +
        "&before=" + before.toString() +
        "&after=" + after.toString() + 
        "&hl=" + cleanString +
        "#" + rset.getInt("message_id") + "\">");
        out.print("+/-&nbsp;15&nbsp;");
        out.print("</a><br>");

        out.print("<a href=\"index.jsp?from=" +
        rset.getString("sender_sn") +
        "&to=" + rset.getString("recipient_sn") +
        "&before=" + thirtyBefore.toString() +
        "&after=" + thirtyAfter.toString() + 
        "&hl=" + cleanString +
        "#" + rset.getInt("message_id") + "\">");
        out.print("+/-&nbsp;30&nbsp;");
        out.print("</a></td>");

        out.print("</tr>");
    }
} catch (SQLException e) {
    out.print(e.getMessage() + "<br>");
} finally {
    if (pstmt != null) {
        pstmt.close();
    }
    conn.close();
}
%>
</table>
</body>
</html>
