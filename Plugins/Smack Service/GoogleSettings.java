//
//  GoogleSettings.java
//  Adium
//
//  Created by Andreas Monitzer on 2006-08-16.
//  Copyright 2006 Andreas Monitzer. All rights reserved.
//

package net.adium.smackBridge.google;

import org.jivesoftware.smack.packet.IQ;

public class GoogleSettings extends IQ {
    boolean autoAcceptRequests = false;
    boolean mailNotifications = false;
    
    public GoogleSettings() {
    }
    
    public void setAutoAcceptRequests(boolean aar) {
        autoAcceptRequests = aar;
    }
    
    public boolean getAutoAcceptRequests() {
        return autoAcceptRequests;
    }
    
    public void setMailNotifications(boolean mn) {
        mailNotifications = mn;
    }
    
    public boolean getMailNotifications() {
        return mailNotifications;
    }
    
    public String getChildElementXML() {
        StringBuffer buf = new StringBuffer();
        buf.append("<usersetting xmlns=\"google:setting\"><autoacceptrequests value=\"").append(autoAcceptRequests?"true":"false").append("\"/>");
        buf.append("<mailnotifications value=\"").append(mailNotifications?"true":"false").append("\"/></usersetting>");
        
        return buf.toString();
    }
    
    // send-only command, so no provider required
}
