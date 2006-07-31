//
//  VCardUpdateExtension.java
//  Adium
//
//  Created by Andreas Monitzer on 2006-07-31.
//  Copyright 2006 Andreas Monitzer. All rights reserved.
//

package net.adium.smackBridge;

import org.jivesoftware.smack.packet.PacketExtension;
import org.jivesoftware.smack.provider.ProviderManager;

public class VCardUpdateExtension implements PacketExtension {
    String photo = null;

    static public void register() {
        ProviderManager.addExtensionProvider("x",
                                             "vcard-temp:x:update",
                                             VCardUpdateExtension.class);
    }
    
    public String getElementName() {
        return "x";
    }
    
    public String getNamespace() {
        return "vcard-temp:x:update";
    }
    
    // use setPhoto("") to signal that there's no image to be advertized.
    // use setPhoto(null) to signal that the user is not ready to advertize an image.
    public void setPhoto(String photo) {
        this.photo = photo;
    }
    
    public String getPhoto() {
        return photo;
    }
    
    public String toXML() {
        StringBuffer buf = new StringBuffer();
        if(photo != null) {
            buf.append("<").append(getElementName()).append(" xmlns=\"").append(getNamespace()).append("\">");
            buf.append("<photo>").append(photo).append("</photo>");
            buf.append("</").append(getElementName()).append(">");
        } else {
            buf.append("<").append(getElementName()).append(" xmlns=\"").append(getNamespace()).append("\"/>");
        }
        return buf.toString();
    }
}
