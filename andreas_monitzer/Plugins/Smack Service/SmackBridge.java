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
import org.jivesoftware.smack.filter.*;
import java.util.*;

public class SmackBridge implements ConnectionListener {
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
        conn.addPacketListener(new PacketListener() {
            public void processPacket(Packet packet) {
                delegate.takeValueForKey(packet, "newMessagePacket");
            }
        },new PacketTypeFilter(Message.class));
        conn.addPacketListener(new PacketListener() {
            public void processPacket(Packet packet) {
                delegate.takeValueForKey(packet, "newPresencePacket");
            }
        },new PacketTypeFilter(Presence.class));
        conn.addPacketListener(new PacketListener() {
            public void processPacket(Packet packet) {
                delegate.takeValueForKey(packet, "newIQPacket");
            }
        },new PacketTypeFilter(IQ.class));
        
        delegate.takeValueForKey(new Boolean(true),"connection");
    }
    
    public void connectionClosed() {
        delegate.takeValueForKey(new Boolean(false),"connection");
    }
    
    public void connectionClosedOnError(Exception e) {
        delegate.takeValueForKey(e.toString(),"connectionError");
    }
    
    public boolean accept(Packet packet) {
        return true;
    }
    
    public static Object getStaticFieldFromClass(String fieldname, String classname) throws ClassNotFoundException, NoSuchFieldException, IllegalAccessException {
        return Class.forName(classname).getField(fieldname).get(null);
    }
}
