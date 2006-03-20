//
//  JoscarStateInfo.java
//  Adium
//
//  Created by Evan Schoenberg on 6/28/05.
//

package net.adium.joscarBridge;

import net.kano.joustsim.oscar.*;
import net.kano.joustsim.oscar.oscar.loginstatus.*;

import net.kano.joscar.snaccmd.auth.*;

import java.lang.String;

public class JoscarStateInfo {
	private String errorMessage;
	private String errorCode;

	//Returns a message word if an error occurred. Null if there was no error.
	public String errorMessage() {
		return errorMessage;
	}
	
	//Return an error code, or null
	public String errorCode() {
		return errorCode;
	}
	
	public JoscarStateInfo(StateInfo sinfo) {
		processStateInfo(sinfo);
	}

	private void processStateInfo(StateInfo sinfo) {
		final String msg;
		if (sinfo instanceof LoginFailureStateInfo) {
			LoginFailureStateInfo lfsi
			= (LoginFailureStateInfo) sinfo;
			LoginFailureInfo lfi = lfsi.getLoginFailureInfo();
			if (lfi instanceof TimeoutFailureInfo) {
				//A timeout occurred
				this.errorMessage = "Timeout";
				
			} else if (lfi instanceof FlapErrorFailureInfo
					   || lfi instanceof SnacErrorFailureInfo) {
				String errcode;
				if (lfi instanceof FlapErrorFailureInfo) {
					FlapErrorFailureInfo fi = (FlapErrorFailureInfo) lfi;
					errcode = "Red-" + fi.getFlapError();
				} else {
					SnacErrorFailureInfo si = (SnacErrorFailureInfo) lfi;
					errcode = "Green-" + si;
				}
				//Unknown
				this.errorMessage = "Unknown";
				this.errorCode = errcode;
				
			} else if (lfi instanceof AuthFailureInfo) {
				AuthFailureInfo afi = (AuthFailureInfo) lfi;
				int ec = afi.getErrorCode();
				
				if (ec == AuthResponse.ERROR_ACCOUNT_DELETED) {
					//Your account has been deleted.
					this.errorMessage = "Deleted";
				} else if (ec == AuthResponse.ERROR_BAD_INPUT) {
					//The connection was corrupted while signing on. Try signing on again.
					this.errorMessage = "Corrupted";
					
				} else if (ec == AuthResponse.ERROR_BAD_PASSWORD) {
					//The password you entered is not correct.
					this.errorMessage = "Password";
					
				} else if (ec == AuthResponse.ERROR_CLIENT_TOO_OLD) {
					//AOL said this version is too old. Uh oh.
					this.errorMessage = "TooOld";
					
				} else if (ec == AuthResponse.ERROR_CONNECTING_TOO_MUCH_A
						   || ec == AuthResponse.ERROR_CONNECTING_TOO_MUCH_B) {
					//You are connecting too frequently. Wait 5 or 10 minutes and try again.
					this.errorMessage = "TooFrequently";
					
				} else if (ec == AuthResponse.ERROR_INVALID_SECURID) {
					/*
					 * The SecurID you entered is wrong. If you did not enter a SecurID,
					 * some other error occurred. Try signing on again.
					 */
					this.errorMessage = "SecurID";
					
				} else if (ec == AuthResponse.ERROR_INVALID_SN_OR_PASS_A
						   || ec == AuthResponse.ERROR_INVALID_SN_OR_PASS_B) {
					//Screenname or Password
					this.errorMessage = "Password";
					
				} else if (ec == AuthResponse.ERROR_SIGNON_BLOCKED) {
					//Your account has been temporarily blocked.
					this.errorMessage = "TemporarilyBlocked";
					
				} else if (ec == AuthResponse.ERROR_TEMP_UNAVAILABLE_A
						   || ec == AuthResponse.ERROR_TEMP_UNAVAILABLE_B
						   || ec == AuthResponse.ERROR_TEMP_UNAVAILABLE_C
						   || ec == AuthResponse.ERROR_TEMP_UNAVAILABLE_D
						   || ec == AuthResponse.ERROR_TEMP_UNAVAILABLE_E
						   || ec == AuthResponse.ERROR_TEMP_UNAVAILABLE_F
						   || ec == AuthResponse.ERROR_TEMP_UNAVAILABLE_G) {
					/* AIM is temporarily unavailable. Try signing on again. If this error
					* continues to occur, try again later.
					*/
					this.errorMessage = "TemporarilyUnavailable";
					
				} else if (ec == AuthResponse.ERROR_UNDER_13) {
					/*
					 * Your account is marked as being owned by someone under the age of 13.
					 * You must be 13 years of age to use the AIM service.
					 * If this is not correct, visit the AIM website.
					 */
					this.errorMessage = "Under13";
					
				} else {
					//Unknown
					this.errorMessage = "Unknown";
					this.errorCode = "Blue-" + ec;					
				}
			} else if (lfi instanceof DisconnectedFailureInfo) {
				DisconnectedFailureInfo di = (DisconnectedFailureInfo) lfi;
				if (!di.isOnPurpose()) {
					//"The connection to the AIM service was lost while signing in."
					this.errorMessage = "ConnectionLost";
					
				} else {
					// the user did it on purpose, it looks like, so we
					// don't need to tell him that he did it
					this.errorMessage = null;
				}
				
			} else {
				//"An unknown error occurred while signing in."
				this.errorMessage = "Unknown";
			}
			
		} else if (sinfo instanceof ConnectionFailedStateInfo) {
			ConnectionFailedStateInfo cfsi
			= (ConnectionFailedStateInfo) sinfo;
			//Connection could not be made
			this.errorMessage = "ConnectionFailed";
			
		} else if (sinfo instanceof DisconnectedStateInfo) {
			DisconnectedStateInfo di = (DisconnectedStateInfo) sinfo;
			if (!di.isOnPurpose()) {
				this.errorMessage = "ConnectionLost";
				
			} else {
				// the user wanted it, so we don't need to tell him
				this.errorMessage = null;
			}
		} else {
			// nothing interesting happened
			this.errorMessage = null;
		}
	}
}
