//
//  InvisibleCommand.java
//  Adium
//
//  Created by Andreas Monitzer on 2006-08-06.
//  Copyright 2006 Andreas Monitzer. All rights reserved.
//

package net.adium.smackBridge;

import org.jivesoftware.smack.packet.IQ;
import org.jivesoftware.smack.provider.IQProvider;
import org.xmlpull.v1.XmlPullParser;

public class InvisibleCommand extends IQ {
    boolean isInvisible;
    
    public InvisibleCommand(boolean isInvisible) {
        this.isInvisible = isInvisible;
    }
    
    public void setInvisible(boolean invisible) {
        isInvisible = invisible;
    }
    
    public boolean getInvisible() {
        return isInvisible;
    }
    
    public String getChildElementXML() {
        StringBuilder buf = new StringBuilder();
        buf.append("<" + (isInvisible?"invisible":"visible") + " xmlns=\"http://jabber.org/protocol/invisibility\"/>");
        return buf.toString();
    }
    
    // this is a send-only command, so we don't need a provider
}
