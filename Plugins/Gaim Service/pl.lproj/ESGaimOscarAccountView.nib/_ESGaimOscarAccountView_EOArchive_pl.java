// _ESGaimOscarAccountView_EOArchive_pl.java
// Generated by EnterpriseObjects palette at niedziela, 27 listopada 2005 00:44:34 Europe/Warsaw

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

public class _ESGaimOscarAccountView_EOArchive_pl extends com.webobjects.eoapplication.EOArchive {
    com.webobjects.eointerface.swing.EOTextArea _nsTextView0;
    com.webobjects.eointerface.swing.EOTextField _nsTextField0, _nsTextField1, _nsTextField2, _nsTextField3, _nsTextField4, _nsTextField5, _nsTextField6, _nsTextField7;
    com.webobjects.eointerface.swing.EOView _nsCustomView0, _nsCustomView1;
    javax.swing.JCheckBox _nsButton0;

    public _ESGaimOscarAccountView_EOArchive_pl(Object owner, NSDisposableRegistry registry) {
        super(owner, registry);
    }

    protected void _construct() {
        Object owner = _owner();
        EOArchive._ObjectInstantiationDelegate delegate = (owner instanceof EOArchive._ObjectInstantiationDelegate) ? (EOArchive._ObjectInstantiationDelegate)owner : null;
        Object replacement;

        super._construct();


        if ((delegate != null) && ((replacement = delegate.objectForOutletPath(this, "textView_textProfile")) != null)) {
            _nsTextView0 = (replacement == EOArchive._ObjectInstantiationDelegate.NullObject) ? null : (com.webobjects.eointerface.swing.EOTextArea)replacement;
            _replacedObjects.setObjectForKey(replacement, "_nsTextView0");
        } else {
            _nsTextView0 = (com.webobjects.eointerface.swing.EOTextArea)_registered(new com.webobjects.eointerface.swing.EOTextArea(), "NSTextView");
        }

        _nsTextField7 = (com.webobjects.eointerface.swing.EOTextField)_registered(new com.webobjects.eointerface.swing.EOTextField(), "NSTextField211");

        if ((delegate != null) && ((replacement = delegate.objectForOutletPath(this, "textField_alias")) != null)) {
            _nsTextField6 = (replacement == EOArchive._ObjectInstantiationDelegate.NullObject) ? null : (com.webobjects.eointerface.swing.EOTextField)replacement;
            _replacedObjects.setObjectForKey(replacement, "_nsTextField6");
        } else {
            _nsTextField6 = (com.webobjects.eointerface.swing.EOTextField)_registered(new com.webobjects.eointerface.swing.EOTextField(), "NSTextField11");
        }

        if ((delegate != null) && ((replacement = delegate.objectForOutletPath(this, "view_profile")) != null)) {
            _nsCustomView1 = (replacement == EOArchive._ObjectInstantiationDelegate.NullObject) ? null : (com.webobjects.eointerface.swing.EOView)replacement;
            _replacedObjects.setObjectForKey(replacement, "_nsCustomView1");
        } else {
            _nsCustomView1 = (com.webobjects.eointerface.swing.EOView)_registered(new com.webobjects.eointerface.swing.EOView(), "Profile");
        }

        _nsTextField5 = (com.webobjects.eointerface.swing.EOTextField)_registered(new com.webobjects.eointerface.swing.EOTextField(), "NSTextField221");
        _nsTextField4 = (com.webobjects.eointerface.swing.EOTextField)_registered(new com.webobjects.eointerface.swing.EOTextField(), "NSTextField211");

        if ((delegate != null) && ((replacement = delegate.objectForOutletPath(this, "textField_connectPort")) != null)) {
            _nsTextField3 = (replacement == EOArchive._ObjectInstantiationDelegate.NullObject) ? null : (com.webobjects.eointerface.swing.EOTextField)replacement;
            _replacedObjects.setObjectForKey(replacement, "_nsTextField3");
        } else {
            _nsTextField3 = (com.webobjects.eointerface.swing.EOTextField)_registered(new com.webobjects.eointerface.swing.EOTextField(), "NSTextField12");
        }

        if ((delegate != null) && ((replacement = delegate.objectForOutletPath(this, "checkBox_checkMail")) != null)) {
            _nsButton0 = (replacement == EOArchive._ObjectInstantiationDelegate.NullObject) ? null : (javax.swing.JCheckBox)replacement;
            _replacedObjects.setObjectForKey(replacement, "_nsButton0");
        } else {
            _nsButton0 = (javax.swing.JCheckBox)_registered(new javax.swing.JCheckBox("Sprawd\u017a now\u0105 poczt\u0119 (tylko konta AOL)"), "NSButton4111");
        }

        if ((delegate != null) && ((replacement = delegate.objectForOutletPath(this, "view_options")) != null)) {
            _nsCustomView0 = (replacement == EOArchive._ObjectInstantiationDelegate.NullObject) ? null : (com.webobjects.eointerface.swing.EOView)replacement;
            _replacedObjects.setObjectForKey(replacement, "_nsCustomView0");
        } else {
            _nsCustomView0 = (com.webobjects.eointerface.swing.EOView)_registered(new com.webobjects.eointerface.swing.EOView(), "Options");
        }

        if ((delegate != null) && ((replacement = delegate.objectForOutletPath(this, "textField_connectHost")) != null)) {
            _nsTextField2 = (replacement == EOArchive._ObjectInstantiationDelegate.NullObject) ? null : (com.webobjects.eointerface.swing.EOTextField)replacement;
            _replacedObjects.setObjectForKey(replacement, "_nsTextField2");
        } else {
            _nsTextField2 = (com.webobjects.eointerface.swing.EOTextField)_registered(new com.webobjects.eointerface.swing.EOTextField(), "NSTextField3");
        }

        _nsTextField1 = (com.webobjects.eointerface.swing.EOTextField)_registered(new com.webobjects.eointerface.swing.EOTextField(), "NSTextField22");
        _nsTextField0 = (com.webobjects.eointerface.swing.EOTextField)_registered(new com.webobjects.eointerface.swing.EOTextField(), "NSTextField2111");
    }

    protected void _awaken() {
        super._awaken();

        if (_replacedObjects.objectForKey("_nsTextField2") == null) {
            _connect(_owner(), _nsTextField2, "textField_connectHost");
        }

        if (_replacedObjects.objectForKey("_nsTextView0") == null) {
            _connect(_owner(), _nsTextView0, "textView_textProfile");
        }

        if (_replacedObjects.objectForKey("_nsTextView0") == null) {
            _connect(_nsTextView0, _owner(), "delegate");
        }

        if (_replacedObjects.objectForKey("_nsTextField6") == null) {
            _connect(_owner(), _nsTextField6, "textField_alias");
        }

        _nsTextField6.addActionListener((com.webobjects.eointerface.swing.EOControlActionAdapter)_registered(new com.webobjects.eointerface.swing.EOControlActionAdapter(_owner(), "changedPreference", _nsTextField6), ""));

        if (_replacedObjects.objectForKey("_nsCustomView1") == null) {
            _connect(_owner(), _nsCustomView1, "view_profile");
        }

        if (_replacedObjects.objectForKey("_nsTextField3") == null) {
            _connect(_owner(), _nsTextField3, "textField_connectPort");
        }

        _nsTextField3.addActionListener((com.webobjects.eointerface.swing.EOControlActionAdapter)_registered(new com.webobjects.eointerface.swing.EOControlActionAdapter(_owner(), "changedPreference", _nsTextField3), ""));

        if (_replacedObjects.objectForKey("_nsButton0") == null) {
            _connect(_owner(), _nsButton0, "checkBox_checkMail");
        }

        _nsButton0.addActionListener((com.webobjects.eointerface.swing.EOControlActionAdapter)_registered(new com.webobjects.eointerface.swing.EOControlActionAdapter(_owner(), "changedPreference", _nsButton0), ""));

        if (_replacedObjects.objectForKey("_nsCustomView0") == null) {
            _connect(_owner(), _nsCustomView0, "view_options");
        }

        _nsTextField2.addActionListener((com.webobjects.eointerface.swing.EOControlActionAdapter)_registered(new com.webobjects.eointerface.swing.EOControlActionAdapter(_owner(), "changedPreference", _nsTextField2), ""));
    }

    protected void _init() {
        super._init();

        if (_replacedObjects.objectForKey("_nsTextView0") == null) {
            _nsTextView0.setEditable(true);
            _nsTextView0.setOpaque(true);
            _nsTextView0.setText("");
        }

        _setFontForComponent(_nsTextField7, "Lucida Grande", 13, Font.PLAIN);
        _nsTextField7.setEditable(false);
        _nsTextField7.setOpaque(false);
        _nsTextField7.setText("Pseudonim:");
        _nsTextField7.setHorizontalAlignment(javax.swing.JTextField.RIGHT);
        _nsTextField7.setSelectable(false);
        _nsTextField7.setEnabled(true);
        _nsTextField7.setBorder(null);

        if (_replacedObjects.objectForKey("_nsTextField6") == null) {
            _setFontForComponent(_nsTextField6, "Lucida Grande", 13, Font.PLAIN);
            _nsTextField6.setEditable(true);
            _nsTextField6.setOpaque(true);
            _nsTextField6.setText("");
            _nsTextField6.setHorizontalAlignment(javax.swing.JTextField.LEFT);
            _nsTextField6.setSelectable(true);
            _nsTextField6.setEnabled(true);
        }

        if (_replacedObjects.objectForKey("_nsCustomView1") == null) {
            if (!(_nsCustomView1.getLayout() instanceof EOViewLayout)) { _nsCustomView1.setLayout(new EOViewLayout()); }
            _nsTextField6.setSize(260, 22);
            _nsTextField6.setLocation(81, 0);
            ((EOViewLayout)_nsCustomView1.getLayout()).setAutosizingMask(_nsTextField6, EOViewLayout.MaxYMargin);
            _nsCustomView1.add(_nsTextField6);
            _nsTextField7.setSize(78, 17);
            _nsTextField7.setLocation(-2, 3);
            ((EOViewLayout)_nsCustomView1.getLayout()).setAutosizingMask(_nsTextField7, EOViewLayout.MaxYMargin);
            _nsCustomView1.add(_nsTextField7);
            _nsTextField0.setSize(78, 17);
            _nsTextField0.setLocation(-2, 28);
            ((EOViewLayout)_nsCustomView1.getLayout()).setAutosizingMask(_nsTextField0, EOViewLayout.MaxYMargin);
            _nsCustomView1.add(_nsTextField0);
            _nsTextView0.setSize(260, 117);
            _nsTextView0.setLocation(80, 30);
            ((EOViewLayout)_nsCustomView1.getLayout()).setAutosizingMask(_nsTextView0, EOViewLayout.WidthSizable | EOViewLayout.HeightSizable);
            _nsCustomView1.add(_nsTextView0);
        }

        _setFontForComponent(_nsTextField5, "Lucida Grande", 13, Font.PLAIN);
        _nsTextField5.setEditable(false);
        _nsTextField5.setOpaque(false);
        _nsTextField5.setText("Email:");
        _nsTextField5.setHorizontalAlignment(javax.swing.JTextField.RIGHT);
        _nsTextField5.setSelectable(false);
        _nsTextField5.setEnabled(true);
        _nsTextField5.setBorder(null);
        _setFontForComponent(_nsTextField4, "Lucida Grande", 13, Font.PLAIN);
        _nsTextField4.setEditable(false);
        _nsTextField4.setOpaque(false);
        _nsTextField4.setText("Port:");
        _nsTextField4.setHorizontalAlignment(javax.swing.JTextField.RIGHT);
        _nsTextField4.setSelectable(false);
        _nsTextField4.setEnabled(true);
        _nsTextField4.setBorder(null);

        if (_replacedObjects.objectForKey("_nsTextField3") == null) {
            _setFontForComponent(_nsTextField3, "Lucida Grande", 13, Font.PLAIN);
            _nsTextField3.setEditable(true);
            _nsTextField3.setOpaque(true);
            _nsTextField3.setText("");
            _nsTextField3.setHorizontalAlignment(javax.swing.JTextField.LEFT);
            _nsTextField3.setSelectable(true);
            _nsTextField3.setEnabled(true);
        }

        if (_replacedObjects.objectForKey("_nsButton0") == null) {
            _setFontForComponent(_nsButton0, "Lucida Grande", 13, Font.PLAIN);
        }

        if (_replacedObjects.objectForKey("_nsCustomView0") == null) {
            if (!(_nsCustomView0.getLayout() instanceof EOViewLayout)) { _nsCustomView0.setLayout(new EOViewLayout()); }
            _nsButton0.setSize(273, 17);
            _nsButton0.setLocation(140, 31);
            ((EOViewLayout)_nsCustomView0.getLayout()).setAutosizingMask(_nsButton0, EOViewLayout.MaxYMargin);
            _nsCustomView0.add(_nsButton0);
            _nsTextField1.setSize(140, 17);
            _nsTextField1.setLocation(-2, 2);
            ((EOViewLayout)_nsCustomView0.getLayout()).setAutosizingMask(_nsTextField1, EOViewLayout.MaxYMargin);
            _nsCustomView0.add(_nsTextField1);
            _nsTextField2.setSize(200, 22);
            _nsTextField2.setLocation(143, 0);
            ((EOViewLayout)_nsCustomView0.getLayout()).setAutosizingMask(_nsTextField2, EOViewLayout.MaxYMargin);
            _nsCustomView0.add(_nsTextField2);
            _nsTextField3.setSize(51, 22);
            _nsTextField3.setLocation(387, 0);
            ((EOViewLayout)_nsCustomView0.getLayout()).setAutosizingMask(_nsTextField3, EOViewLayout.MaxYMargin);
            _nsCustomView0.add(_nsTextField3);
            _nsTextField4.setSize(34, 17);
            _nsTextField4.setLocation(348, 3);
            ((EOViewLayout)_nsCustomView0.getLayout()).setAutosizingMask(_nsTextField4, EOViewLayout.MaxYMargin);
            _nsCustomView0.add(_nsTextField4);
            _nsTextField5.setSize(140, 17);
            _nsTextField5.setLocation(-2, 30);
            ((EOViewLayout)_nsCustomView0.getLayout()).setAutosizingMask(_nsTextField5, EOViewLayout.MaxYMargin);
            _nsCustomView0.add(_nsTextField5);
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

        _setFontForComponent(_nsTextField1, "Lucida Grande", 13, Font.PLAIN);
        _nsTextField1.setEditable(false);
        _nsTextField1.setOpaque(false);
        _nsTextField1.setText("Serwer logowania:");
        _nsTextField1.setHorizontalAlignment(javax.swing.JTextField.RIGHT);
        _nsTextField1.setSelectable(false);
        _nsTextField1.setEnabled(true);
        _nsTextField1.setBorder(null);
        _setFontForComponent(_nsTextField0, "Lucida Grande", 13, Font.PLAIN);
        _nsTextField0.setEditable(false);
        _nsTextField0.setOpaque(false);
        _nsTextField0.setText("Profil:");
        _nsTextField0.setHorizontalAlignment(javax.swing.JTextField.RIGHT);
        _nsTextField0.setSelectable(false);
        _nsTextField0.setEnabled(true);
        _nsTextField0.setBorder(null);
    }
}
