// _DCGaimOscarJoinChatView_EOArchive_pl.java
// Generated by EnterpriseObjects palette at niedziela, 27 listopada 2005 00:43:58 Europe/Warsaw

import com.webobjects.eoapplication.*;
import com.webobjects.eocontrol.*;
import com.webobjects.eointerface.*;
import com.webobjects.eointerface.swing.*;
import com.webobjects.foundation.*;
import java.awt.*;
import javax.swing.*;
import javax.swing.border.*;
import javax.swing.table.*;
import javax.swing.text.*;

public class _DCGaimOscarJoinChatView_EOArchive_pl extends com.webobjects.eoapplication.EOArchive {
    com.webobjects.eointerface.swing.EOTextField _nsTextField0, _nsTextField1, _nsTextField2, _nsTextField3, _nsTextField4, _nsTextField5, _nsTextField6;
    com.webobjects.eointerface.swing.EOView _nsCustomView0;

    public _DCGaimOscarJoinChatView_EOArchive_pl(Object owner, NSDisposableRegistry registry) {
        super(owner, registry);
    }

    protected void _construct() {
        Object owner = _owner();
        EOArchive._ObjectInstantiationDelegate delegate = (owner instanceof EOArchive._ObjectInstantiationDelegate) ? (EOArchive._ObjectInstantiationDelegate)owner : null;
        Object replacement;

        super._construct();

        _nsTextField6 = (com.webobjects.eointerface.swing.EOTextField)_registered(new com.webobjects.eointerface.swing.EOTextField(), "NSTextField11");
        _nsTextField5 = (com.webobjects.eointerface.swing.EOTextField)_registered(new com.webobjects.eointerface.swing.EOTextField(), "NSTextField211");
        _nsTextField4 = (com.webobjects.eointerface.swing.EOTextField)_registered(new com.webobjects.eointerface.swing.EOTextField(), "NSTextField21");
        _nsTextField3 = (com.webobjects.eointerface.swing.EOTextField)_registered(new com.webobjects.eointerface.swing.EOTextField(), "NSTextField2");

        if ((delegate != null) && ((replacement = delegate.objectForOutletPath(this, "view")) != null)) {
            _nsCustomView0 = (replacement == EOArchive._ObjectInstantiationDelegate.NullObject) ? null : (com.webobjects.eointerface.swing.EOView)replacement;
            _replacedObjects.setObjectForKey(replacement, "_nsCustomView0");
        } else {
            _nsCustomView0 = (com.webobjects.eointerface.swing.EOView)_registered(new com.webobjects.eointerface.swing.EOView(), "View");
        }

        if ((delegate != null) && ((replacement = delegate.objectForOutletPath(this, "view.nextFocusableComponent")) != null)) {
            _nsTextField2 = (replacement == EOArchive._ObjectInstantiationDelegate.NullObject) ? null : (com.webobjects.eointerface.swing.EOTextField)replacement;
            _replacedObjects.setObjectForKey(replacement, "_nsTextField2");
        } else {
            _nsTextField2 = (com.webobjects.eointerface.swing.EOTextField)_registered(new com.webobjects.eointerface.swing.EOTextField(), "NSTextField");
        }

        if ((delegate != null) && ((replacement = delegate.objectForOutletPath(this, "textField_inviteUsers.nextFocusableComponent")) != null)) {
            _nsTextField1 = (replacement == EOArchive._ObjectInstantiationDelegate.NullObject) ? null : (com.webobjects.eointerface.swing.EOTextField)replacement;
            _replacedObjects.setObjectForKey(replacement, "_nsTextField1");
        } else {
            _nsTextField1 = (com.webobjects.eointerface.swing.EOTextField)_registered(new com.webobjects.eointerface.swing.EOTextField(), "NSTextField3");
        }

        if ((delegate != null) && ((replacement = delegate.objectForOutletPath(this, "textField_inviteUsers.nextFocusableComponent.nextFocusableComponent.nextFocusableComponent")) != null)) {
            _nsTextField0 = (replacement == EOArchive._ObjectInstantiationDelegate.NullObject) ? null : (com.webobjects.eointerface.swing.EOTextField)replacement;
            _replacedObjects.setObjectForKey(replacement, "_nsTextField0");
        } else {
            _nsTextField0 = (com.webobjects.eointerface.swing.EOTextField)_registered(new com.webobjects.eointerface.swing.EOTextField(), "NSTextField31");
        }
    }

    protected void _awaken() {
        super._awaken();

        if (_replacedObjects.objectForKey("_nsTextField0") == null) {
            _connect(_owner(), _nsTextField0, "textField_inviteUsers");
        }

        if (_replacedObjects.objectForKey("_nsTextField1") == null) {
            _connect(_owner(), _nsTextField1, "textField_inviteMessage");
        }

        if (_replacedObjects.objectForKey("_nsTextField2") == null) {
            _connect(_owner(), _nsTextField2, "textField_roomName");
        }

        if (_replacedObjects.objectForKey("_nsCustomView0") == null) {
            _connect(_owner(), _nsCustomView0, "view");
        }

        if (_replacedObjects.objectForKey("_nsTextField2") == null) {
            _connect(_nsTextField2, _owner(), "delegate");
        }
    }

    protected void _init() {
        super._init();

        if (_replacedObjects.objectForKey("_nsCustomView0") == null) {
            _connect(_nsCustomView0, _nsTextField2, "nextFocusableComponent");
        }

        _setFontForComponent(_nsTextField6, "Lucida Grande", 11, Font.PLAIN);
        _nsTextField6.setEditable(false);
        _nsTextField6.setOpaque(false);
        _nsTextField6.setText("Oddziel nazwy kontakt\u00f3w przecinkami.");
        _nsTextField6.setHorizontalAlignment(javax.swing.JTextField.LEFT);
        _nsTextField6.setSelectable(false);
        _nsTextField6.setEnabled(true);
        _nsTextField6.setBorder(null);
        _setFontForComponent(_nsTextField5, "Lucida Grande", 13, Font.PLAIN);
        _nsTextField5.setEditable(false);
        _nsTextField5.setOpaque(false);
        _nsTextField5.setText("Zapro\u015b kontakty:");
        _nsTextField5.setHorizontalAlignment(javax.swing.JTextField.RIGHT);
        _nsTextField5.setSelectable(false);
        _nsTextField5.setEnabled(true);
        _nsTextField5.setBorder(null);
        _setFontForComponent(_nsTextField4, "Lucida Grande", 13, Font.PLAIN);
        _nsTextField4.setEditable(false);
        _nsTextField4.setOpaque(false);
        _nsTextField4.setText("Do\u0142\u0105cz wiadomo\u015b\u0107:");
        _nsTextField4.setHorizontalAlignment(javax.swing.JTextField.RIGHT);
        _nsTextField4.setSelectable(false);
        _nsTextField4.setEnabled(true);
        _nsTextField4.setBorder(null);
        _setFontForComponent(_nsTextField3, "Lucida Grande", 13, Font.PLAIN);
        _nsTextField3.setEditable(false);
        _nsTextField3.setOpaque(false);
        _nsTextField3.setText("Pok\u00f3j pogaw\u0119dek:");
        _nsTextField3.setHorizontalAlignment(javax.swing.JTextField.RIGHT);
        _nsTextField3.setSelectable(false);
        _nsTextField3.setEnabled(true);
        _nsTextField3.setBorder(null);

        if (_replacedObjects.objectForKey("_nsCustomView0") == null) {
            if (!(_nsCustomView0.getLayout() instanceof EOViewLayout)) { _nsCustomView0.setLayout(new EOViewLayout()); }
            _nsTextField3.setSize(120, 17);
            _nsTextField3.setLocation(-2, 4);
            ((EOViewLayout)_nsCustomView0.getLayout()).setAutosizingMask(_nsTextField3, EOViewLayout.MinYMargin);
            _nsCustomView0.add(_nsTextField3);
            _nsTextField2.setSize(266, 22);
            _nsTextField2.setLocation(123, 1);
            ((EOViewLayout)_nsCustomView0.getLayout()).setAutosizingMask(_nsTextField2, EOViewLayout.MinYMargin);
            _nsCustomView0.add(_nsTextField2);
            _nsTextField1.setSize(266, 60);
            _nsTextField1.setLocation(123, 110);
            ((EOViewLayout)_nsCustomView0.getLayout()).setAutosizingMask(_nsTextField1, EOViewLayout.MinYMargin);
            _nsCustomView0.add(_nsTextField1);
            _nsTextField4.setSize(120, 34);
            _nsTextField4.setLocation(-2, 113);
            ((EOViewLayout)_nsCustomView0.getLayout()).setAutosizingMask(_nsTextField4, EOViewLayout.MinYMargin);
            _nsCustomView0.add(_nsTextField4);
            _nsTextField5.setSize(120, 17);
            _nsTextField5.setLocation(-2, 31);
            ((EOViewLayout)_nsCustomView0.getLayout()).setAutosizingMask(_nsTextField5, EOViewLayout.MinYMargin);
            _nsCustomView0.add(_nsTextField5);
            _nsTextField0.setSize(266, 60);
            _nsTextField0.setLocation(123, 31);
            ((EOViewLayout)_nsCustomView0.getLayout()).setAutosizingMask(_nsTextField0, EOViewLayout.MinYMargin);
            _nsCustomView0.add(_nsTextField0);
            _nsTextField6.setSize(224, 14);
            _nsTextField6.setLocation(120, 91);
            ((EOViewLayout)_nsCustomView0.getLayout()).setAutosizingMask(_nsTextField6, EOViewLayout.MinYMargin);
            _nsCustomView0.add(_nsTextField6);
        }

        if (_replacedObjects.objectForKey("_nsTextField2") == null) {
            _connect(_nsTextField2, _nsTextField0, "nextFocusableComponent");
        }

        if (_replacedObjects.objectForKey("_nsTextField2") == null) {
            _setFontForComponent(_nsTextField2, "Lucida Grande", 13, Font.PLAIN);
            _nsTextField2.setEditable(true);
            _nsTextField2.setOpaque(true);
            _nsTextField2.setText("");
            _nsTextField2.setHorizontalAlignment(javax.swing.JTextField.LEFT);
            _nsTextField2.setSelectable(true);
            _nsTextField2.setEnabled(true);
        }

        if (_replacedObjects.objectForKey("_nsTextField1") == null) {
            _connect(_nsTextField1, _nsTextField2, "nextFocusableComponent");
        }

        if (_replacedObjects.objectForKey("_nsTextField1") == null) {
            _setFontForComponent(_nsTextField1, "Lucida Grande", 13, Font.PLAIN);
            _nsTextField1.setEditable(true);
            _nsTextField1.setOpaque(true);
            _nsTextField1.setText("");
            _nsTextField1.setHorizontalAlignment(javax.swing.JTextField.LEFT);
            _nsTextField1.setSelectable(true);
            _nsTextField1.setEnabled(true);
        }

        if (_replacedObjects.objectForKey("_nsTextField0") == null) {
            _connect(_nsTextField0, _nsTextField1, "nextFocusableComponent");
        }

        if (_replacedObjects.objectForKey("_nsTextField0") == null) {
            _setFontForComponent(_nsTextField0, "Lucida Grande", 13, Font.PLAIN);
            _nsTextField0.setEditable(true);
            _nsTextField0.setOpaque(true);
            _nsTextField0.setText("");
            _nsTextField0.setHorizontalAlignment(javax.swing.JTextField.LEFT);
            _nsTextField0.setSelectable(true);
            _nsTextField0.setEnabled(true);
        }
    }
}
