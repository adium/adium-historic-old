//
//  SmackBridge.java
//  Smack Java Bridge
//
//  Created by Andreas Monitzer on 2006-05-28.
//  Copyright (c) 2006 Andreas Monitzer. All rights reserved.
//

package net.adium.smackBridge;

import com.apple.cocoa.foundation.*;
import org.jivesoftware.smack.*;
import org.jivesoftware.smack.packet.*;
import java.util.*;

public class SmackBridge implements ConnectionListener, PacketListener, org.jivesoftware.smack.filter.PacketFilter {
    NSObject delegate;
    
    public SmackBridge() {
    }
    
    public void setDelegate(NSObject d) {
        delegate = d;
    }
    public NSObject delegate() {
        return delegate;
    }
    
    public void registerConnection(XMPPConnection conn) {
        conn.addConnectionListener(this);
        conn.addPacketListener(this,this);
//        conn.getRoster().addRosterListener(this); // only works when already logged in
        
//        System.err.println("Connected to host " + conn.getHost());
        delegate.takeValueForKey(new Boolean(true),"connection");
    }
    
    public void connectionClosed() {
        delegate.takeValueForKey(new Boolean(false),"connection");
    }
    
    public void connectionClosedOnError(Exception e) {
        delegate.takeValueForKey(e.toString(),"connectionError");
    }
    
    public void processPacket(Packet packet) {
        delegate.takeValueForKey(packet, "newPacket");
    }
    
    public boolean accept(Packet packet) {
        return true;
    }
}
