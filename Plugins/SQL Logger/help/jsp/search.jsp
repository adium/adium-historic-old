<%@ page import = 'java.sql.*' %>
<%@ page import = 'javax.sql.*' %>
<%@ page import = 'javax.naming.*' %>
<%@ page import = 'java.util.List' %>
<%@ page import = 'java.util.ArrayList' %>
<%@ page import = 'java.util.Map' %>
<%@ page import = 'java.util.HashMap' %>
<%@ page import = 'org.slamb.axamol.library.*' %>
<%@ page import = 'java.io.File' %>
<%@ page import = 'sqllogger.*' %>

<%
Context env = (Context) new InitialContext().lookup("java:comp/env/");
DataSource source = (DataSource) env.lookup("jdbc/postgresql");
Connection conn = source.getConnection();

String searchFormURL = new String("saveForm.jsp?action=saveSearch.jsp");
int search_id = Util.checkInt(request.getParameter("search_id"));

String date_start, date_finish;

String sender = Util.checkNull(request.getParameter("sender"), false);
searchFormURL += "&amp;sender=" + Util.safeString(sender);

String recipient = Util.checkNull(request.getParameter("recipient"), false);
searchFormURL += "&amp;recipient=" + Util.safeString(recipient);

String searchString = Util.checkNull(request.getParameter("search"), false);
searchFormURL += "&amp;searchString=" + Util.safeString(searchString);

String service = Util.checkNull(request.getParameter("service"));
searchFormURL += "&amp;service=" + Util.safeString(service);

String orderBy = Util.checkNull(request.getParameter("order_by"));

String ascDesc = Util.checkNull(request.getParameter("asc_desc"));
searchFormURL += "&amp;orderBy=" + Util.safeString(orderBy);

date_finish = Util.checkNull(request.getParameter("finish"));
searchFormURL += "&amp;date_finish=" + Util.safeString(date_finish);

date_start = Util.checkNull(request.getParameter("start"));
searchFormURL += "&amp;date_start=" + Util.safeString(date_start);

String title = new String();
String notes = new String();

ResultSet rset = null;
SQLWarning warning = null;

long beginTime = 0;
long queryTime = 0;

String searchKey = new String();

searchKey = searchString;

File queryFile = new File(session.getServletContext().getRealPath("queries/standard.xml"));
LibraryConnection lc = new LibraryConnection(queryFile, conn);
Map params = new HashMap();

try {
if(search_id != 0) {
        params.put("search_id", new Integer(search_id));

        rset = lc.executeQuery("saved_search", params);

        if(rset != null && rset.next()) {
            title = rset.getString("title");
            notes = rset.getString("notes");
            sender = rset.getString("sender");
            recipient = rset.getString("recipient");
            searchString = rset.getString("searchstring");
            date_start = rset.getString("date_start");
            date_finish = rset.getString("date_finish");
            orderBy = rset.getString("orderby");
        }
    } else {
        title = "Search";
    }

    String searchType = new String();

    // Check if tsearch types exist
    rset = lc.executeQuery("check_for_tsearch", params);

    if (rset != null && !rset.isBeforeFirst()) {
        searchType = "search_none";
    } else {
        rset.next();
        if(rset.getString(1).equals("txtidx")) {
            searchType = "search_tsearch1";
        } else if (rset.getString(1).equals("tsquery")) {
            searchType = "search_tsearch2";
        }
    }

%>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<title>SQL Logger: Search</title>
<meta http-equiv="content-type" content="text/html; charset=iso-8859-1" />
<link rel="stylesheet" type="text/css" href="styles/layout.css" />
<link rel="stylesheet" type="text/css" href="styles/default.css" />
<link rel="shortcut icon" href="favicon.ico" type="image/x-icon" />
<script language="javascript" type="text/javascript">
 function OpenLink(c){
   window.open(c, 'link', 'width=480,height=480,scrollbars=yes,status=yes,toolbar=no');
 }
</script>
<script lanaguage = "JavaScript">
    window.name='search';
</script>
<script language="JavaScript" src="calendar.js"></script>
</head>
<body>
	<div id="container">
	   <div id="header">
	   </div>
	   <div id="banner">
            <div id="bannerTitle">
                <img class="adiumIcon" src="images/headlines/search.png" width="128" height="128" border="0" alt="Search" />
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
                    <li><a href="users.jsp">Users</a></li>
                    <li><a href="meta.jsp">Meta-Contacts</a></li>
                    <li><a href="chats.jsp">Chats</a></li>
                    <li><a href="statistics.jsp">Statistics</a></li>
                    <li><a href="query.jsp">Query</a></li>
                </ul>
            </div>
            <div id="sidebar-a">
                <h1>Saved Searches</h1>
                <div class="boxThinTop"></div>
                <div class="boxThinContent">
<%

    rset = lc.executeQuery("saved_searches_list", params);

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
                    <form action="search.jsp" method="post" name="control">
                    <table border="0" cellpadding="3" cellspacing="0">
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
                                "\"");
                        %> id="searchstring" />
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

<% if(searchType.equals("search_tsearch2")) { %>
                                <option value="rank(idxfti, q)"
                                <% if ((searchKey != null &&
                                            orderBy == null) ||
                                    (orderBy != null &&
                                        orderBy.startsWith("rank")))
                                    out.print("selected=\"selected\"") ; %> >Rank</option>
<% } %>
                            </select><br />
                            <input type="radio" name="asc_desc" value=" asc"
                        <% if (orderBy != null && orderBy.endsWith("asc")) %> checked="checked"
                        <%;%> />Ascending<br />

                            <input type="radio" name="asc_desc" value=" desc"
                            <% if ((searchKey != null && orderBy == null) ||
                                (orderBy != null && orderBy.endsWith("desc")))
                                    %> checked="checked"
                            <%;%> />Descending
                            </td>
                        </tr>
                        <tr>
                            <td align="right">
                                <label for="sender">Sender: </label>
                            </td>
                            <td><input type="text" name="sender"
                                value="<%= Util.safeString(sender) %>"
                                id="sender" />
                            </td>
                        </tr>
                        <tr>
                            <td align="right">
                                <label for="recipient">Recipient: </label>
                            </td>
                            <td>
                                <input type="text" name="recipient"
                                    value="<%= Util.safeString(recipient) %>"
                                    id="recipient" />
                            </td>
                        </tr>
                        <tr>
                            <td align="right">
                                <label for="service">Service:</label>
                            </td>
                            <td>
                                <select name="service" id="service">
                                    <option value="0">Choose One</option>
<%

    rset = lc.executeQuery("distinct_services", params);
    while(rset.next()) {
        out.print("<option value=\"" + rset.getString("service") + "\"" );
        if(rset.getString("service").equals(service)) {
            out.print(" selected=\"selected\"");
        }
        out.print(">" + rset.getString("service") + "</option>\n");
    }
%>
                                </select>
                            </td>
                        </tr>
                        <tr>
                            <td align="right">
                                <label for="start_date">Date Range: </label>
                            </td>
                            <td colspan="2">
                                <input type="text" name="start"
                                    value="<%= Util.safeString(date_start) %>"
                                    id="start_date" />
                                <a
                        href="javascript:show_calendar('control.start');"
                        onmouseover="window.status='Date Picker';return true;"
                        onmouseout="window.status='';return true;">
                        <img src="images/calicon.jpg" border=0></a>


                                    <label for="finish_date">
                                        &nbsp;--&nbsp;
                                    </label>
                                    <input type="text" name="finish" <%
                                        if (date_finish != null)
                                            out.print("value=\"" + date_finish + "\"");
                                    %> id="finish_date" />
                                    <a

                    href="javascript:show_calendar('control.finish');"
                    onmouseover="window.status='Date Picker';return true;"
                    onmouseout="window.status='';return true;">
                <img src="images/calicon.jpg" border=0></a>

                            </td>
                        </tr>
                        </table><br />
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
        List exactMatch = new ArrayList();
        int quoteMatch = 1;

        //If the user hasn't installed tsearch, be slow & simple
        if(searchType.equals("search_none")) {

            out.print("<div align=\"center\">");
            out.print("<i>This query is case sensitive for speed.<br>");
            out.print("For a non-case-sensitive, faster query, "+
            "install the tsearch2 module.</i></div>");

            params.put("search", searchString);

            // If the user has installed a tsearch, transform the search string
        } else {

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

            params.put("matchRegexp", exactMatch);
            params.put("search", searchKey);
        }

        params.put("sender", sender);
        params.put("recipient", recipient);
        params.put("dateStart", date_start);
        params.put("dateFinish", date_finish);
        params.put("service", service);

        beginTime = System.currentTimeMillis();
        try {
            rset = lc.executeQuery(searchType, params);
        } catch (SQLException e) {
            out.println("<span style=\"color:red\">" + e.getMessage() +
                "</span>");
        }
        queryTime = System.currentTimeMillis() - beginTime;


        if(rset != null && rset.isBeforeFirst()) {
%>
<div align="center"><i>Query executed in <%=queryTime%> milliseconds</i></div>
<%

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

                String cleanString = searchKey;
                cleanString = cleanString.replaceAll("&", " ");
                cleanString = cleanString.replaceAll("!", " ");
                cleanString = cleanString.replaceAll("\\|", " ");

                out.print("<a href=\"index.jsp?from=" +
                rset.getString("sender_sn") +
                "&amp;to=" + rset.getString("recipient_sn") +
                "&amp;hl=" + cleanString +
                "&amp;message_id=" + rset.getString("message_id") +
                "&amp;time=15#" + rset.getInt("message_id") + "\">");
                out.print("&#177;15&nbsp;");
                out.print("</a>");

                out.print("<a href=\"index.jsp?from=" +
                rset.getString("sender_sn") +
                "&amp;to=" + rset.getString("recipient_sn") +
                "&amp;message_id=" + rset.getString("message_id") +
                "&amp;time=30" +
                "&amp;hl=" + cleanString +
                "#" + rset.getInt("message_id") + "\">");
                out.print("&#177;30&nbsp;");
                out.print("</a>");

                out.print("<span style=\"float:right\">" +
                    rset.getDate("message_date") +
                    "&nbsp;" + rset.getTime("message_date") +
                    "</span></p>\n");

            }

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
%>
            </div>
            <div class="boxWideBottom"></div>
<%
    }

} catch (SQLException e) {
    out.print("<br />" + e.getMessage() + "<br>");
} finally {
    lc.close();
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
