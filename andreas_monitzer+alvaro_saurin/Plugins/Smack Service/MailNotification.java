//
//  MailNotification.java
//  Adium
//
//  Created by Andreas Monitzer on 2006-08-16.
//  Copyright 2006 Andreas Monitzer. All rights reserved.
//

package net.adium.smackBridge.google;

import org.jivesoftware.smack.packet.IQ;
import org.jivesoftware.smack.provider.ProviderManager;

public class MailNotification extends IQ {
    
    static public void registerIQ() {
        ProviderManager.addIQProvider("new-mail","google:mail:notify",MailNotification.class);
    }
    
    public String getChildElementXML() {
        return "<new-mail xmlns=\"google:mail:notify\"/>";
    }
}
