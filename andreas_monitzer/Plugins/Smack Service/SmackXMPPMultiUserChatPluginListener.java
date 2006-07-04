//
//  SmackXMPPMultiUserChatPluginListener.java
//  Adium
//
//  Created by Andreas Monitzer on 2006-07-03.
//  Copyright 2006 Andreas Monitzer. All rights reserved.
//

package net.adium.smackBridge;

import org.jivesoftware.smack.*;
import org.jivesoftware.smack.packet.Packet;
import org.jivesoftware.smack.packet.Message;
import org.jivesoftware.smackx.muc.*;
import com.apple.cocoa.foundation.*;

public class SmackXMPPMultiUserChatPluginListener implements InvitationListener {
    NSObject delegate;
    XMPPConnection connection;
    
    public SmackXMPPMultiUserChatPluginListener(XMPPConnection conn) {
        connection = conn;
        MultiUserChat.addInvitationListener(connection, this);
    }
    
    public void listenToChat(MultiUserChat chat, final NSObject d) {
        chat.addInvitationRejectionListener(new InvitationRejectionListener() {
            public void invitationDeclined(String invitee,
                                           String reason) {
                d.takeValueForKey(new NSDictionary(new Object[] {invitee, reason}, new Object[] {"invitee", "reason"}), "MUCInvitationDeclined");
            }
        });
        chat.addMessageListener(new PacketListener() {
            public void processPacket(Packet packet) {
                d.takeValueForKey(packet, "MUCMessage");
            }
        });
        chat.addParticipantListener(new PacketListener() {
            public void processPacket(Packet packet) {
                d.takeValueForKey(packet, "MUCParticipant");
            }
        });
        chat.addParticipantStatusListener(new ParticipantStatusListener() {
            public void joined(String participant) {
                d.takeValueForKey(participant,"MUCJoined");
            }
            public void left(String participant) {
                d.takeValueForKey(participant,"MUCLeft");
            }
            public void kicked(String participant, String actor, String reason) {
                d.takeValueForKey(new NSDictionary(new Object[] {participant, actor, reason}, new Object[] {"participant", "actor", "reason"}), "MUCKicked");
            }
            public void voiceGranted(String participant) {
                d.takeValueForKey(participant, "MUCVoiceGranted");
            }
            public void voiceRevoked(String participant) {
                d.takeValueForKey(participant, "MUCVoiceRevoked");
            }
            public void banned(String participant, String actor, String reason) {
                d.takeValueForKey(new NSDictionary(new Object[] {participant, actor, reason}, new Object[] {"participant", "actor", "reason"}), "MUCBanned");
            }
            public void membershipGranted(String participant) {
                d.takeValueForKey(participant, "MUCMembershipGranted");
            }
            public void membershipRevoked(String participant) {
                d.takeValueForKey(participant, "MUCMembershipRevoked");
            }
            public void moderatorGranted(String participant) {
                d.takeValueForKey(participant, "MUCModeratorGranted");
            }
            public void moderatorRevoked(String participant) {
                d.takeValueForKey(participant, "MUCModeratorRevoked");
            }
            public void ownershipGranted(String participant) {
                d.takeValueForKey(participant, "MUCOwnershipGranted");
            }
            public void ownershipRevoked(String participant) {
                d.takeValueForKey(participant, "MUCOwnershipRevoked");
            }
            public void adminGranted(String participant) {
                d.takeValueForKey(participant, "MUCAdminGranted");
            }
            public void adminRevoked(String participant) {
                d.takeValueForKey(participant, "MUCAdminRevoked");
            }
            public void nicknameChanged(String participant, String newNickname) {
                d.takeValueForKey(new NSDictionary(new Object[] {participant, newNickname}, new Object[] {"participant", "newNickname"}), "MUCNicknameChanged");
            }
        });
        chat.addSubjectUpdatedListener(new SubjectUpdatedListener() {
            public void subjectUpdated(String subject,
                                       String from) {
                d.takeValueForKey(new NSDictionary(new Object[] {subject, from}, new Object[] {"subject", "from"}), "MUCSubjectUpdated");
            }
        });
        chat.addUserStatusListener(new UserStatusListener() {
            public void kicked(String actor, String reason) {
                d.takeValueForKey(new NSDictionary(new Object[] {actor, reason}, new Object[] {"actor", "reason"}), "MUCUserKicked");
            }
            public void voiceGranted() {
                d.takeValueForKey(new Boolean(true),"MUCUserVoice");
            }
            public void voiceRevoked() {
                d.takeValueForKey(new Boolean(false),"MUCUserVoice");
            }
            public void banned(String actor, String reason) {
                d.takeValueForKey(new NSDictionary(new Object[] {actor, reason}, new Object[] {"actor", "reason"}), "MUCUserBanned");
            }
            public void membershipGranted() {
                d.takeValueForKey(new Boolean(true),"MUCUserMembership");
            }
            public void membershipRevoked() {
                d.takeValueForKey(new Boolean(false),"MUCUserMembership");
            }
            public void moderatorGranted() {
                d.takeValueForKey(new Boolean(true),"MUCUserModerator");
            }
            public void moderatorRevoked() {
                d.takeValueForKey(new Boolean(false),"MUCUserModerator");
            }
            public void ownershipGranted() {
                d.takeValueForKey(new Boolean(true),"MUCUserOwnership");
            }
            public void ownershipRevoked() {
                d.takeValueForKey(new Boolean(false),"MUCUserOwnership");
            }
            public void adminGranted() {
                d.takeValueForKey(new Boolean(true),"MUCUserAdmin");
            }
            public void adminRevoked() {
                d.takeValueForKey(new Boolean(false),"MUCUserAdmin");
            }
        });
    }
    
    public void setDelegate(NSObject d) {
        delegate = d;
    }
    public NSObject delegate() {
        return delegate;
    }
    
    public void destroy() {
        MultiUserChat.removeInvitationListener(connection, this);
    }
    
    public void invitationReceived(XMPPConnection conn,
                                   String room,
                                   String inviter,
                                   String reason,
                                   String password,
                                   Message message) {
        if(delegate != null) {
            NSDictionary dict = new NSDictionary(new Object[] {conn,         room,   inviter,   reason,   password,   message },
                                                 new Object[] {"connection", "room", "inviter", "reason", "password", "message"});
            
            delegate.takeValueForKey(dict, "MUCInvitation");
        }
    }
}
