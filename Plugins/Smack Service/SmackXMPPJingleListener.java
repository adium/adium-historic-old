/* 
 * Adium is the legal property of its developers, whose names are listed in the copyright file included
 * with this source distribution.
 * 
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 * General Public License as published by the Free Software Foundation; either version 2 of the License,
 * or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 * the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 * Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along with this program; if not,
 * write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */


package net.adium.smackBridge;

import org.jivesoftware.smack.*;
import com.apple.cocoa.foundation.*;

import java.lang.reflect.*;
import java.net.URL;
import java.util.Enumeration;

public class SmackXMPPJingleListener {

	public final static String STUNSERVERS_FILENAME = "META-INF/stun-config.xml";
	
	private static String CLASSNAME_SESSION	=
		"org.jivesoftware.smackx.jingle.JingleSession";

	private static String CLASSNAME_MANAGER	=
		"org.jivesoftware.smackx.jingle.JingleManager";
	
	private static String CLASSNAME_INPUTSTREAM = 
		"java.io.InputStream";
	
	private static String CLASSNAME_LISTENER = 
		"org.jivesoftware.smackx.jingle.JingleListener";
	
	private static String CLASSNAME_SESSION_LISTENER =
		"org.jivesoftware.smackx.jingle.JingleListener$Session";
	
	private static String CLASSNAME_SESSION_REQ_LISTENER	=
		"org.jivesoftware.smackx.jingle.JingleListener$SessionRequest";
	
	private static String CLASSNAME_TRANS_RESOLVER		=
		"org.jivesoftware.smackx.nat.TransportResolver";
    
	private static String CLASSNAME_STUN_RESOLVER		=
		"org.jivesoftware.smackx.nat.STUNResolver";

	
	
	public static class SessionRequest {

		private final NSObject	delegate;
		private Object			manager;
		private ClassLoader		jingleClassLoader;
		

		/**
		 * JingleListener constructor.
		 */
		public SessionRequest (XMPPConnection conn, final NSObject delegate,
							   ClassLoader jingleClassLoader)
			throws ClassNotFoundException, InstantiationException, NoSuchMethodException,
				IllegalAccessException, InvocationTargetException {
								
				this.jingleClassLoader	= jingleClassLoader;
				this.delegate			= delegate;

				// Load the classes
				Class jingleManagerClass			= jingleClassLoader.loadClass (CLASSNAME_MANAGER);
				Class sessionRequestListenerClass	= jingleClassLoader.loadClass (CLASSNAME_SESSION_REQ_LISTENER);				
				Class jingleSTUNResolverClass		= jingleClassLoader.loadClass (CLASSNAME_STUN_RESOLVER);

				// Create the stream for loading the STUN configuration
				java.io.InputStream stunConfigStream = null;
				URL url = null;
				
				try {
					Enumeration stunConfigEnum = jingleClassLoader.getResources(STUNSERVERS_FILENAME);
					while (stunConfigEnum.hasMoreElements() && stunConfigStream == null) {
						url = (URL) stunConfigEnum.nextElement();						
						stunConfigStream = url.openStream();
					}
				} catch (Exception e) {
					e.printStackTrace();
				}
		
				// Try to load the STUN configuration by invoking the method...
				Object resolver = jingleSTUNResolverClass.newInstance();
				if (stunConfigStream != null) {
					
					try {
						stunConfigStream = url.openStream();
						Method loadSTUNServersMethod = jingleSTUNResolverClass.getMethod ("loadSTUNServers",
												new Class[] { java.io.InputStream.class });
						
						loadSTUNServersMethod.invoke (resolver, new Object [] {	stunConfigStream });
					} catch (Exception e) {
						e.printStackTrace();
					} finally {
						try {
							stunConfigStream.close();							
						} catch (Exception e) {
						}
					}
				}				
				
				// Create the manager
				manager = jingleManagerClass.getConstructor (new Class[] {
					XMPPConnection.class,
					jingleClassLoader.loadClass (CLASSNAME_TRANS_RESOLVER)
				}).newInstance (new Object[] {conn, resolver});

				// Session request handler		
				InvocationHandler sessionRequestedHandler = new InvocationHandler() {
					public Object invoke (Object proxy, Method method, Object[] args) throws Throwable {
						if(method.getName().equals("sessionRequested")) {
							delegate.takeValueForKey(args[0], "sessionRequested");
						}
						return null;
					}
				};
				
				jingleManagerClass.getMethod ("addJingleSessionRequestListener",
						new Class[] { sessionRequestListenerClass }).
					invoke (manager, Proxy.newProxyInstance (
							jingleClassLoader,
							new Class[] { sessionRequestListenerClass },
							sessionRequestedHandler));
			}		
	
		/**
		 * Get the unique instance.
		 */
		public static SmackXMPPJingleListener.SessionRequest getInstance (XMPPConnection conn, NSObject delegate,
												  ClassLoader jingleClassLoader)
			throws ClassNotFoundException, InstantiationException, NoSuchMethodException,
					IllegalAccessException, InvocationTargetException {
				
				return new SmackXMPPJingleListener.SessionRequest (conn,delegate,jingleClassLoader);
		}
		
		/**
		 * Get the manager. 
		 */
		public Object getManager() {
			return manager;
		}		
	}
	
	
	
	public static class Session {

		private final NSObject	delegate;
		private Object			manager;
		private ClassLoader		jingleClassLoader;

		/**
		 * Add a session listener.
		 */
		public Session (final Object session, final NSObject delegate, ClassLoader jingleClassLoader)
			throws ClassNotFoundException, InstantiationException, NoSuchMethodException,
				IllegalAccessException, InvocationTargetException {

			if (session != null && delegate != null && jingleClassLoader != null) {
				
				this.jingleClassLoader	= jingleClassLoader;
				this.delegate			= delegate;
				
				// Create the handler for method requests:
				// This handler will be invoked when a method is called.
				
				InvocationHandler sessionHandler = new InvocationHandler() {
					
					public Object invoke (Object proxy, Method method, Object[] args) throws Throwable {
						
						if (method.getName().equals("sessionEstablished")) {
							delegate.takeValueForKey(new NSDictionary (new Object[] {args[0], args[1], args[2]},
																	   new Object[] {"pt", "rc", "lc"}),
													 "sessionEstablished");
						} else if (method.getName().equals("sessionDeclined")) {
							delegate.takeValueForKey(args[0], "sessionDeclined");
						} else if (method.getName().equals("sessionClosed")) {
							delegate.takeValueForKey(args[0], "sessionClosed");
						} else if (method.getName().equals("sessionClosedOnError")) {
							delegate.takeValueForKey(args[0], "sessionClosedOnError");
						}
						return null;
					}
				};
				
				// Register the listener by invoking addListener() on the session
				Class jingleListenerClass = jingleClassLoader.loadClass (CLASSNAME_LISTENER);
				Class jingleSessionClass = jingleClassLoader.loadClass (CLASSNAME_SESSION);
				Method addListenerMethod = jingleSessionClass.getMethod ("addListener",
																		 new Class[] { jingleListenerClass });
				
				// Invoke the addListener method
				Class sessionListenerClass = jingleClassLoader.loadClass (CLASSNAME_SESSION_LISTENER);
				//addListenerMethod.invoke (session,
				//						  Proxy.newProxyInstance (jingleClassLoader,
				//												  new Class[] { sessionListenerClass },
				//												  sessionHandler));				
			} else {
				throw new IllegalAccessException();
			}
		}
	
		/**
		 * Get a unique instance
		 */
		public static SmackXMPPJingleListener.Session getInstance (Object session,
																   NSObject delegate,
																   ClassLoader jingleClassLoader)
			throws ClassNotFoundException, InstantiationException, NoSuchMethodException,
					IllegalAccessException, InvocationTargetException {
			
			return new SmackXMPPJingleListener.Session (session, delegate, jingleClassLoader);
		}		
	}
}
