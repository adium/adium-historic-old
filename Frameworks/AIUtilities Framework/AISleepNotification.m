//
//  AISleepNotification.m
//  Adium
//
//  Created by Adam Iser on Sun Jun 29 2003.
//

/*
 AISleepNotification posts two notifications, 
	AISystemWillSleep_Notification and AISystemDidWake_Notification.
 Registering for these allow a program to take action before the computer sleeps and after the computer
 wakes from sleep.
 
 AISleepNotification also observes two notifications, 
	AISystemHoldSleep_Notification and AISystemContinueSleep_Notification.
 Through the use of these, a program
 can preemptively delay sleeping which may occur during, for example, the execution of a lengthy block of
 code which shouldn't be inerrupted and then remove the delay when execution of the code is complete.
 */

#import <mach/mach_port.h>
#import <mach/mach_interface.h>
#import <mach/mach_init.h>
#import <IOKit/pwr_mgt/IOPMLib.h>
#import <IOKit/IOMessage.h>
#import "AISleepNotification.h"


void callback(void * x,io_service_t y,natural_t messageType,void * messageArgument);

io_connect_t		root_port;
int			holdSleep = 0;
long unsigned int	waitingSleepArgument;

@implementation AISleepNotification

+ (void)load
{
    IONotificationPortRef	notify;
    io_object_t 		anIterator;

    //Observe system power events
    root_port = IORegisterForSystemPower(0, &notify, callback, &anIterator);
    if(root_port){
        CFRunLoopAddSource(CFRunLoopGetCurrent(),
                           IONotificationPortGetRunLoopSource(notify),
                           kCFRunLoopDefaultMode);
    }

    //Observe Hold/continue sleep notification
    [[NSNotificationCenter defaultCenter] addObserver:self 
											 selector:@selector(holdSleep:) 
												 name:AISystemHoldSleep_Notification
											   object:nil];
	
    [[NSNotificationCenter defaultCenter] addObserver:self 
											 selector:@selector(continueSleep:)
												 name:AISystemContinueSleep_Notification
											   object:nil];
}

//
+ (void)holdSleep:(NSNotification *)notification
{
    holdSleep++;
}
+ (void)continueSleep:(NSNotification *)notification
{
    holdSleep--;

    if(holdSleep == 0){
        //Permit sleep now
        IOAllowPowerChange(root_port, (long)waitingSleepArgument);
    }
}


//
void callback(void * x, io_service_t y, natural_t messageType, void * messageArgument)
{
    switch ( messageType ) {
        case kIOMessageSystemWillSleep:
            //Let everyone know we will sleep
            holdSleep = 0;
            [[NSNotificationCenter defaultCenter] postNotificationName:AISystemWillSleep_Notification object:nil];

            //If noone requested a delay, sleep now
            if(holdSleep == 0){
                IOAllowPowerChange(root_port,(long)messageArgument);
            }else{
                waitingSleepArgument = (long unsigned int)messageArgument;
            }
                
        break;
            
        case kIOMessageCanSystemSleep:
            IOAllowPowerChange(root_port,(long)messageArgument);
        break;
            
        case kIOMessageSystemHasPoweredOn:
            //Let everyone know we awoke
            [[NSNotificationCenter defaultCenter] postNotificationName:AISystemDidWake_Notification object:nil];
        break;
    }
}

@end
