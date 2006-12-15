function appendMessage(messages)
{
	shouldScroll = nearBottom();
	for(var message in messages) {
		var messageType = message.getMessageType();
		insert = document.getElementById("insert");
		range = document.createRange();
		if(messageType == "normal") {
			//Remove any existing insertion point
			if(insert) insert.parentNode.removeChild(insert);
			
			//Append the new message to the bottom of our chat block
			chat = document.getElementById("Chat");
			range.selectNode(chat);
			documentFragment = range.createContextualFragment(message.getMessageHTML());
			chat.appendChild(documentFragment);
		} else if(messageType == "next") {
			//make the new node
			range.selectNode(insert.parentNode);
			newNode = range.createContextualFragment(message.getMessageHTML());

			//swap
			insert.parentNode.replaceChild(newNode,insert);
		}
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

Element.prototype.removeClass = function(class)
{
	if(this.hasClass(class))
		this.className = this.className.replace(class, "");
}

Element.prototype.addClass = function(class)
{
	if (!this.hasClass(class)) {
		//make sure to space-separate multiple classes
		this.className += (this.className.length ? " " + class : class);
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