//
//  JingleListener.java
//  Adium
//
//  Created by Andreas Monitzer on 2006-08-10.
//  Copyright 2006 Andreas Monitzer. All rights reserved.
//

package net.adium.smackBridge;

import org.jivesoftware.smack.*;
import com.apple.cocoa.foundation.*;

import java.lang.reflect.*;

public class SmackXMPPJingleListener {

	private static String CLASSNAME_JINGLESESSION		=
		"org.jivesoftware.smackx.jingle.JingleSession";

	private static String CLASSNAME_JINGLEMANAGER		=
		"org.jivesoftware.smackx.jingle.JingleManager";
	
	private static String CLASSNAME_SESSION_LISTENER =
		"org.jivesoftware.smackx.jingle.JingleListener$Session";
	
	private static String CLASSNAME_REQUEST_LISTENER	=
		"org.jivesoftware.smackx.jingle.JingleListener$SessionRequest";
	
	private static String CLASSNAME_TRANS_RESOLVER		=
		"org.jivesoftware.smackx.nat.TransportResolver";
    
	private static String CLASSNAME_STUN_RESOLVER		=
		"org.jivesoftware.smackx.nat.STUNResolver";


	public static class SessionRequest {

		private final NSObject	delegate;
		private Object			manager;
		private ClassLoader		jingleClassLoader;
		
		private Class			jingleManagerClass;
		private Class			sessionRequestListenerClass;

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
				jingleManagerClass			= jingleClassLoader.loadClass (CLASSNAME_JINGLEMANAGER);
				sessionRequestListenerClass	= jingleClassLoader.loadClass (CLASSNAME_REQUEST_LISTENER);
				
				// Create the jingle manager
				Object resolver = jingleClassLoader.loadClass (CLASSNAME_STUN_RESOLVER).newInstance();
				
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
		public Session (final Object session, final NSObject delegate,
						ClassLoader jingleClassLoader)
			throws ClassNotFoundException, InstantiationException, NoSuchMethodException,
				IllegalAccessException, InvocationTargetException {

			this.jingleClassLoader	= jingleClassLoader;
			this.delegate			= delegate;

			// Create the handler for method requests
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
			
			Class jingleSessionClass	= jingleClassLoader.loadClass (CLASSNAME_JINGLESESSION);
			Class sessionListenerClass	= jingleClassLoader.loadClass (CLASSNAME_SESSION_LISTENER);

			// Register the listener by invoking addListener() on the session
			jingleSessionClass.getMethod ("addListener", new Class[] { sessionListenerClass }).
				invoke (session, Proxy.newProxyInstance (jingleClassLoader,
														 new Class[] { sessionListenerClass },
														 sessionHandler));		
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
