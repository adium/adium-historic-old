// _ESGaimMSNAccountView_EOArchive_pl.java
// Generated by EnterpriseObjects palette at niedziela, 27 listopada 2005 00:44:26 Europe/Warsaw

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

public class _ESGaimMSNAccountView_EOArchive_pl extends com.webobjects.eoapplication.EOArchive {
    com.webobjects.eointerface.swing.EOTextField _nsTextField0, _nsTextField1, _nsTextField2, _nsTextField3, _nsTextField4, _nsTextField5, _nsTextField6;
    com.webobjects.eointerface.swing.EOView _nsCustomView0, _nsCustomView1;
    javax.swing.JCheckBox _nsButton0, _nsButton1;

    public _ESGaimMSNAccountView_EOArchive_pl(Object owner, NSDisposableRegistry registry) {
        super(owner, registry);
    }

    protected void _construct() {
        Object owner = _owner();
        EOArchive._ObjectInstantiationDelegate delegate = (owner instanceof EOArchive._ObjectInstantiationDelegate) ? (EOArchive._ObjectInstantiationDelegate)owner : null;
        Object replacement;

        super._construct();


        if ((delegate != null) && ((replacement = delegate.objectForOutletPath(this, "checkBox_HTTPConnectMethod")) != null)) {
            _nsButton1 = (replacement == EOArchive._ObjectInstantiationDelegate.NullObject) ? null : (javax.swing.JCheckBox)replacement;
            _replacedObjects.setObjectForKey(replacement, "_nsButton1");
        } else {
            _nsButton1 = (javax.swing.JCheckBox)_registered(new javax.swing.JCheckBox("Po\u0142\u0105cz przez HTTP"), "NSButton41111");
        }

        _nsTextField6 = (com.webobjects.eointerface.swing.EOTextField)_registered(new com.webobjects.eointerface.swing.EOTextField(), "NSTextField211");
        _nsTextField5 = (com.webobjects.eointerface.swing.EOTextField)_registered(new com.webobjects.eointerface.swing.EOTextField(), "NSTextField221");

        if ((delegate != null) && ((replacement = delegate.objectForOutletPath(this, "checkBox_checkMail")) != null)) {
            _nsButton0 = (replacement == EOArchive._ObjectInstantiationDelegate.NullObject) ? null : (javax.swing.JCheckBox)replacement;
            _replacedObjects.setObjectForKey(replacement, "_nsButton0");
        } else {
            _nsButton0 = (javax.swing.JCheckBox)_registered(new javax.swing.JCheckBox("Sprawd\u017a now\u0105 poczt\u0119"), "NSButton4111");
        }

        if ((delegate != null) && ((replacement = delegate.objectForOutletPath(this, "textField_connectHost")) != null)) {
            _nsTextField4 = (replacement == EOArchive._ObjectInstantiationDelegate.NullObject) ? null : (com.webobjects.eointerface.swing.EOTextField)replacement;
            _replacedObjects.setObjectForKey(replacement, "_nsTextField4");
        } else {
            _nsTextField4 = (com.webobjects.eointerface.swing.EOTextField)_registered(new com.webobjects.eointerface.swing.EOTextField(), "NSTextField3");
        }

        _nsTextField3 = (com.webobjects.eointerface.swing.EOTextField)_registered(new com.webobjects.eointerface.swing.EOTextField(), "NSTextField22");

        if ((delegate != null) && ((replacement = delegate.objectForOutletPath(this, "view_options")) != null)) {
            _nsCustomView1 = (replacement == EOArchive._ObjectInstantiationDelegate.NullObject) ? null : (com.webobjects.eointerface.swing.EOView)replacement;
            _replacedObjects.setObjectForKey(replacement, "_nsCustomView1");
        } else {
            _nsCustomView1 = (com.webobjects.eointerface.swing.EOView)_registered(new com.webobjects.eointerface.swing.EOView(), "Options");
        }

        _nsTextField2 = (com.webobjects.eointerface.swing.EOTextField)_registered(new com.webobjects.eointerface.swing.EOTextField(), "NSTextField11");

        if ((delegate != null) && ((replacement = delegate.objectForOutletPath(this, "textField_alias")) != null)) {
            _nsTextField1 = (replacement == EOArchive._ObjectInstantiationDelegate.NullObject) ? null : (com.webobjects.eointerface.swing.EOTextField)replacement;
            _replacedObjects.setObjectForKey(replacement, "_nsTextField1");
        } else {
            _nsTextField1 = (com.webobjects.eointerface.swing.EOTextField)_registered(new com.webobjects.eointerface.swing.EOTextField(), "NSTextField441");
        }

        if ((delegate != null) && ((replacement = delegate.objectForOutletPath(this, "view_profile")) != null)) {
            _nsCustomView0 = (replacement == EOArchive._ObjectInstantiationDelegate.NullObject) ? null : (com.webobjects.eointerface.swing.EOView)replacement;
            _replacedObjects.setObjectForKey(replacement, "_nsCustomView0");
        } else {
            _nsCustomView0 = (com.webobjects.eointerface.swing.EOView)_registered(new com.webobjects.eointerface.swing.EOView(), "Profile");
        }

        if ((delegate != null) && ((replacement = delegate.objectForOutletPath(this, "textField_connectPort")) != null)) {
            _nsTextField0 = (replacement == EOArchive._ObjectInstantiationDelegate.NullObject) ? null : (com.webobjects.eointerface.swing.EOTextField)replacement;
            _replacedObjects.setObjectForKey(replacement, "_nsTextField0");
        } else {
            _nsTextField0 = (com.webobjects.eointerface.swing.EOTextField)_registered(new com.webobjects.eointerface.swing.EOTextField(), "NSTextField12");
        }
    }

    protected void _awaken() {
        super._awaken();

        if (_replacedObjects.objectForKey("_nsTextField0") == null) {
            _connect(_owner(), _nsTextField0, "textField_connectPort");
        }

        if (_replacedObjects.objectForKey("_nsButton1") == null) {
            _connect(_owner(), _nsButton1, "checkBox_HTTPConnectMethod");
        }

        _nsButton1.addActionListener((com.webobjects.eointerface.swing.EOControlActionAdapter)_registered(new com.webobjects.eointerface.swing.EOControlActionAdapter(_owner(), "changedPreference", _nsButton1), ""));

        if (_replacedObjects.objectForKey("_nsButton0") == null) {
            _connect(_owner(), _nsButton0, "checkBox_checkMail");
        }

        _nsButton0.addActionListener((com.webobjects.eointerface.swing.EOControlActionAdapter)_registered(new com.webobjects.eointerface.swing.EOControlActionAdapter(_owner(), "changedPreference", _nsButton0), ""));

        if (_replacedObjects.objectForKey("_nsTextField4") == null) {
            _connect(_owner(), _nsTextField4, "textField_connectHost");
        }

        _nsTextField4.addActionListener((com.webobjects.eointerface.swing.EOControlActionAdapter)_registered(new com.webobjects.eointerface.swing.EOControlActionAdapter(_owner(), "changedPreference", _nsTextField4), ""));

        if (_replacedObjects.objectForKey("_nsCustomView1") == null) {
            _connect(_owner(), _nsCustomView1, "view_options");
        }

        if (_replacedObjects.objectForKey("_nsTextField1") == null) {
            _connect(_owner(), _nsTextField1, "textField_alias");
        }

        _nsTextField1.addActionListener((com.webobjects.eointerface.swing.EOControlActionAdapter)_registered(new com.webobjects.eointerface.swing.EOControlActionAdapter(_owner(), "changedPreference", _nsTextField1), ""));

        if (_replacedObjects.objectForKey("_nsCustomView0") == null) {
            _connect(_owner(), _nsCustomView0, "view_profile");
        }

        _nsTextField0.addActionListener((com.webobjects.eointerface.swing.EOControlActionAdapter)_registered(new com.webobjects.eointerface.swing.EOControlActionAdapter(_owner(), "changedPreference", _nsTextField0), ""));
    }

    protected void _init() {
        super._init();

        if (_replacedObjects.objectForKey("_nsButton1") == null) {
            _setFontForComponent(_nsButton1, "Lucida Grande", 13, Font.PLAIN);
        }

        _setFontForComponent(_nsTextField6, "Lucida Grande", 13, Font.PLAIN);
        _nsTextField6.setEditable(false);
        _nsTextField6.setOpaque(false);
        _nsTextField6.setText("Port:");
        _nsTextField6.setHorizontalAlignment(javax.swing.JTextField.RIGHT);
        _nsTextField6.setSelectable(false);
        _nsTextField6.setEnabled(true);
        _nsTextField6.setBorder(null);
        _setFontForComponent(_nsTextField5, "Lucida Grande", 13, Font.PLAIN);
        _nsTextField5.setEditable(false);
        _nsTextField5.setOpaque(false);
        _nsTextField5.setText("Email:");
        _nsTextField5.setHorizontalAlignment(javax.swing.JTextField.RIGHT);
        _nsTextField5.setSelectable(false);
        _nsTextField5.setEnabled(true);
        _nsTextField5.setBorder(null);

        if (_replacedObjects.objectForKey("_nsButton0") == null) {
            _setFontForComponent(_nsButton0, "Lucida Grande", 13, Font.PLAIN);
        }

        if (_replacedObjects.objectForKey("_nsTextField4") == null) {
            _setFontForComponent(_nsTextField4, "Lucida Grande", 13, Font.PLAIN);
            _nsTextField4.setEditable(true);
            _nsTextField4.setOpaque(true);
            _nsTextField4.setText("");
            _nsTextField4.setHorizontalAlignment(javax.swing.JTextField.LEFT);
            _nsTextField4.setSelectable(true);
            _nsTextField4.setEnabled(true);
        }

        _setFontForComponent(_nsTextField3, "Lucida Grande", 13, Font.PLAIN);
        _nsTextField3.setEditable(false);
        _nsTextField3.setOpaque(false);
        _nsTextField3.setText("Serwer logowania:");
        _nsTextField3.setHorizontalAlignment(javax.swing.JTextField.RIGHT);
        _nsTextField3.setSelectable(false);
        _nsTextField3.setEnabled(true);
        _nsTextField3.setBorder(null);

        if (_replacedObjects.objectForKey("_nsCustomView1") == null) {
            if (!(_nsCustomView1.getLayout() instanceof EOViewLayout)) { _nsCustomView1.setLayout(new EOViewLayout()); }
            _nsTextField0.setSize(51, 22);
            _nsTextField0.setLocation(387, 0);
            ((EOViewLayout)_nsCustomView1.getLayout()).setAutosizingMask(_nsTextField0, EOViewLayout.MaxYMargin);
            _nsCustomView1.add(_nsTextField0);
            _nsTextField3.setSize(140, 17);
            _nsTextField3.setLocation(-2, 3);
            ((EOViewLayout)_nsCustomView1.getLayout()).setAutosizingMask(_nsTextField3, EOViewLayout.MaxYMargin);
            _nsCustomView1.add(_nsTextField3);
            _nsTextField4.setSize(200, 22);
            _nsTextField4.setLocation(143, 0);
            ((EOViewLayout)_nsCustomView1.getLayout()).setAutosizingMask(_nsTextField4, EOViewLayout.MaxYMargin);
            _nsCustomView1.add(_nsTextField4);
            _nsButton0.setSize(273, 17);
            _nsButton0.setLocation(140, 57);
            ((EOViewLayout)_nsCustomView1.getLayout()).setAutosizingMask(_nsButton0, EOViewLayout.MaxYMargin);
            _nsCustomView1.add(_nsButton0);
            _nsTextField5.setSize(140, 17);
            _nsTextField5.setLocation(-2, 56);
            ((EOViewLayout)_nsCustomView1.getLayout()).setAutosizingMask(_nsTextField5, EOViewLayout.MaxYMargin);
            _nsCustomView1.add(_nsTextField5);
            _nsTextField6.setSize(34, 17);
            _nsTextField6.setLocation(348, 3);
            ((EOViewLayout)_nsCustomView1.getLayout()).setAutosizingMask(_nsTextField6, EOViewLayout.MaxYMargin);
            _nsCustomView1.add(_nsTextField6);
            _nsButton1.setSize(273, 17);
            _nsButton1.setLocation(140, 29);
            ((EOViewLayout)_nsCustomView1.getLayout()).setAutosizingMask(_nsButton1, EOViewLayout.MaxYMargin);
            _nsCustomView1.add(_nsButton1);
        }

        _setFontForComponent(_nsTextField2, "Lucida Grande", 13, Font.PLAIN);
        _nsTextField2.setEditable(false);
        _nsTextField2.setOpaque(false);
        _nsTextField2.setText("Wy\u015bwietlana nazwa:");
        _nsTextField2.setHorizontalAlignment(javax.swing.JTextField.LEFT);
        _nsTextField2.setSelectable(false);
        _nsTextField2.setEnabled(true);
        _nsTextField2.setBorder(null);

        if (_replacedObjects.objectForKey("_nsTextField1") == null) {
            _setFontForComponent(_nsTextField1, "Lucida Grande", 13, Font.PLAIN);
            _nsTextField1.setEditable(true);
            _nsTextField1.setOpaque(true);
            _nsTextField1.setText("");
            _nsTextField1.setHorizontalAlignment(javax.swing.JTextField.LEFT);
            _nsTextField1.setSelectable(true);
            _nsTextField1.setEnabled(true);
        }

        if (_replacedObjects.objectForKey("_nsCustomView0") == null) {
            if (!(_nsCustomView0.getLayout() instanceof EOViewLayout)) { _nsCustomView0.setLayout(new EOViewLayout()); }
            _nsTextField1.setSize(340, 59);
            _nsTextField1.setLocation(1, 25);
            ((EOViewLayout)_nsCustomView0.getLayout()).setAutosizingMask(_nsTextField1, EOViewLayout.MaxYMargin);
            _nsCustomView0.add(_nsTextField1);
            _nsTextField2.setSize(129, 17);
            _nsTextField2.setLocation(-2, 0);
            ((EOViewLayout)_nsCustomView0.getLayout()).setAutosizingMask(_nsTextField2, EOViewLayout.MaxYMargin);
            _nsCustomView0.add(_nsTextField2);
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
