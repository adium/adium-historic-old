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

import com.apple.cocoa.foundation.NSArray;

public class SmackBridge implements ConnectionListener {
    NSObject delegate;
    
    public void initSubscriptionMode() {
        Roster.setDefaultSubscriptionMode(Roster.SUBSCRIPTION_MANUAL);
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
    public static boolean isInstanceOfClass(Object instance, String classname) throws ClassNotFoundException {
        return Class.forName(classname).isInstance(instance);
    }
    public static void createRosterEntry(Roster roster, String jid, String name, String group) throws XMPPException {
        String[] grouparray = new String[1];
        grouparray[0] = group;
        
        roster.createEntry(jid,name,grouparray);
    }
}
