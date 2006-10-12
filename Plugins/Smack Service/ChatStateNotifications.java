//
//  ChatStateNotifications.java
//  Adium
//
//  Created by Andreas Monitzer on 2006-07-24.
//  Copyright 2006 Andreas Monitzer. All rights reserved.
//

package net.adium.smackBridge;

import org.jivesoftware.smack.packet.PacketExtension;
import org.jivesoftware.smack.packet.Message;
import org.jivesoftware.smack.provider.ProviderManager;

public class ChatStateNotifications implements PacketExtension {
    public String getElementName() {
        return null;
    }
    
    public String getNamespace() {
        return "http://jabber.org/protocol/chatstates";
    }
    
    public String toXML() {
        StringBuffer buf = new StringBuffer();
        buf.append("<").append(getElementName()).append(" xmlns=\"").append(getNamespace()).append("\"/>");
        return buf.toString();
    }
    
    static public void register() {
        ProviderManager.addExtensionProvider("active","http://jabber.org/protocol/chatstates", active.class);
        ProviderManager.addExtensionProvider("composing","http://jabber.org/protocol/chatstates", composing.class);
        ProviderManager.addExtensionProvider("paused","http://jabber.org/protocol/chatstates", paused.class);
        ProviderManager.addExtensionProvider("inactive","http://jabber.org/protocol/chatstates", inactive.class);
        ProviderManager.addExtensionProvider("gone","http://jabber.org/protocol/chatstates", gone.class);
    }
    
    static public ChatStateNotifications getChatState(Message message) {
        ChatStateNotifications result;
        result = (ChatStateNotifications)message.getExtension("active","http://jabber.org/protocol/chatstates");
        if(result != null)
            return result;
        result = (ChatStateNotifications)message.getExtension("composing","http://jabber.org/protocol/chatstates");
        if(result != null)
            return result;
        result = (ChatStateNotifications)message.getExtension("paused","http://jabber.org/protocol/chatstates");
        if(result != null)
            return result;
        result = (ChatStateNotifications)message.getExtension("inactive","http://jabber.org/protocol/chatstates");
        if(result != null)
            return result;
        result = (ChatStateNotifications)message.getExtension("gone","http://jabber.org/protocol/chatstates");
        if(result != null)
            return result;
        return null;
    }
    static public ChatStateNotifications createChatState(String type) {
        if(type.equals("active"))
            return new active();
        if(type.equals("composing"))
            return new composing();
        if(type.equals("paused"))
            return new paused();
        if(type.equals("inactive"))
            return new inactive();
        if(type.equals("gone"))
            return new gone();
        return null;
    }
    
    static public class active extends ChatStateNotifications {
        public String getElementName() {
            return "active";
        }
    }
    static public class composing extends ChatStateNotifications {
        public String getElementName() {
            return "composing";
        }
    }
    static public class paused extends ChatStateNotifications {
        public String getElementName() {
            return "paused";
        }
    }
    static public class inactive extends ChatStateNotifications {
        public String getElementName() {
            return "inactive";
        }
    }
    static public class gone extends ChatStateNotifications {
        public String getElementName() {
            return "gone";
        }
    }
}
