var keywords = new Array("%userIconPath%", "%message%", "%time%", "%sender%");
var hfkeywords = new Array("%chatName%");
var incomingContentHTML = "";
var outgoingContentHTML = "";
var eventHTML = "";

function fillHeaderFooterKeywords(input)
{
	var keyword;
	for(var i = 0; i < hfkeywords.length; i++)
	{
		keyword = hfkeywords[i];
		input = input.replace(new RegExp(keyword, "g"), getHeaderFooterKeywordValue(keyword, message));
	}
	return input;
}

function fillKeywords(input, message)
{
	var keyword;
	client.debugLog("Filling keywords for message");
	for(var i = 0; i < keywords.length; i++)
	{
		keyword = keywords[i];
		input = input.replace(new RegExp(keyword, "g"), getKeywordValue(keyword, message));
	}
	return input;
}

function getHeaderFooterKeywordValue(word)
{
	var chat = client.chat();
	client.debugLog("Getting keyword value for header keyword " + word);
	switch(word)
	{
		case "%chatName%":
			return chat.name();
	}
	client.debugLog("Found no switch case for header keyword " + word);
	return "";
}

function getKeywordValue(word, message)
{
	client.debugLog("Getting keyword value for message keyword " + word);
	var sender = message.sender();
	var value = "";
	switch(word)
	{
		case "%userIconPath%":
			client.debugLog("About to get icon path for " + sender);
			value = sender.iconPath();
			break;
		case "%message%":
		client.debugLog("Reached %message% case");
			value = message.HTMLContent();
			break;
		case "%time%":
			value = message.localizedTimeStamp();
			break;
		case "%sender%":
			value = sender.displayName();
			break;
	}
	client.debugLog("Found " + value + " for " + word);
	
	return value;
}

function open()
{
	client.debugLog("Opening Chat");
	document.body.setAttribute("style", client.backgroundStyle());
	
	client.debugLog("At main stylesheet");
	
	var mainStyleSheet = document.createElement("link");
	mainStyleSheet.type = "text/css";
	mainStyleSheet.id = "mainStyles";
	mainStyleSheet.rel = "stylesheet";
	mainStyleSheet.href = client.getResourceURL("main.css");
	document.getElementsByTagName("head")[0].appendChild(mainStyleSheet);
	
	client.debugLog("At variant stylesheet");
	
	var variantStyleSheet = document.createElement("link");
	variantStyleSheet.type = "text/css";
	variantStyleSheet.rel = "stylesheet";
	variantStyleSheet.id = "variantStyles";
	variantStyleSheet.href = client.getResourceURL("Variants/Alt Blue - Grey.css");
	document.getElementsByTagName("head")[0].appendChild(variantStyleSheet);
	
	//document.styleSheets[0].insertRule("*{ word-wrap:break-word; }", 0);
	//document.styleSheets[0].insertRule("img.scaledToFitImage { height:auto; width:100%; }", 0);
	
	incomingContentHTML = client.getResourceContents("Incoming/Content.html");
	outgoingContentHTML = client.getResourceContents("Outgoing/Content.html");
	eventHTML = client.getResourceContents("Status.html");
	
	client.debugLog("Loaded content templates");
	
	var range = document.createRange();
	range.selectNode(document.body);
	var headerHTML = client.getResourceContents("Header.html");
	var headerNode = null;
	if(headerHTML.length > 5)
	{
		headerNode = range.createContextualFragment(fillHeaderFooterKeywords(headerHTML));
	}
	else 
	{
		headerNode = document.createElement("span");
	}
	document.body.replaceChild(headerNode, document.getElementById("header"));
	
	var range = document.createRange();
	range.selectNode(document.body);
	var footerHTML = client.getResourceContents("Footer.html");
	var footerNode = null;
	if(footerHTML.length > 5)
	{
		footerNode = range.createContextualFragment(fillHeaderFooterKeywords(footerHTML));
	}
	else 
	{
		footerNode = document.createElement("span");
	}
	document.body.replaceChild(footerNode, document.getElementById("footer"));
}

Element.prototype.query = function(query) 
{
	return document.evaluate(query, this, null, XPathResult.FIRST_ORDERED_NODE_TYPE, null).singleNodeValue;
}

function updateItem(item, property)
{
	   client.debugLog("Updating item " + item + " at property " + property);
	var node = document.getElementById(item.getID());
	client.debugLog("Switching based on event type, node is " + node + "event type is " + item.getType());
	switch(item.getType() + "")
	{
		case "event":
			switch(property)
			{
				case "state":
					node.query('.//div[@class="progressbar"]').style.width = item.getState() + "%";
					break;
			}
			break;
	}
}

function appendMessages()
{
	shouldScroll = nearBottom();
	var message = null;
	var messageHTML = null;
	for(var i = 0; i < arguments.length; i++) {
		message = arguments[i];
		client.debugLog("Got to getType");
		var type = message.getType();
		client.debugLog("Type is " + type);
		if(type == "event") {
			messageHTML = new String(eventHTML);
			messageHTML = messageHTML.replace(new RegExp("%message%", "g"), "<div class=\"progressbar\" style=\"background-color:blue; width:10%;\">progressbar<div>");
		} else if(type == "message") {
			if(message.direction == "outgoing")
				messageHTML = new String(outgoingContentHTML);
			else
				messageHTML = new String(incomingContentHTML);
		}
		messageHTML = fillKeywords(messageHTML, message);
		insert = document.getElementById("insert");
		range = document.createRange();
		//Remove any existing insertion point
		if(insert) insert.parentNode.removeChild(insert);
		
		//Append the new message to the bottom of our chat block
		chat = document.getElementById("Chat");
		var container = document.createElement("div");
		client.debugLog("About to get id");
		var id = message.getID();
		client.debugLog("message id is " + id);
		chat.appendChild(container);
		range.selectNode(container);
		documentFragment = range.createContextualFragment(messageHTML);
		container.id = id;
		container.appendChild(documentFragment);
	}
	alignChat(shouldScroll);
}

//Auto-scroll to bottom.  Use nearBottom to determine if a scrollToBottom is desired.
function nearBottom() {
	return document.body.scrollTop >= document.body.offsetHeight - (window.innerHeight * 1.2);
}

function scrollToBottom() {
	document.body.scrollTop = document.body.offsetHeight;
}

//Dynamically exchange the active stylesheet
function setStylesheet( id, url ) {
	code = "<style id=\"" + id + "\" type=\"text/css\" media=\"screen,print\">";
	if( url.length ) code += "@import url( \"" + url + "\" );";
	code += "</style>";
	range = document.createRange();
	head = document.getElementsByTagName( "head" ).item(0);
	range.selectNode( head );
	documentFragment = range.createContextualFragment( code );
	head.removeChild( document.getElementById( id ) );
	head.appendChild( documentFragment );
}

//Swap an image with its alt-tag text on click, or expand/unexpand an attached image
document.onclick = imageCheck;
function imageCheck() {		
	node = event.target;
	if(node.tagName.toLowerCase() == 'img' && !client.zoomImage(node) && node.alt) {
		a = document.createElement('a');
		a.setAttribute('onclick', 'imageSwap(this)');
		a.src = node.src;
		a.className = node.className;
		text = document.createTextNode(node.alt);
		a.appendChild(text);
		node.parentNode.replaceChild(a, node);
	}
}

function imageSwap(node) {
	shouldScroll = nearBottom();
	
	//Swap the image/text
	img = document.createElement('img');
	img.setAttribute('src', node.src);
	img.setAttribute('alt', node.firstChild.nodeValue);
	img.className = node.className;
	node.parentNode.replaceChild(img, node);
	
	alignChat(shouldScroll);
}

function zoomImage(img)
{
	shouldScroll = nearBottom();
	
	if(img.hasClass("fullSizeImage"))
	{
		img.addClass("scaledToFitImage");
		img.removeClass("fullSizeImage");
	}
	else
	{
		img.addClass("fullSizeImage");
		img.removeClass("scaledToFitImage");
	}
	
	alignChat(shouldScroll);
}

Element.prototype.removeClass = function(className)
{
	if(this.hasClass(className))
		this.className = this.className.replace(className, "");
}

Element.prototype.addClass = function(className)
{
	if (!this.hasClass(className)) {
		//make sure to space-separate multiple classes
		this.className += (this.className.length ? " " + className : className);
	}
}

Element.prototype.hasClass = function(className) {
	return this.className.toLowerCase().indexOf(className.toLowerCase()) > -1;
};

//Align our chat to the bottom of the window.  If true is passed, view will also be scrolled down
function alignChat(shouldScroll) {
	var windowHeight = window.innerHeight;
	
	if (windowHeight > 0) {
		var contentElement = document.getElementById('Chat');
		var contentHeight = contentElement.offsetHeight;
		if (windowHeight - contentHeight > 0) {
			contentElement.style.position = 'relative';
			contentElement.style.top = (windowHeight - contentHeight) + 'px';
		} else {
			contentElement.style.position = 'static';
		}
	}
	
	if (shouldScroll) scrollToBottom();
}

function windowDidResize(){
	alignChat(true/*nearBottom()*/); //nearBottom buggy with inactive tabs
}

window.onresize = windowDidResize;