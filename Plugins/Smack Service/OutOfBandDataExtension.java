//
//  OutOfBandDataExtension.java
//  Adium
//
//  Created by Andreas Monitzer on 2006-07-24.
//  Copyright 2006 Andreas Monitzer. All rights reserved.
//

package net.adium.smackBridge;

import org.jivesoftware.smack.packet.PacketExtension;
import org.jivesoftware.smack.provider.ProviderManager;

public class OutOfBandDataExtension implements PacketExtension {
    String url;
    String desc;
    
    static public void register() {
        ProviderManager.addExtensionProvider(getConstantElementName(),
                                             getConstantNamespace(),
                                             OutOfBandDataExtension.class);
    }
    
    public OutOfBandDataExtension() {
        url = "";
        desc = null;
    }

    static public String getConstantElementName() {
        return "x";
    }
    
    public String getElementName() {
        return OutOfBandDataExtension.getConstantElementName();
    }
    
    static public String getConstantNamespace() {
        return "jabber:x:oob";
    }
    
    public String getNamespace() {
        return OutOfBandDataExtension.getConstantNamespace();
    }
    
    public void setUrl(String url) {
        this.url = url;
    }
    
    public String getUrl() {
        return url;
    }
    
    public void setDesc(String desc) {
        this.desc = desc;
    }
    
    public String getDesc() {
        return desc;
    }
    
    public String toXML() {
        StringBuffer buf = new StringBuffer();
        buf.append("<").append(getElementName()).append(" xmlns=\"").append(getNamespace()).append("\">");
        buf.append("<url>").append(url).append("</url>");
        if(desc != null && desc.length() > 0)
            buf.append("<desc>").append(desc).append("</desc>");
        buf.append("</").append(getElementName()).append(">");
        return buf.toString();
    }
}
