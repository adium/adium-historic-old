//
//  SmackXMPPFileTransferListener.java
//  Adium
//
//  Created by Andreas Monitzer on 2006-07-21.
//  Copyright 2006 Andreas Monitzer. All rights reserved.
//

package net.adium.smackBridge;

import org.jivesoftware.smack.*;
import org.jivesoftware.smackx.filetransfer.*;
import com.apple.cocoa.foundation.NSObject;

public class SmackXMPPFileTransferListener implements FileTransferListener {
    NSObject delegate;
    FileTransferManager manager;
    
    public SmackXMPPFileTransferListener(XMPPConnection connection, NSObject delegate) {
        this.delegate = delegate;

        manager = new FileTransferManager(connection);
        manager.addFileTransferListener(this);
    }
    
    public OutgoingFileTransfer createOutgoingFileTransfer(String userID)
    {
        return manager.createOutgoingFileTransfer(userID);
    }
    
    public void fileTransferRequest(FileTransferRequest request)
    {
        delegate.takeValueForKey(request, "fileTransferRequest");
    }
}
