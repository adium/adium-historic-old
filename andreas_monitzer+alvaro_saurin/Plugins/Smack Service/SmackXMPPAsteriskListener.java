//
//  SmackXMPPAsteriskListener.java
//  Adium
//
//  Created by Andreas Monitzer on 2006-08-14.
//  Copyright 2006 Andreas Monitzer. All rights reserved.
//

package net.adium.smackBridge;

import org.jivesoftware.smack.*;
import com.apple.cocoa.foundation.NSObject;

import java.lang.reflect.*;

public class SmackXMPPAsteriskListener {
    NSObject delegate;
    Object phoneClient;
    
    public SmackXMPPAsteriskListener(XMPPConnection connection, ClassLoader classLoader, final NSObject delegate) throws Exception {
        this.delegate = delegate;
        final Class phoneClientClass = classLoader.loadClass("org.jivesoftware.phone.client.PhoneClient");
        try {
            phoneClient = phoneClientClass.getConstructor(XMPPConnection.class).newInstance((Object)connection);
        } catch (Exception e) {
            e.printStackTrace();
            throw e;
        }
        
        // Define the event listener. Since we can't access the phone package directly (it's not in our own class loader, it's only
        // available from the one we got as an argument to this method), we have to use some very complicated proxy stuff to dynamically
        // create the listener at runtime.
        
        final Class eventListenerClass = classLoader.loadClass("org.jivesoftware.phone.client.PhoneEventListener");
        final Method eventListenerHandle = eventListenerClass.getDeclaredMethod("handle",classLoader.loadClass("org.jivesoftware.phone.client.PhoneEvent"));
        
        phoneClientClass.getMethod("addEventListener",new Class[] { eventListenerClass }).invoke(phoneClient,
            Proxy.newProxyInstance(classLoader, new Class[] {eventListenerClass}, new InvocationHandler() {
                public Object invoke(Object proxy, Method method, Object[] args) throws Throwable {
                    if(method.equals(eventListenerHandle)) {
                        delegate.takeValueForKey(args[0],"phoneEvent");
                    }
                    return null;
                }
        }));
    }
    
    public Object getPhoneClient() {
        return phoneClient;
    }
}
