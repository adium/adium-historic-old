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

public class JingleListener implements org.jivesoftware.smackx.jingle.JingleListener.SessionRequest {
    NSObject delegate;
    JingleManager manager;
    
    public JingleListener(XMPPConnection conn, NSObject delegate) {
        STUNResolver resolver = new STUNResolver();
        manager = new JingleManager(conn,resolver);
        manager.addJingleSessionRequestListener(this);
    }
    
    public static JingleListener getInstance(XMPPConnection conn, NSObject delegate) {
        return new JingleListener(conn,delegate);
    }
    
    public void sessionRequested(JingleSessionRequest request) {
        delegate.takeValueForKey(request,"jingleSessionRequest");
    }
    
    public JingleManager getManager() {
        return manager;
    }
}
