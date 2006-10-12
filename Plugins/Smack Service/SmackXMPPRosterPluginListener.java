//
//  SmackXMPPRosterPluginListener.java
//  Adium
//
//  Created by Andreas Monitzer on 2006-07-16.
//  Copyright 2006 Andreas Monitzer. All rights reserved.
//

package net.adium.smackBridge;

import org.jivesoftware.smack.RosterListener;
import java.util.Collection;
import com.apple.cocoa.foundation.NSObject;

public class SmackXMPPRosterPluginListener implements RosterListener {
    NSObject delegate;
    public SmackXMPPRosterPluginListener(NSObject delegate) {
        this.delegate = delegate;
    }
    
    public void entriesAdded(Collection addresses) {
        delegate.takeValueForKey(addresses, "XMPPRosterEntriesAdded");
    }
    public void entriesUpdated(Collection addresses) {
        delegate.takeValueForKey(addresses, "XMPPRosterEntriesUpdated");
    }
    public void entriesDeleted(Collection addresses) {
        delegate.takeValueForKey(addresses, "XMPPRosterEntriesDeleted");
    }
    public void presenceChanged(String XMPPAddress) {
        delegate.takeValueForKey(XMPPAddress, "XMPPRosterPresenceChanged");
    }
}
