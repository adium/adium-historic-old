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
import org.jivesoftware.smackx.ServiceDiscoveryManager;
import org.jivesoftware.smackx.packet.VCard;
import java.util.*;
import java.lang.reflect.Method;

public class SmackBridge implements ConnectionListener {
    NSObject delegate;
    
    static {
        System.setProperty("java.net.preferIPv6Addresses", "true");
        
        // set client identity and name
        ServiceDiscoveryManager.setIdentityName("Adium (via Smack)");
        ServiceDiscoveryManager.setIdentityType("pc");
        
        // set up our own packet extensions and iq provider
        OutOfBandDataExtension.register();
        ChatStateNotifications.register();
        VCardUpdateExtension.register();
    }
    
    public void initSubscriptionMode() {
        Roster.setDefaultSubscriptionMode(Roster.SubscriptionMode.manual);
    }
    
    public void setDelegate(NSObject d) {
        delegate = d;
    }
    public NSObject delegate() {
        return delegate;
    }
    
    public void createConnection(boolean useSSL, ConnectionConfiguration conf) throws XMPPException {
        XMPPConnection conn;
        // ### there's no way to specify a ConnectionConfiguration for an SSLXMPPConnection, wtf?
        
//        if(useSSL)
//            conn = new SSLXMPPConnection(conf, this);
//        else
        conn = new XMPPConnection(conf, this);
        registerConnection(conn);
    }
    
    private void registerConnection(XMPPConnection conn) {
//        conn.addConnectionListener(this);
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
        
        delegate.takeValueForKey(conn,"connection");
    }
    
    public void connectionClosed() {
        delegate.takeValueForKey(new Boolean(true),"disconnection");
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
    
    public static Method getMethod(String classname, String methodname, Vector parameterTypes) throws ClassNotFoundException, NoSuchMethodException, SecurityException {
        Class[] parameterClasses = new Class[parameterTypes.size()];
        for(int i = 0; i < parameterTypes.size(); i++)
        {
            String name = (String)parameterTypes.get(i);
            
            if(name.equals("int"))
                parameterClasses[i] = Integer.TYPE;
            else if(name.equals("boolean"))
                parameterClasses[i] = Boolean.TYPE;
            else if(name.equals("double"))
                parameterClasses[i] = Double.TYPE;
            else if(name.equals("float"))
                parameterClasses[i] = Float.TYPE;
            else if(name.equals("long"))
                parameterClasses[i] = Long.TYPE;
            else if(name.equals("char"))
                parameterClasses[i] = Character.TYPE;
            else if(name.equals("short"))
                parameterClasses[i] = Short.TYPE;
            else
                parameterClasses[i] = Class.forName(name);
        }
        
        return Class.forName(classname).getMethod(methodname,parameterClasses);
    }
    public static Object invokeMethod(Method meth, Object obj, Vector arguments) throws IllegalAccessException, IllegalArgumentException, java.lang.reflect.InvocationTargetException {
        return meth.invoke(obj, arguments.toArray());
    }
    
    public static void createRosterEntry(Roster roster, String jid, String name, String group) throws XMPPException {
        String[] grouparray = new String[1];
        grouparray[0] = group;
        
        roster.createEntry(jid,name,grouparray);
    }
    
    public static void setVCardAvatar(VCard vCard, NSData avatar) {
        vCard.setAvatar(avatar.bytes(0,avatar.length()));
    }
    
    public static NSData getVCardAvatar(VCard vCard) {
        byte[] avt = vCard.getAvatar();
        if(avt == null)
            return null;
        return new NSData(avt);
    }
    
    public static boolean isAvatarEmpty(VCard vCard) {
        byte[] avatar = vCard.getAvatar();
        return avatar == null || avatar.length == 0;
    }
    
    public static List<PrivacyList> getAllPrivacyLists(XMPPConnection connection) throws XMPPException {
        return Arrays.asList(PrivacyListManager.getInstanceFor(connection).getPrivacyLists());
    }
}
