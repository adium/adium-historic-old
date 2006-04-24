//
//  BridgeToAdiumHandler.java
//  joscar Java Bridge
//
//  Created by Augie Fackler on 12/26/05.
//

package net.adium.joscarBridge;

import com.apple.cocoa.foundation.*;

import java.util.logging.Handler;
import java.util.logging.LogRecord;
import java.util.logging.Formatter;

public class BridgeToAdiumHandler extends Handler {
	protected NSObject outputDestination;
	public BridgeToAdiumHandler()
	{
		super();
		outputDestination = null;
	}
	
	public void setOutputDestination(NSObject newDestination)
	{
		outputDestination = newDestination;
	}
	
	public void flush()
	{
		//this is a no-op for us
	}
	
	public void close()
	{
		outputDestination = null;
	}
	
	public void publish(LogRecord record)
	{
		if (isLoggable(record)) {
			Formatter formatter = getFormatter();
			String outputString;

			if (formatter != null) {
				outputString = formatter.formatMessage(record);
			} else {
				outputString = record.toString();
			}
			if (outputDestination != null)
				outputDestination.takeValueForKey(outputString, "out");
			else
				System.out.println(outputString);
		}
	}
}
