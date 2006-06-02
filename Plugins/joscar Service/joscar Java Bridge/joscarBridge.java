//
//  joscarBridge.java
//  Adium
//
//  Created by Evan Schoenberg on 6/22/05.
//

package net.adium.joscarBridge;

import com.apple.cocoa.foundation.*;

import net.kano.joustsim.*;
import net.kano.joustsim.oscar.*;
import net.kano.joustsim.oscar.oscar.service.Service;
import net.kano.joustsim.oscar.oscar.service.ssi.*;
import net.kano.joustsim.oscar.oscar.service.info.*;
import net.kano.joustsim.oscar.oscar.service.icbm.*;
import net.kano.joustsim.oscar.oscar.service.icbm.ft.*;
import net.kano.joustsim.oscar.oscar.service.icbm.ft.controllers.TransferredFileImpl;
import net.kano.joustsim.oscar.oscar.service.icbm.dim.*;
import net.kano.joustsim.oscar.oscar.service.icbm.ft.events.*;
import net.kano.joustsim.oscar.oscar.service.icon.*;
import net.kano.joustsim.oscar.oscar.service.chatrooms.*;

import net.kano.joscar.*;
import net.kano.joscar.snaccmd.*;

import net.kano.joustsim.oscar.oscar.service.login.LoginService;
import net.kano.joustsim.oscar.oscar.service.login.SecuridProvider;

import net.kano.joustsim.trust.BuddyCertificateInfo;

import net.adium.joscarBridge.BridgeToAdiumHandler;

import java.beans.PropertyChangeEvent;
import java.lang.reflect.Array;
import java.util.List;
import java.util.HashMap;
import java.util.Collection;
import java.util.logging.Formatter;
import java.util.logging.LogRecord;
import java.util.Date;
import java.util.Set;
import java.text.DateFormat;
import java.io.StringWriter;
import java.io.PrintWriter;
import java.util.logging.Level;
import java.util.logging.Logger;
import java.util.logging.Handler;
import java.util.logging.ConsoleHandler;
import java.nio.ByteBuffer;
import java.nio.channels.ReadableByteChannel;


public class joscarBridge implements GlobalBuddyInfoListener, BuddyInfoTrackerListener,
InfoServiceListener, StateListener,
OpenedServiceListener, BuddyListLayoutListener,
BuddyListener, GroupListener,
IcbmListener, RvConnectionManagerListener,
ImConversationListener, TypingListener,
RvConnectionEventListener, IconRequestListener, ChatRoomManagerListener, ChatRoomSessionListener,
SecuridProvider
{
	private NSObject delegate;
	
	static private final NSNotificationCenter defaultCenter = NSNotificationCenter.defaultCenter();
	private BridgeToAdiumHandler h;
	
	static private final Logger LOGGER = Logger.getLogger("net.adium.joscarBridge");
	
	public joscarBridge(int	enableLogging) {
		Logger l;
		Handler[] handlers;
		Level generalLevel, joscarLevel;

		h = new BridgeToAdiumHandler();
		h.setFormatter(new CoolFormatter());

		if (enableLogging == 0) {
			generalLevel = Level.SEVERE;
			joscarLevel = Level.SEVERE;

		} else if (enableLogging == 1) {
			generalLevel = Level.ALL;
			joscarLevel = Level.FINE;

		} else if (enableLogging == 2) {
			generalLevel = Level.WARNING;
			joscarLevel = Level.WARNING;

		} else {
			generalLevel = Level.OFF;
			joscarLevel = Level.OFF;	
		}
		
		h.setLevel(generalLevel);
		
		l = Logger.getLogger("net.kano.joustsim");
		l.setLevel(generalLevel);
		l.setUseParentHandlers(false);
		l.addHandler(h);
		
		l = Logger.getLogger("net.kano.joscar");
		l.setLevel(joscarLevel);
		l.setUseParentHandlers(false);
		l.addHandler(h);
		
		LOGGER.setLevel(generalLevel);
		LOGGER.setUseParentHandlers(false);
		LOGGER.addHandler(h);		
    }
	
	public BridgeToAdiumHandler getAdiumHandler() {
		return h;
	}
	
    private static class CoolFormatter extends Formatter {
        private final DateFormat formatter
                = DateFormat.getTimeInstance(DateFormat.FULL);

        public String format(LogRecord record) {
            String clname = record.getSourceClassName();
            String shname = clname.substring(clname.lastIndexOf('.') + 1);
            Throwable thrown = record.getThrown();
            StringWriter sw = null;

			//Get the stack trace if there is one
            if (thrown != null) {
                sw = new StringWriter();
                thrown.printStackTrace(new PrintWriter(sw));
            }

            return "[" + formatter.format(new Date(record.getMillis())) + "] "
                    + shname + ": "
                    + record.getMessage() +
					(sw == null ? "" : sw.getBuffer().toString()) + "\n";
        }
    }
	
	public NSData dataFromByteBlock(ByteBlock byteBlock) {
		NSData	data = null;
		
		if (byteBlock != null) {
			byte[]	byteArray = byteBlock.toByteArray();

			data = new NSData(byteArray);
		}
		
		return (data);
	}
	
	public ByteBlock byteBlockFromData(NSData data) {
		ByteBlock	byteBlock = null;

		if (data != null) {
			byteBlock = ByteBlock.wrap(ByteBlock.wrap(data.bytes(0, data.length())).toByteArray());
		}

		return (byteBlock);
	}

	public NSData dataFromAttachment(Attachment attachment) throws java.io.IOException {
		NSData	data = null;
		
		if (attachment != null) {
			ReadableByteChannel byteChannel = attachment.openForReading();
			ByteBuffer byteBuffer = ByteBuffer.allocate((int)attachment.getLength());
			byteChannel.read(byteBuffer);
			byte[]	byteArray = byteBuffer.array();

			data = new NSData(byteArray);
		}
		
		return (data);		
	}
	
	public void setDelegate(NSObject inDelegate) {
		this.delegate = inDelegate;		
	}

	private void sendDelegateMessageWithMap(String notificationName, HashMap map) {
		/*
		 * Delegate should implement:
		 * Java: setNotificationName(NSDictionary infoDict)
		 * ObjC: - (void)setNotificationName:(NSDictionary *)infoDict
		 */
		delegate.takeValueForKey(map, notificationName);
	}

	/* Called by Cocoa before initiating an outgoing file transfer so we can set up our TransferredFileFactory.
	 * The TransferredFileFactory is responsible for querying the Cocoa delegate for Mac information about files
	 * immediately before transfers occur.
	 */
	public void prepareOutgoingFileTransfer(OutgoingFileTransfer fileTransfer) {
		fileTransfer.setTransferredFileFactory(new DefaultTransferredFileFactory() {
			protected void initializeFile(TransferredFileImpl tfile) {
				//Get info on the file from the delegate
				ByteBlock	macFileInfo;
				HashMap		map = new HashMap();

				//Put the file path in the map for use by the delegate...
				try {
				map.put("FilePath", tfile.getRealFile().getCanonicalPath());
				sendDelegateMessageWithMap("GetMacFileInfo", map);
				
				//Two-way use of the map! Clever.
				macFileInfo = (ByteBlock)map.get("FInfoByteBlock");

				tfile.setMacFileInfo(macFileInfo);
				}
				catch (java.io.IOException e) {
					System.err.println("IOException: " 
									   + e.getMessage());
				}
			}
		});		
	}

	public void newBuddyInfo(BuddyInfoManager manager, Screenname buddy,
							 BuddyInfo info) {

    }
	
    public void buddyInfoChanged(BuddyInfoManager manager, Screenname buddy,
								 BuddyInfo info, PropertyChangeEvent event) {
		String	changedProperty = event.getPropertyName();
		
		HashMap map = new HashMap();
		map.put("Screenname", buddy);
		map.put("BuddyInfo", info);
		
		if (changedProperty.equals("online")) {
			sendDelegateMessageWithMap("ContactOnline", map);
			
		} else if (changedProperty.equals("iconData")) {			
			sendDelegateMessageWithMap("IconUpdate", map);
			
		} else if (changedProperty.equals("statusMessage")) {
			//don't use just "StatusMessage" because setStatusMessage: was already taken in ESjoscarCocoaAdapter
			sendDelegateMessageWithMap("IncomingStatusMessage", map);

		} else if (changedProperty.equals("awayMessage")) {
			Object val = event.getNewValue();
			if (val != null) {
				map.put("Away message", val);
			}
			sendDelegateMessageWithMap("AwayMessage", map);
			
		} else if (changedProperty.equals("userProfile")) {
			Object userInfo = event.getNewValue();
			if (userInfo != null) {
				map.put("Profile", userInfo);
			}
			
			sendDelegateMessageWithMap("Profile", map);
		}
		/*else if (changedProperty.equals("mobile")) {
			sendDelegateMessageWithMap("Mobile", map);
			
		} else if (changedProperty.equals("aolUser")) {
			sendDelegateMessageWithMap("AolUser", map);
		}*/
    }

    public void receivedStatusUpdate(BuddyInfoManager manager,
									 Screenname buddy, BuddyInfo info) {
		HashMap map = new HashMap();
		map.put("Screenname", buddy);
		map.put("BuddyInfo", info);
		
		sendDelegateMessageWithMap("StatusUpdate", map);
	}
	
	/* InfoServiceListener */
	public void handleUserProfile(InfoService service, Screenname buddy,
								  String userInfo) {
	}
    public void handleAwayMessage(InfoService service, Screenname buddy,
								  String awayMessage) {
	}
    public void handleCertificateInfo(InfoService service, Screenname buddy,
									  BuddyCertificateInfo certInfo) {
		
	}
    public void handleInvalidCertificates(InfoService service, Screenname buddy,
										  CertificateInfo origCertInfo, Throwable ex) {
		
	}
    public void handleDirectoryInfo(InfoService service, Screenname buddy,
									DirInfo dirInfo) {
		
	}
	
	/* StateListener */
	public void handleStateChange(StateEvent event) {
		State			newState = event.getNewState();
		StateInfo		newStateInfo = event.getNewStateInfo();
		NSDictionary	notificationDict;

		JoscarStateInfo	joscarStateInfo = new JoscarStateInfo(newStateInfo);

		String errorMessage = joscarStateInfo.errorMessage();
		String errorCode = joscarStateInfo.errorCode();

		HashMap map = new HashMap();
		map.put("NewState", newState.toString());
		
		if (errorMessage != null) {
			map.put("ErrorMessage", errorMessage);
		}
		
		if (errorCode != null) {
			map.put("ErrorCode", errorCode);
		}
		
		sendDelegateMessageWithMap("StateChange", map);
	}
	
	/* OpenedServiceListener. We want to listen on the SsiService; no need to pass back to Adium. */
	public void openedServices(AimConnection conn, Collection<? extends Service> services) {
		for (Service service : services) {
			if (service instanceof SsiService) {
				SsiService ssiService = (SsiService) service;
				MutableBuddyList buddyList = ssiService.getBuddyList(); 
				
				buddyList.addRetroactiveLayoutListener(this);
				
			} else if (service instanceof IcbmService) {
				IcbmService icbmService = (IcbmService) service;
				//listen for new convesations
				icbmService.addIcbmListener(this);
				
				//listen for incoming file transfers
				RvConnectionManager ftManager = icbmService.getRvConnectionManager();
				ftManager.addConnectionManagerListener(this);

			} else if (service instanceof IconService) {
				IconService iconService = (IconService) service;
				//Listen for buddy icon changes
				iconService.addIconRequestListener(this);

			} else if (service instanceof LoginService) {
				sendDelegateMessageWithMap("LoginServiceOpened", null);
			}
		}
	}
	public void closedServices(AimConnection conn, Collection<? extends Service> services) {
    }
	
	/* BuddyListLayoutListener */
	public void groupsReordered(BuddyList list, List<? extends Group> oldOrder,
								List<? extends Group> newOrder) {
		
	}
	
	public void groupAdded(BuddyList list, List<? extends Group> oldItems,
						   List<? extends Group> newItems,
						   Group group, List<? extends Buddy> buddies) {
		HashMap map = new HashMap();
		map.put("Group", group);

		sendDelegateMessageWithMap("GroupAdded", map);
		
		//We want to be a group listener
		group.addGroupListener(this);
	}
	
	public void groupRemoved(BuddyList list, List<? extends Group> oldItems,
							 List<? extends Group> newItems,
							 Group group) {
		
		//No need to continue monitoring the group
		group.removeGroupListener(this);
		
	}

	public void buddyAdded(BuddyList list, Group group, List<? extends Buddy> oldItems,
						   List<? extends Buddy> newItems,
						   Buddy buddy) {
		HashMap map = new HashMap();
		map.put("Group", group);
		map.put("Buddy", buddy);
		
		sendDelegateMessageWithMap("BuddyAdded", map);
		
		//We want to be a buddy listener
		buddy.addBuddyListener(this);
	}

	public void buddyRemoved(BuddyList list, Group group, List<? extends Buddy> oldItems,
							 List<? extends Buddy> newItems,
							 Buddy buddy) {
		HashMap map = new HashMap();
		map.put("Group", group);
		map.put("Buddy", buddy);
		
		sendDelegateMessageWithMap("BuddyRemoved", map);

		//No need to continue monitoring this buddy
		buddy.removeBuddyListener(this);
	}

	public void buddiesReordered(BuddyList list, Group group,
								 List<? extends Buddy> oldBuddies, List<? extends Buddy> newBuddies) {
	}
	
	/* Group Listener */
	public void groupNameChanged(Group group, String oldName, String newName) {
		
	}
	
	/* Buddy Listener */
	public void screennameChanged(Buddy buddy, Screenname oldScreenname, Screenname newScreenname) {
		
	}

	public void awaitingAuthChanged(Buddy buddy, boolean old, boolean awaiting) {
	}
	
	public void aliasChanged(Buddy buddy, String oldAlias, String newAlias) {
		HashMap map = new HashMap();
		map.put("Buddy", buddy);
		map.put("Alias", newAlias);

		sendDelegateMessageWithMap("AliasChanged", map);				
	}
	
    public void buddyCommentChanged(Buddy buddy, String oldComment, String newComment) {
		HashMap map = new HashMap();
		map.put("Buddy", buddy);
		map.put("Old Comment", oldComment);
		map.put("New Comment", oldComment);
		
		sendDelegateMessageWithMap("BuddyCommentChanged", map);
	}
	
	public void alertActionChanged(Buddy buddy, int oldAlertAction, int newAlertAction) {
		
	}
	
    public void alertTimeChanged(Buddy buddy, int oldAlertEvent, int newAlertEvent) {
		
	}
	
    public void alertSoundChanged(Buddy buddy, String oldAlertSound,
								  String newAlertSound) {
		
	}
	
	/* IcbmListener */
	public void newConversation(IcbmService service, Conversation conv) {
		if (conv instanceof DirectimConversation) {
			DirectimConversation directConv = (DirectimConversation) conv;

			directConv.open();
		}
		
		conv.addConversationListener(this);
	}
	
    public void buddyInfoUpdated(IcbmService service, Screenname buddy,
								 IcbmBuddyInfo info) {
		
	}
	
	public void sendAutomaticallyFailed(IcbmService service, Message message,
										Set<Conversation> triedConversations) {
		HashMap map = new HashMap();
		map.put("Message", message);
		map.put("Set<Conversation>", triedConversations);
		
		sendDelegateMessageWithMap("SendAutomaticallyFailed", map);		
	}
	
	/* ImConversationListener (extends ConversationListener, TypingListener) */

	/** This may never be called */
    public void conversationOpened(Conversation conversation) {
		conversation.addConversationListener(this);
		
		if (conversation instanceof DirectimConversation) {
			HashMap map = new HashMap();
			map.put("DirectimConversation", conversation);
			
			sendDelegateMessageWithMap("OpenedDirectIMConversation", map);			
		}
	}
    /** This may be called without ever calling conversationOpened */
	public void conversationClosed(Conversation conversation) {
		if (conversation instanceof DirectimConversation) {
			HashMap map = new HashMap();
			map.put("DirectimConversation", conversation);
			
			sendDelegateMessageWithMap("ClosedDirectIMConversation", map);			
		}		
	}
	
    /** This may be called after conversationClosed is called */
    public void gotMessage(Conversation conversation, MessageInfo minfo) {
		HashMap map = new HashMap();
		map.put("Conversation", conversation);
		map.put("MessageInfo", minfo);
		
		sendDelegateMessageWithMap("GotMessage", map);
		conversation.addConversationListener(this);
	}
    
	/** This may be called after conversationClosed is called */
    public void sentMessage(Conversation conversation, MessageInfo minfo) {
		
	}
	
    public void canSendMessageChanged(Conversation conversation, boolean canSend) {
		
	}
	
    public void gotOtherEvent(Conversation conversation, ConversationEventInfo event) {
		HashMap map = new HashMap();
		map.put("Conversation", conversation);
		map.put("ConversationEventInfo", event);
		
		sendDelegateMessageWithMap("GotOtherEvent", map);		
	}
	
    public void sentOtherEvent(Conversation conversation, ConversationEventInfo event) {
		HashMap map = new HashMap();
		map.put("Conversation", conversation);
		map.put("ConversationEventInfo", event);
		
		sendDelegateMessageWithMap("SentOtherEvent", map);
	}

	public void missedMessages(ImConversation conv, MissedImInfo info) {
		HashMap map = new HashMap();
		map.put("ImConversation", conv);
		map.put("MissedImInfo", info);

		sendDelegateMessageWithMap("MissedMessages", map);
	}

	public void gotTypingState(Conversation conversation, TypingInfo typingInfo) {
		HashMap map = new HashMap();
		map.put("Conversation", conversation);
		map.put("TypingInfo", typingInfo);
		
		sendDelegateMessageWithMap("GotTypingState", map);
	}
	
	/* Enum Conversion for TypingState { TYPING, NO_TEXT, PAUSED } */
	TypingState typingStateFromString(String modeName)
	{
		TypingState mode = null;
		if (modeName.equals(TypingState.TYPING.name()))
			mode = TypingState.TYPING;
		if (modeName.equals(TypingState.NO_TEXT.name()))
			mode = TypingState.NO_TEXT;
		if (modeName.equals(TypingState.PAUSED.name()))
			mode = TypingState.PAUSED;
		return mode;
	}	
	
	/* RvConnectionManagerListener */
    public void handleNewIncomingConnection(RvConnectionManager manager, IncomingRvConnection incomingFT) {
	    if (incomingFT instanceof IncomingFileTransfer) {
			incomingFT.addEventListener(this);

			HashMap map = new HashMap();
			map.put("IncomingFileTransfer", incomingFT);
			
			sendDelegateMessageWithMap("NewIncomingFileTransfer", map);
		}
	}
	
	/* FileTransferListener */
	public void handleEventWithStateChange(RvConnection ft, RvConnectionState ftState, RvConnectionEvent ftEvent) {
		HashMap map = new HashMap();
		map.put("RvConnection", ft);
		map.put("RvConnectionState", ftState);
		map.put("RvConnectionEvent", ftEvent);
		
		sendDelegateMessageWithMap("FileTransferUpdate", map);
	}
		
	public void handleEvent(RvConnection ft, RvConnectionEvent ftEvent) {
		HashMap map = new HashMap();
		map.put("RvConnection", ft);
		map.put("RvConnectionEvent", ftEvent);
		
		sendDelegateMessageWithMap("FileTransferUpdate", map);
	}

	/* IconRequestListener */
	public void buddyIconCleared(IconService service, Screenname screenname,
						  ExtraInfoData data) {
		HashMap map = new HashMap();
		map.put("Screenname", screenname);

		sendDelegateMessageWithMap("IconUpdate", map);		
	}
	
    public void buddyIconUpdated(IconService service, Screenname screenname,
						  ExtraInfoData hash, ByteBlock iconData) {
		HashMap map = new HashMap();
		map.put("Screenname", screenname);
		map.put("IconData", iconData);

		sendDelegateMessageWithMap("IconUpdate", map);		
	}
	
	/*Enum Conversion for PrivacyMode*/
	PrivacyMode privacyModeFromString(String modeName)
	{
		PrivacyMode mode = null;
		if (modeName.equals(PrivacyMode.ALLOW_ALLOWED.name()))
			mode = PrivacyMode.ALLOW_ALLOWED;
		if (modeName.equals(PrivacyMode.BLOCK_ALL.name()))
			mode = PrivacyMode.BLOCK_ALL;
		if (modeName.equals(PrivacyMode.BLOCK_BLOCKED.name()))
			mode = PrivacyMode.BLOCK_BLOCKED;
		if (modeName.equals(PrivacyMode.ALLOW_BUDDIES.name()))
			mode = PrivacyMode.ALLOW_BUDDIES;
		if (modeName.equals(PrivacyMode.ALLOW_ALL.name()))
			mode = PrivacyMode.ALLOW_ALL;
		return mode;
	}
	
	public void handleInvitation(ChatRoomManager manager, ChatInvitation invite)
	{
		HashMap map = new HashMap();
		map.put("ChatInvitation",invite);
		map.put("ChatRoomManager", manager);
		sendDelegateMessageWithMap("ChatInvitation",map);
	}
	
	/* ChatRoomSessionListener methods */
	public void handleStateChange(ChatRoomSession session, ChatSessionState oldState, ChatSessionState state)
	{
		String stateString = new String("UNKNOWN");
		HashMap map = new HashMap();
		map.put("ChatRoomSession", session);
		
		//translate the state to a string we can parse in Adium since enums don't like the objc bridge
		if (oldState == ChatSessionState.INITIALIZING)
			stateString = new String("INITIALIZING");
		else if (oldState == ChatSessionState.CONNECTING)
			stateString = new String("CONNECTING");
		else if (oldState == ChatSessionState.FAILED)
			stateString = new String("FAILED");
		else if (oldState == ChatSessionState.INROOM)
			stateString = new String("INROOM");
		else if (oldState == ChatSessionState.CLOSED)
			stateString = new String("CLOSED");
		map.put("oldState",stateString);
		
		//translate the state to a string we can parse in Adium since enums don't like the objc bridge
		if (state == ChatSessionState.INITIALIZING)
			stateString = new String("INITIALIZING");
		else if (state == ChatSessionState.CONNECTING)
			stateString = new String("CONNECTING");
		else if (state == ChatSessionState.FAILED)
			stateString = new String("FAILED");
		else if (state == ChatSessionState.INROOM)
			stateString = new String("INROOM");
		else if (state == ChatSessionState.CLOSED)
			stateString = new String("CLOSED");
		map.put("state",stateString);
		sendDelegateMessageWithMap("GroupChatStateChange",map);
	}
	
    public void handleUsersJoined(ChatRoomSession session, Set<ChatRoomUser> joined)
	{
		HashMap map = new HashMap();
		map.put("ChatRoomSession", session);
		map.put("Set",joined);
		sendDelegateMessageWithMap("GroupChatUsersJoined",map);
	}
	
    public void handleUsersLeft(ChatRoomSession session, Set<ChatRoomUser> left)
	{
		HashMap map = new HashMap();
		map.put("ChatRoomSession", session);
		map.put("Set",left);
		sendDelegateMessageWithMap("GroupChatUsersLeft",map);
	}
	
    public void handleIncomingMessage(ChatRoomSession room, ChatRoomUser user, ChatMessage message)
	{
		HashMap map = new HashMap();
		map.put("ChatRoomSession", room);
		map.put("ChatRoomUser", user);
		map.put("ChatMessage", message);
		sendDelegateMessageWithMap("GroupChatIncomingMessage",map);
	}
	
	/* SecurID */
	public String getSecurid()
	{
		return (String)delegate.valueForKey("securid");
	}
}
