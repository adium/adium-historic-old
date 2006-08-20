//
//  SmackXMPPAsteriskListener.java
//  Adium
//
//  Created by Andreas Monitzer on 2006-08-14.
//  Copyright 2006 Andreas Monitzer. All rights reserved.
//

package net.adium.smackBridge;

import org.jivesoftware.smack.*;
import org.jivesoftware.smack.packet.PacketExtension;
import org.jivesoftware.smack.provider.PacketExtensionProvider;
import org.jivesoftware.smack.provider.ProviderManager;
import com.apple.cocoa.foundation.NSObject;

import java.lang.reflect.*;

public class SmackXMPPAsteriskListener {
    NSObject delegate;
    Object phoneClient;
    
    public static class PhoneStatusExtensionProvider implements PacketExtensionProvider {
        public PhoneStatusExtensionProvider() {
        }
        
        // we need a provider here, since the information is stored in an attribute, which isn't handled by
        // that java beans-using method
        public PacketExtension parseExtension(org.xmlpull.v1.XmlPullParser parser) throws Exception {
            boolean done = false;
            
            // get status from attribute
            PhoneStatusExtension result = new PhoneStatusExtension(parser);
            
            // move to the end of the packet
            while(!done) {
                int eventType = parser.next();
                if(eventType == org.xmlpull.v1.XmlPullParser.END_TAG && parser.getName().equals("phone-status"))
                    done = true;
            }
            return result;
        }
    }
    
    public static class PhoneStatusExtension implements PacketExtension {
        String status;
        
        protected PhoneStatusExtension(String status) {
            this.status = status;
        }
        protected PhoneStatusExtension(org.xmlpull.v1.XmlPullParser parser) {
            this.status = parser.getAttributeValue(getNamespace(),getElementName());
        }
        
        public String getStatus() {
            return status;
        }
   
        public String getElementName() {
            return "phone-status";
        }
        
        public String getNamespace() {
            return "http://jivesoftware.com/xmlns/phone";
        }
        
        public String toXML() {
            StringBuffer buf = new StringBuffer();
            buf.append("<phone-status xmlns=\"http://jivesoftware.com/xmlns/phone\" status=\"").append(status).append("\"/>");
            return buf.toString();
        }
    }
    
    public static void register() {
        ProviderManager.addExtensionProvider("phone-status","http://jivesoftware.com/xmlns/phone",new PhoneStatusExtensionProvider());
    }
    
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
