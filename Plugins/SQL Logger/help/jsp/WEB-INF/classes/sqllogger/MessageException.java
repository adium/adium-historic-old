/*
 * Created on Oct 26, 2004
 *
 * To change the template for this generated file go to
 * Window&gt;Preferences&gt;Java&gt;Code Generation&gt;Code and Comments
 */
package sqllogger;

/**
 * @author jmelloy
 *
 * To change the template for this generated type comment go to
 * Window&gt;Preferences&gt;Java&gt;Code Generation&gt;Code and Comments
 */
public class MessageException extends Exception {

	/**
	 * 
	 */
	public MessageException() {
		super();
	}

	/**
	 * @param arg0
	 */
	public MessageException(String arg0) {
		super(arg0);
	}

	/**
	 * @param arg0
	 * @param arg1
	 */
	public MessageException(String arg0, Throwable arg1) {
		super(arg0, arg1);
	}

	/**
	 * @param arg0
	 */
	public MessageException(Throwable arg0) {
		super(arg0);
	}

}
