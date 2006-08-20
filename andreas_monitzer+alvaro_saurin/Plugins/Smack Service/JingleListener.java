//
//  JingleListener.java
//  Adium
//
//  Created by Andreas Monitzer on 2006-08-10.
//  Copyright 2006 Andreas Monitzer. All rights reserved.
//

package net.adium.smackBridge;

import org.jivesoftware.smack.*;
import org.jivesoftware.smackx.jingle.*;
import org.jivesoftware.smackx.nat.STUNResolver;
import com.apple.cocoa.foundation.NSObject;

import java.lang.reflect.*;

public class JingleListener {
    final NSObject delegate;
    Object manager;
    ClassLoader jingleClassLoader;
    
    public JingleListener(XMPPConnection conn, final NSObject delegate, ClassLoader jingleClassLoader) throws ClassNotFoundException, InstantiationException, NoSuchMethodException, IllegalAccessException, InvocationTargetException {
        Object resolver = jingleClassLoader.loadClass("org.jivesoftware.smackx.nat.STUNResolver").newInstance();
        Class jingleManagerClass = jingleClassLoader.loadClass("org.jivesoftware.smackx.jingle.JingleManager");
        Class sessionRequestListener = jingleClassLoader.loadClass("org.jivesoftware.smackx.jingle.JingleListener$SessionRequest");
        
        manager = jingleManagerClass.getConstructor(new Class[] { XMPPConnection.class, jingleClassLoader.loadClass("org.jivesoftware.smackx.nat.TransportResolver") }).newInstance(new Object[] { conn, resolver });
        
        jingleManagerClass.getMethod("addJingleSessionRequestListener",new Class[] { sessionRequestListener }).invoke(manager,
          Proxy.newProxyInstance(jingleClassLoader, new Class[] { sessionRequestListener }, new InvocationHandler() {
              public Object invoke(Object proxy, Method method, Object[] args) throws Throwable {
                  if(method.getName().equals("sessionRequested")) {
                      delegate.takeValueForKey(args[0], "sessionRequested");
                  }
                  return null;
              }
          }));
        
        this.jingleClassLoader = jingleClassLoader;
        this.delegate = delegate;
    }
    
    public static JingleListener getInstance(XMPPConnection conn, NSObject delegate, ClassLoader jingleClassLoader) throws ClassNotFoundException, InstantiationException, NoSuchMethodException, IllegalAccessException, InvocationTargetException {
        return new JingleListener(conn,delegate,jingleClassLoader);
    }
    
    public Object getManager() {
        return manager;
    }
}
