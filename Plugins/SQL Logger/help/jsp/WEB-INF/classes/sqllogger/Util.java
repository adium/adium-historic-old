/*
 * $URL$
 * $Id$
 *
 * Jeffrey Melloy
 */

package sqllogger;

/**
 * Utilities for the SQL Logger.  Checks if strings are null or empty, etc.
 *
 * @author      Jeffrey Melloy &lt;jmelloy@visualdistortion.org&gt;
 * @version     $Rev$ $Date$
 **/

public class Util {
    public static String checkNull(String input, boolean literal) {
        if(input == null ||
            input.equals("") ||
            (literal && input.equals("null"))) return null;
        else return input;
    }

    public static String checkNull(String input) {
        return checkNull(input, true);
    }

    public static String safeString(String input) {
        if(input == null) return "";
        else return input;
    }

    public static String safeString(String input, String output) {
        if(input == null) return output;
        else return input;
    }

    public static int checkInt(String input) {
        int retVal;
        try {
            retVal = Integer.parseInt(input);
        } catch (NumberFormatException e) {
            retVal = 0;
        }

        return retVal;
    }

    public static int checkInt(String input, int out) {
        int retVal;
        try {
            retVal = Integer.parseInt(input);
        } catch (NumberFormatException e) {
            retVal = out;
        }

        return retVal;
    }

    public static String compare(String a, String b, String out) {
        if(a == null || b == null) {
            return "";
        }

        if(a.equals(b)) {
            return out;
        } else {
            return "";
        }
    }
}
