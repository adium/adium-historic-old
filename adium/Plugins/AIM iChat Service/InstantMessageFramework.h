/*
 *  InstantMessageFramework.h
 *  Adium
 */

enum {
    kMessageNoFlags		= 0L,
//    kUnknown		= (1L << 0),
//    kUnknown		= (1L << 1),
    kMessageOutgoingFlag	= (1L << 2),
    kMessageTypingFlag		= (1L << 3),
};    

@protocol FZDaemon <NSObject>
- (void)addOpenNoteProperties:fp12 fromListener:fp16;	//?
- (void)removeOpenNoteID:fp12;				//?
- (NSArray *)allServices;				//Returns an array of FZServices
- (void)addListener:(id)fp12 capabilities:(int)fp16;	//Add a listener (caps == 15)
- (void)removeListener:(id)fp12;			//Remove a listener
- (oneway void)changeMyStatus:fp12;			//?
- (NSDictionary *)myStatus;				//Returns a status dict for the user
- (void)terminate;					//?Terminate the daemon
@end

@interface FZMessage : NSObject <NSCoding, NSCopying>
//Init
- initWithSender:fp12 format:(int)fp16 body:fp20;
- initWithSender:(NSString *)fp12 time:(NSDate *)fp16 format:(int)fp20 body:(NSString *)fp24 attributes:fp28 incomingFile:fp32 outgoingFile:file inlineFiles:files flags:(int)fp40; //init for outgoing messages.  iChat uses ("Our Name", date, 2, "Message Text", nil, nil, nil, nil, 5) for finished messages, but ("Our Name", date, 2, "Message Text", nil, nil, nil, nil, 12) for messages as they're typed

//Accessors
- (NSString *)sender;
- (NSDate *)time;
- (int)bodyFormat;
- (NSString *)body;
- (void *)attributes; 	//?
- (void *)incomingFile;	//?
- (void *)outgoingFile;	//?
- (void *)inlineFiles;	//?
- (int)flags;
- (char)isFinished;
- (char)isEmpty;
- (void)setSender:(NSString *)fp12;
- (void)setTime:(NSDate *)fp12;
- (void)setAttributes:fp12;
- (void)setIncomingFile:fp12;
- (void)setOutgoingFile:fp12;
- (void)setInlineFiles:fp12;
- (void)setFlags:(int)fp12;
- (void)setBody:(NSString *)fp12 format:(int)fp16;
- (void)adjustIsEmptyFlag;

//Other
- copyWithZone:(struct _NSZone *)fp12;
- replacementObjectForPortCoder:fp12;
- initWithCoder:fp12;
- (void)encodeWithCoder:fp12;
- init;
- (void)dealloc;

@end

@protocol FZService <NSObject>
- (void)setBlockIdleStatus:(char)fp12;					//?
- (char)blockIdleStatus;						//?
- (int)blockingMode;							//?
- (void)setBlockingMode:(int)fp12;					//?
- allowList;								//?
- (void)setAllowList:fp12;						//?
- blockList;								//?
- (void)setBlockList:fp12;						//?
- (void)blockMessages:(char)fp12 fromID:fp16;				//?
- (char)sendFile:fp12 toPerson:fp16;					//?
- (char)infoForChat:fp12 status:(out int *)fp16 isChatRoom:(out char *)fp20 members:(out id *)fp24;//?
- (char)setPerson:fp12 isIgnored:(char)fp16 inChat:fp20;		//?
- (char)leaveChat:fp12;							//?
- (int)sendMessage:(FZMessage *)fp12 toChat:(void *)fp16;		//Send a message
- (char)respond:(char)fp12 toInvitationToChat:fp16;			//?
- (char)invitePerson:fp12 toChat:fp16 withMessage:fp20;			//?
- goToChatNamed:fp12;							//?
- createChatWith:fp12 invitation:fp16 named:fp20;			//Create
- (void *)createChatForIMsWith:(NSString *)fp12 isDirect:(char)fp16;	//Create a chat for IM's with a screenname
- (char)removeBuddies:fp12 fromGroups:fp16;				//?
- (char)addBuddies:fp12 toGroups:fp16;					//?
- (NSImage *)pictureOfBuddy:(NSString *)fp12;				//Returns the buddy icon of a buddy
- (NSArray *)buddyPictures;						//Returns everyones buddy icons
- (char)setValue:fp12 ofProperty:fp16 ofPerson:fp20;			//?
- (char)requestProperty:fp12 ofPerson:fp16;				//?
- (NSDictionary *)buddyProperties;					//Returns the properties of a buddy (FZPersonStatus (kCFNumberSInt32Type), FZPersonFirstName (CFString), FZPersonStatusMessage (CFString), FZPersonEmail (CFString), FZPersonLastName (CFString), FZPersonPictureData (CFImage))
- (NSString *)serviceLoginStatusMessage;				//Returns the login status "connecting to..."
- (int)serviceDisconnectReason;						//Returns the reason for disconnect
- (int)serviceLoginStatus;						//Returns the login status (0 = offline, 1 = ERROR, 2 = disconnecting??, 3 = connecting, 4 = online)
- (oneway void)logout;							//Disconnect
- (oneway void)login;							//Connect
- loginID;								//Returns the screenname of the service
- (char)serviceIsAvailable;						//Always seems to return YES
- defaultBuddyIconURLs;							//?
- (int)acceptableMessageFormats;					//?
- (char)hasCapability:(int)fp12;					//?
- (int)capabilities;							//?
- (int)IDSensitivity;							//?
- emailDomains;								//?
- addressBookProperty;							//?
- serviceIconURL;							//?
- internalName;								//?
- shortName;								//?
- name;									//?
- loginDefaults;							//?
- (void)writeServiceDefaults:fp12;					//?
- serviceDefaults;							//?
- (void)removeListener:(id)fp12;					//Remove a listener
- (void)addListener:(id)fp12 signature:(NSString *)fp16 capabilities:(int)fp20;	//Add a listener.  iChat passes a bundle ID and 15
@end

@protocol FZServiceListener <NSObject>
- (oneway void)service:(id)service requestOutgoingFileXfer:(id)file;
- (oneway void)service:(id)service requestIncomingFileXfer:(id)file;
- (oneway void)service:(id)service chat:(id)chat member:(id)member statusChanged:(int)status;
- (oneway void)service:(id)service chat:(id)chat showError:(id)error;
- (oneway void)service:(id)service chat:(id)chat messageReceived:(id)message;
- (oneway void)service:(id)service chat:(id)chat statusChanged:(int)status;
- (oneway void)service:(id)service directIMRequestFrom:(id)from invitation:(id)invitation;
- (oneway void)service:(id)service invitedToChat:(id)chat isChatRoom:(char)isRoom invitation:(id)invitation;
- (oneway void)service:(id)service youAreDesignatedNotifier:(char)notifier;
- (oneway void)service:(id)service buddyPictureChanged:(id)buddy imageData:(id)image;
- (oneway void)service:(id)inService buddyPropertiesChanged:(NSArray *)inProperties;
- (oneway void)service:(id)inService loginStatusChanged:(int)inStatus message:(id)inMessage reason:(int)inReason;
@end

@protocol FZDaemonListener <NSObject>
- (oneway void)openNotesChanged:(id)unknown;
- (oneway void)myStatusChanged:(id)unknown;
@end
