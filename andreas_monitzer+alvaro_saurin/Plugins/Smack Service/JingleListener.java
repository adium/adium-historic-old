//
//  JingleListener.java
//  Adium
//
//  Created by Andreas Monitzer on 2006-08-10.
//  Copyright 2006 Andreas Monitzer. All rights reserved.
//

package net.adium.smackBridge;

import org.jivesoftware.smack.*;
import com.apple.cocoa.foundation.NSObject;

import java.lang.reflect.*;

public class JingleListener {

	private static String CLASSNAME_JINGLEMANAGER		=
		"org.jivesoftware.smackx.jingle.JingleManager";
	
	private static String CLASSNAME_REQUEST_LISTENER	=
		"org.jivesoftware.smackx.jingle.JingleListener$SessionRequest";
	
	private static String CLASSNAME_TRANS_RESOLVER		=
		"org.jivesoftware.smackx.nat.TransportResolver";
    
	private static String CLASSNAME_STUN_RESOLVER		=
		"org.jivesoftware.smackx.nat.STUNResolver";

	final NSObject	delegate;
    Object			manager;
    ClassLoader		jingleClassLoader;
    
	/**
	 * JingleListener constructor.
	 */
    public JingleListener(XMPPConnection conn, final NSObject delegate,
						  ClassLoader jingleClassLoader)
		throws ClassNotFoundException, InstantiationException, NoSuchMethodException,
			IllegalAccessException, InvocationTargetException {

        Object resolver = jingleClassLoader.loadClass(CLASSNAME_STUN_RESOLVER).newInstance();
        Class jingleManagerClass = jingleClassLoader.loadClass(CLASSNAME_JINGLEMANAGER);
        Class sessionRequestListener = jingleClassLoader.loadClass(CLASSNAME_REQUEST_LISTENER);
        
        manager = jingleManagerClass.getConstructor(new Class[] {
			XMPPConnection.class,
			jingleClassLoader.loadClass(CLASSNAME_TRANS_RESOLVER) }).newInstance(new Object[] {
				conn,
				resolver });
        
		InvocationHandler invokeHandler = new InvocationHandler() {
			public Object invoke(Object proxy, Method method, Object[] args) throws Throwable {
				if(method.getName().equals("sessionRequested")) {
					delegate.takeValueForKey(args[0], "sessionRequested");
				}
				return null;
			}
		};
		
        jingleManagerClass.getMethod("addJingleSessionRequestListener",
			new Class[] { sessionRequestListener }).invoke(manager,
					Proxy.newProxyInstance(jingleClassLoader,
						new Class[] { sessionRequestListener },
						invokeHandler ));
        
        this.jingleClassLoader = jingleClassLoader;
        this.delegate = delegate;
    }
    
	/**
	 * Get the unique instance.
	 */
    public static JingleListener getInstance(XMPPConnection conn, NSObject delegate, ClassLoader jingleClassLoader) throws ClassNotFoundException, InstantiationException, NoSuchMethodException, IllegalAccessException, InvocationTargetException {
        return new JingleListener(conn,delegate,jingleClassLoader);
    }

    /**
	 * Get the manager. 
	 */
    public Object getManager() {
        return manager;
    }
}
