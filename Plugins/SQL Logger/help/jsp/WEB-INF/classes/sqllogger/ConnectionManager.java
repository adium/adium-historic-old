/*
 * $URL$
 * $Id$
 *
 * Scott Lamb
 */

package sqllogger;

import java.util.HashMap;
import java.util.Map;
import java.sql.Connection;
import javax.sql.DataSource;
import javax.naming.Context;
import javax.naming.InitialContext;
import javax.naming.NamingException;
import javax.servlet.ServletContext;
import javax.servlet.ServletContextListener;
import javax.servlet.ServletContextEvent;
import javax.servlet.ServletRequestListener;
import javax.servlet.ServletRequestEvent;
import javax.servlet.ServletRequest;
import org.slamb.axamol.library.Library;
import org.slamb.axamol.library.LibraryConnection;
import org.slamb.axamol.library.SqlUtils;
import java.io.File;
import java.sql.SQLException;

/**
 * Ensures every request gets a database connection and that it's properly
 * destroyed.
 *
 * @author      Scott Lamb &lt;slamb@slamb.org&gt;
 * @version     $Rev$ $Date$
 **/

public class ConnectionManager implements ServletContextListener,
        ServletRequestListener {

    private static final String LIBRARY_NAMES[] = { "standard", "stats", "update" };
    private DataSource dataSource;
    private Map libraries = new HashMap();

    /** Loads the database pool and parses the SQL libraries. */
    public void contextInitialized(ServletContextEvent sce) {
        try {
            Context env = (Context) new InitialContext().lookup("java:comp/env/");
            dataSource = (DataSource) env.lookup("jdbc/postgresql");
        } catch (NamingException e) {
            throw new RuntimeException("Can't find PostgreSQL data source", e);
        }

        ServletContext ctx = sce.getServletContext();
        for (int i = 0; i < LIBRARY_NAMES.length; i++) {
            File libFile = new File(ctx.getRealPath("queries/"
                        + LIBRARY_NAMES[i] + ".xml"));
            libraries.put(LIBRARY_NAMES[i], new Library(libFile));
        }
    }

    public void contextDestroyed(ServletContextEvent sce) {
    }

    /** Gets a connection and associates it with each library. */
    public void requestInitialized(ServletRequestEvent rre) {
        ServletRequest req = rre.getServletRequest();
        Connection conn;

        try {
            conn = dataSource.getConnection();
        } catch (SQLException e) {
            throw new RuntimeException("Can't create connection", e);
        }

        req.setAttribute("conn", conn);
        for (int i = 0; i < LIBRARY_NAMES.length; i++) {
            Library lib = (Library) libraries.get(LIBRARY_NAMES[i]);
            req.setAttribute("lc-" + LIBRARY_NAMES[i],
                             new LibraryConnection(lib, conn));
        }
    }

    /** Cleans up all prepared statements and the connection. */
    public void requestDestroyed(ServletRequestEvent rre) {
        ServletRequest req = rre.getServletRequest();

        for (int i = 0; i < LIBRARY_NAMES.length; i++) {
            ((LibraryConnection) req.getAttribute("lc-" +  LIBRARY_NAMES[i]))
                                    .close();
        }
        SqlUtils.close((Connection) req.getAttribute("conn"));
    }
}
