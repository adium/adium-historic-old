<%@ page import = 'java.sql.*' %>
<%@ page import = 'javax.sql.*' %>
<%@ page import = 'javax.naming.*' %>
<%@ page import = 'java.util.ArrayList' %>
<%
Context env = (Context) new InitialContext().lookup("java:comp/env/");
DataSource source = (DataSource) env.lookup("jdbc/postgresql");
Connection conn = source.getConnection();

String searchFormURL = new String("saveForm.jsp?action=saveSearch.jsp");
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
    searchFormURL += "&amp;sender=" + sender;
}

String recipient = request.getParameter("recipient");
if (recipient != null && recipient.equals("")) {
    recipient = null;
} else if (recipient != null) {
    searchFormURL += "&amp;recipient=" + recipient;
}

String searchString = request.getParameter("search");
if (searchString == null || searchString.equals("")) {
    searchString = null;
} else {
    searchFormURL += "&amp;searchString=" + searchString;
}

String orderBy = request.getParameter("order_by");

if (orderBy != null && orderBy.equals("")) {
    orderBy = null;
}

String ascDesc = request.getParameter("asc_desc");
if(orderBy != null){
    orderBy += ascDesc;
    searchFormURL += "&amp;orderBy=" + orderBy;
}
String title = new String();
String notes = new String();

PreparedStatement pstmt = null;
ResultSet rset = null;
SQLWarning warning;

long beginTime = 0;
long queryTime = 0;

String searchKey = new String();

searchKey = searchString;

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
    } else {
        title = "Search";
    }

%>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<title>Adium SQL Logger: Search</title>
<meta http-equiv="content-type" content="text/html; charset=iso-8859-1" />
<link rel="stylesheet" type="text/css" href="styles/layout.css" />
<link rel="stylesheet" type="text/css" href="styles/default.css" />
<link rel="shortcut icon" href="favicon.ico" type="image/x-icon" />
<script language="javascript" type="text/javascript">
 function OpenLink(c){
   window.open(c, 'link', 'width=480,height=480,scrollbars=yes,status=yes,toolbar=no');
 }
</script>
</head>
<body>
	<div id="container">
	   <div id="header">
	   </div>
	   <div id="banner">
            <div id="bannerTitle">
                <img class="adiumIcon" src="images/adiumy/purple.png" width="128" height="128" border="0" alt="Adium X Icon" />
                <div class="text">
                    <h1><%= title %></h1>
                    <p><%= notes %></p>
                </div>
            </div>
        </div>
        <div id="central">
            <div id="navcontainer">
                <ul id="navlist">
                    <li><a href="index.jsp">Viewer</a></li>
                    <li><span id="current">Search</span></li>
                    <li><a href="statistics.jsp">Statistics</a></li>
                    <li><a href="users.jsp">Users</a></li>
                </ul>
            </div>
            <div id="sidebar-a">
                <h1>Saved Searches</h1>
                <div class="boxThinTop"></div>
                <div class="boxThinContent">
<%
    pstmt = conn.prepareStatement("select search_id, title from adium.saved_searches");
    
    rset = pstmt.executeQuery();
    
    while(rset.next()) {
        out.println("<p><a href=\"search.jsp?search_id=" + 
            rset.getString("search_id") + "\">" + rset.getString("title") +
            "</a></p>");
    }
%>
                    <br />
                        <p>
                        <a href="#" onClick="window.open('<%= searchFormURL %>', 'Save Search', 'width=275,height=225')">
                        Save Search ...</a></p>
                </div>
                <div class="boxThinBottom"></div>
            </div>
            <div id="content">
                <h1>Search</h1>
                <div class="boxWideTop"></div>
                <div class="boxWideContent">
                    <form action="search.jsp" method="post">
                    <table border="0" cellpadding="3" cellspacing="0">
                        <tr>
                            <td align="right">
                                <label for="sender">Sender: </label>
                            </td>
                            <td><input type="text" name="sender"
                        <% if (sender != null) 
                            out.print("value=\"" + sender + "\""); %> id="sender" />
                            </td>
                            <td rowspan="3">
                            <label for="orderBy">Order By</label><br />
                            <select name="order_by" id="orderBy">
                                <option value="" 
                                <% if (orderBy == null) %> selected="selected" <% ; %>
                                >Choose One</option>
                                <option value="message_date"
                                <% if (orderBy != null &&
                                orderBy.startsWith("message_date"))
                                %> selected="selected" <% ; %> >Date</option>
                                <option value="sender_sn"
                                <% if (orderBy != null && orderBy.startsWith("sender_sn"))
                                %> selected="selected" <% ; %> >Sender</option>
                                <option value="recipient_sn"
                                <% if (orderBy != null &&
                                orderBy.startsWith("recipient_sn")) %> selected="selected" <% ; %> >Recipient</option>
                                <option value="message" 
                                <% if (orderBy != null && orderBy.startsWith("message")
                                && !orderBy.startsWith("message_date"))
                                %> selected="selected" <% ; %> >Message</option>
            
                                <option value="rank(idxfti, q)"
                                <% if (orderBy != null && orderBy.startsWith("rank"))
                                %> selected="selected" <% ; %> >Rank</option>
                            </select><br />
                            <input type="radio" name="asc_desc" value=" asc"
                        <% if (orderBy == null || orderBy.endsWith("asc")) %> checked="checked"
                        <%;%> />Ascending<br />
                        
                            <input type="radio" name="asc_desc" value=" desc"
                            <% if (orderBy != null && orderBy.endsWith("desc")) %> checked="checked"
                            <%;%> />Descending
                            </td>
                        </tr>
                        <tr>
                            <td align="right">
                                <label for="recipient">Recipient: </label>
                            </td>
                            <td>
                                <input type="text" name="recipient"
                        <% if (recipient != null)
                            out.print("value=\"" + recipient + "\""); %> id="recipient" />
                            </td>
                        </tr>
                        <tr>
                            <td>
                                <label for="searchstring">Search String: </label>
                            </td>
                            <td>
                                <input type="text" name="search" 
                        <%
                        if (searchString != null) 
                            out.print("value=\"" + 
                                searchString.replaceAll("\"","&quot;") +
                                "\"");%> id="searchstring" />
                            </td>
                        </tr>
                        </table>
                        <div align="right">
                            <input type="reset" />
                            <input type="submit" />
                        </div>
                    </form>
                </div>
                <div class="boxWideBottom"></div>
<%
    if(searchString != null) {
%>

                <h1>Search Results</h1>
                <div class="boxWideTop"></div>
                <div class="boxWideContent">
<%
        searchKey = searchString;
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

    
        if(rset != null && rset.isBeforeFirst()) {
%>
<div align="center"><i>Query executed in <%=queryTime%> milliseconds</i></div>
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
        out.print("<br />");
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
            
            out.print(rset.getString("sender_sn") + 
            ":&#8203;" + rset.getString("recipient_sn"));
            out.print("<p style=\"text-indent: 30px\">" + 
                messageContent + "<br />");
            
            Timestamp dateTime = rset.getTimestamp("message_date");
            long time = dateTime.getTime();
            long finishTime = time + 15*60*1000;
            long startTime = time - 15*60*1000;
            long finishThirty = time + 30*60*1000;
            long startThirty = time - 30*60*1000;
    
            Timestamp finish = new Timestamp(finishTime);
            Timestamp start = new Timestamp(startTime);
    
            Timestamp thirtyFinish = new Timestamp(finishThirty);
            Timestamp thirtyStart = new Timestamp(startThirty);
    
            String cleanString = searchKey;
            cleanString = cleanString.replaceAll("&", " ");
            cleanString = cleanString.replaceAll("!", " ");
            cleanString = cleanString.replaceAll("\\|", " ");
    
            out.print("<a href=\"index.jsp?from=" +
            rset.getString("sender_sn") +
            "&amp;to=" + rset.getString("recipient_sn") +
            "&amp;finish=" + finish.toString() +
            "&amp;start=" + start.toString() + 
            "&amp;hl=" + cleanString +
            "#" + rset.getInt("message_id") + "\">");
            out.print("&#177;15&nbsp;");
            out.print("</a>");
    
            out.print("<a href=\"index.jsp?from=" +
            rset.getString("sender_sn") +
            "&amp;to=" + rset.getString("recipient_sn") +
            "&amp;finish=" + thirtyFinish.toString() +
            "&amp;start=" + thirtyStart.toString() + 
            "&amp;hl=" + cleanString +
            "#" + rset.getInt("message_id") + "\">");
            out.print("&#177;30&nbsp;");
            out.print("</a>");
            
            out.print("<span style=\"float:right\">" + 
                rset.getDate("message_date") + 
                "&nbsp;" + rset.getTime("message_date") +
                "</span></p>\n");
            
        }
%>
            </div>
            <div class="boxWideBottom"></div>
<%
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
        </div>
        <div id="bottom">
            <div class="cleanHackBoth"> </div>
        </div>
        </div>
        <div id="footer">&nbsp;</div>
    </div>
</body>
</html>
