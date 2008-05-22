//
//  SimpleURLTest.m
//  AIHyperlinks.framework
//

#import "SimpleURLTest.h"

@implementation SimpleURLTest

- (void)setUp {
	scanner = [[AHHyperlinkScanner alloc] initWithStrictChecking:NO];
}

- (void)tearDown {
	[scanner release];
}

- (void)testURLOnly {
	testHyperlink(@"example.com");
	testHyperlink(@"www.example.com");
	testHyperlink(@"ftp.example.com");
	testHyperlink(@"example.com/");
	testHyperlink(@"www.example.com/");
	testHyperlink(@"ftp.example.com/");
	testHyperlink(@"example.com/foo");
	testHyperlink(@"www.example.com/foo");
	testHyperlink(@"example.com/foo/bar.php");
	testHyperlink(@"www.example.com/foo/bar.php");
}

- (void)testURI {
	testHyperlink(@"http://example.com/");
	testHyperlink(@"http://www.example.com/");
	testHyperlink(@"http://ftp.example.com/");
	testHyperlink(@"ftp://example.com/");
	testHyperlink(@"ftp://www.example.com/");
	testHyperlink(@"ftp://ftp.example.com/");
	testHyperlink(@"http://example.com");
	testHyperlink(@"http://www.example.com");
	testHyperlink(@"http://ftp.example.com");
	testHyperlink(@"ftp://example.com");
	testHyperlink(@"ftp://www.example.com");
	testHyperlink(@"ftp://ftp.example.com");
}

- (void)testURIWithPaths {
	testHyperlink(@"http://example.com/foo");
	testHyperlink(@"http://example.com/foo/bar.php");
	testHyperlink(@"http://www.example.com/foo/");
	testHyperlink(@"http://www.example.com/foo/bar.php");
	testHyperlink(@"http://ftp.example.com/foo");
	testHyperlink(@"http://ftp.example.com/foo/bar.php");
	testHyperlink(@"ftp://example.com/foo");
	testHyperlink(@"ftp://example.com/foo/bar.php");
	testHyperlink(@"ftp://www.example.com/foo/");
	testHyperlink(@"ftp://www.example.com/foo/bar.php");
	testHyperlink(@"ftp://ftp.example.com/foo");
	testHyperlink(@"ftp://ftp.example.com/foo/bar.php");
}

- (void)testURIWithUserAndPass {
	testHyperlink(@"http://user@example.com");
	testHyperlink(@"http://user:pass@example.com");
	testHyperlink(@"ftp://user@example.com");
	testHyperlink(@"ftp://user:pass@example.com");
}

- (void)testIPAddressURI {
	testHyperlink(@"http://1.1.1.1");
	testHyperlink(@"http://1.1.1.12");
	testHyperlink(@"http://1.1.1.123");
	testHyperlink(@"http://1.1.12.1");
	testHyperlink(@"http://1.1.12.12");
	testHyperlink(@"http://1.1.12.123");
	testHyperlink(@"http://1.1.123.1");
	testHyperlink(@"http://1.1.123.12");
	testHyperlink(@"http://1.1.123.123");
	testHyperlink(@"http://1.12.1.1");
	testHyperlink(@"http://1.12.1.12");
	testHyperlink(@"http://1.12.1.123");
	testHyperlink(@"http://1.12.12.1");
	testHyperlink(@"http://1.12.12.12");
	testHyperlink(@"http://1.12.12.123");
	testHyperlink(@"http://1.12.123.1");
	testHyperlink(@"http://1.12.123.12");
	testHyperlink(@"http://1.12.123.123");
	testHyperlink(@"http://1.123.1.1");
	testHyperlink(@"http://1.123.1.12");
	testHyperlink(@"http://1.123.1.123");
	testHyperlink(@"http://1.123.12.1");
	testHyperlink(@"http://1.123.12.12");
	testHyperlink(@"http://1.123.12.123");
	testHyperlink(@"http://1.123.123.1");
	testHyperlink(@"http://1.123.123.12");
	testHyperlink(@"http://1.123.123.123");
	testHyperlink(@"http://12.1.1.1");
	testHyperlink(@"http://12.1.1.12");
	testHyperlink(@"http://12.1.1.123");
	testHyperlink(@"http://12.1.12.1");
	testHyperlink(@"http://12.1.12.12");
	testHyperlink(@"http://12.1.12.123");
	testHyperlink(@"http://12.1.123.1");
	testHyperlink(@"http://12.1.123.12");
	testHyperlink(@"http://12.1.123.123");
	testHyperlink(@"http://12.12.1.1");
	testHyperlink(@"http://12.12.1.12");
	testHyperlink(@"http://12.12.1.123");
	testHyperlink(@"http://12.12.12.1");
	testHyperlink(@"http://12.12.12.12");
	testHyperlink(@"http://12.12.12.123");
	testHyperlink(@"http://12.12.123.1");
	testHyperlink(@"http://12.12.123.12");
	testHyperlink(@"http://12.12.123.123");
	testHyperlink(@"http://12.123.1.1");
	testHyperlink(@"http://12.123.1.12");
	testHyperlink(@"http://12.123.1.123");
	testHyperlink(@"http://12.123.12.1");
	testHyperlink(@"http://12.123.12.12");
	testHyperlink(@"http://12.123.12.123");
	testHyperlink(@"http://12.123.123.1");
	testHyperlink(@"http://12.123.123.12");
	testHyperlink(@"http://12.123.123.123");
	testHyperlink(@"http://123.1.1.1");
	testHyperlink(@"http://123.1.1.12");
	testHyperlink(@"http://123.1.1.123");
	testHyperlink(@"http://123.1.12.1");
	testHyperlink(@"http://123.1.12.12");
	testHyperlink(@"http://123.1.12.123");
	testHyperlink(@"http://123.1.123.1");
	testHyperlink(@"http://123.1.123.12");
	testHyperlink(@"http://123.1.123.123");
	testHyperlink(@"http://123.12.1.1");
	testHyperlink(@"http://123.12.1.12");
	testHyperlink(@"http://123.12.1.123");
	testHyperlink(@"http://123.12.12.1");
	testHyperlink(@"http://123.12.12.12");
	testHyperlink(@"http://123.12.12.123");
	testHyperlink(@"http://123.12.123.1");
	testHyperlink(@"http://123.12.123.12");
	testHyperlink(@"http://123.12.123.123");
	testHyperlink(@"http://123.123.1.1");
	testHyperlink(@"http://123.123.1.12");
	testHyperlink(@"http://123.123.1.123");
	testHyperlink(@"http://123.123.12.1");
	testHyperlink(@"http://123.123.12.12");
	testHyperlink(@"http://123.123.12.123");
	testHyperlink(@"http://123.123.123.1");
	testHyperlink(@"http://123.123.123.12");
	testHyperlink(@"http://123.123.123.123");
	testHyperlink(@"ftp://1.1.1.1");
	testHyperlink(@"ftp://1.1.1.12");
	testHyperlink(@"ftp://1.1.1.123");
	testHyperlink(@"ftp://1.1.12.1");
	testHyperlink(@"ftp://1.1.12.12");
	testHyperlink(@"ftp://1.1.12.123");
	testHyperlink(@"ftp://1.1.123.1");
	testHyperlink(@"ftp://1.1.123.12");
	testHyperlink(@"ftp://1.1.123.123");
	testHyperlink(@"ftp://1.12.1.1");
	testHyperlink(@"ftp://1.12.1.12");
	testHyperlink(@"ftp://1.12.1.123");
	testHyperlink(@"ftp://1.12.12.1");
	testHyperlink(@"ftp://1.12.12.12");
	testHyperlink(@"ftp://1.12.12.123");
	testHyperlink(@"ftp://1.12.123.1");
	testHyperlink(@"ftp://1.12.123.12");
	testHyperlink(@"ftp://1.12.123.123");
	testHyperlink(@"ftp://1.123.1.1");
	testHyperlink(@"ftp://1.123.1.12");
	testHyperlink(@"ftp://1.123.1.123");
	testHyperlink(@"ftp://1.123.12.1");
	testHyperlink(@"ftp://1.123.12.12");
	testHyperlink(@"ftp://1.123.12.123");
	testHyperlink(@"ftp://1.123.123.1");
	testHyperlink(@"ftp://1.123.123.12");
	testHyperlink(@"ftp://1.123.123.123");
	testHyperlink(@"ftp://12.1.1.1");
	testHyperlink(@"ftp://12.1.1.12");
	testHyperlink(@"ftp://12.1.1.123");
	testHyperlink(@"ftp://12.1.12.1");
	testHyperlink(@"ftp://12.1.12.12");
	testHyperlink(@"ftp://12.1.12.123");
	testHyperlink(@"ftp://12.1.123.1");
	testHyperlink(@"ftp://12.1.123.12");
	testHyperlink(@"ftp://12.1.123.123");
	testHyperlink(@"ftp://12.12.1.1");
	testHyperlink(@"ftp://12.12.1.12");
	testHyperlink(@"ftp://12.12.1.123");
	testHyperlink(@"ftp://12.12.12.1");
	testHyperlink(@"ftp://12.12.12.12");
	testHyperlink(@"ftp://12.12.12.123");
	testHyperlink(@"ftp://12.12.123.1");
	testHyperlink(@"ftp://12.12.123.12");
	testHyperlink(@"ftp://12.12.123.123");
	testHyperlink(@"ftp://12.123.1.1");
	testHyperlink(@"ftp://12.123.1.12");
	testHyperlink(@"ftp://12.123.1.123");
	testHyperlink(@"ftp://12.123.12.1");
	testHyperlink(@"ftp://12.123.12.12");
	testHyperlink(@"ftp://12.123.12.123");
	testHyperlink(@"ftp://12.123.123.1");
	testHyperlink(@"ftp://12.123.123.12");
	testHyperlink(@"ftp://12.123.123.123");
	testHyperlink(@"ftp://123.1.1.1");
	testHyperlink(@"ftp://123.1.1.12");
	testHyperlink(@"ftp://123.1.1.123");
	testHyperlink(@"ftp://123.1.12.1");
	testHyperlink(@"ftp://123.1.12.12");
	testHyperlink(@"ftp://123.1.12.123");
	testHyperlink(@"ftp://123.1.123.1");
	testHyperlink(@"ftp://123.1.123.12");
	testHyperlink(@"ftp://123.1.123.123");
	testHyperlink(@"ftp://123.12.1.1");
	testHyperlink(@"ftp://123.12.1.12");
	testHyperlink(@"ftp://123.12.1.123");
	testHyperlink(@"ftp://123.12.12.1");
	testHyperlink(@"ftp://123.12.12.12");
	testHyperlink(@"ftp://123.12.12.123");
	testHyperlink(@"ftp://123.12.123.1");
	testHyperlink(@"ftp://123.12.123.12");
	testHyperlink(@"ftp://123.12.123.123");
	testHyperlink(@"ftp://123.123.1.1");
	testHyperlink(@"ftp://123.123.1.12");
	testHyperlink(@"ftp://123.123.1.123");
	testHyperlink(@"ftp://123.123.12.1");
	testHyperlink(@"ftp://123.123.12.12");
	testHyperlink(@"ftp://123.123.12.123");
	testHyperlink(@"ftp://123.123.123.1");
	testHyperlink(@"ftp://123.123.123.12");
	testHyperlink(@"ftp://123.123.123.123");
	
	testHyperlink(@"http://1.1.1.1/");
	testHyperlink(@"http://1.1.1.12/");
	testHyperlink(@"http://1.1.1.123/");
	testHyperlink(@"http://1.1.12.1/");
	testHyperlink(@"http://1.1.12.12/");
	testHyperlink(@"http://1.1.12.123/");
	testHyperlink(@"http://1.1.123.1/");
	testHyperlink(@"http://1.1.123.12/");
	testHyperlink(@"http://1.1.123.123/");
	testHyperlink(@"http://1.12.1.1/");
	testHyperlink(@"http://1.12.1.12/");
	testHyperlink(@"http://1.12.1.123/");
	testHyperlink(@"http://1.12.12.1/");
	testHyperlink(@"http://1.12.12.12/");
	testHyperlink(@"http://1.12.12.123/");
	testHyperlink(@"http://1.12.123.1/");
	testHyperlink(@"http://1.12.123.12/");
	testHyperlink(@"http://1.12.123.123/");
	testHyperlink(@"http://1.123.1.1/");
	testHyperlink(@"http://1.123.1.12/");
	testHyperlink(@"http://1.123.1.123/");
	testHyperlink(@"http://1.123.12.1/");
	testHyperlink(@"http://1.123.12.12/");
	testHyperlink(@"http://1.123.12.123/");
	testHyperlink(@"http://1.123.123.1/");
	testHyperlink(@"http://1.123.123.12/");
	testHyperlink(@"http://1.123.123.123/");
	testHyperlink(@"http://12.1.1.1/");
	testHyperlink(@"http://12.1.1.12/");
	testHyperlink(@"http://12.1.1.123/");
	testHyperlink(@"http://12.1.12.1/");
	testHyperlink(@"http://12.1.12.12/");
	testHyperlink(@"http://12.1.12.123/");
	testHyperlink(@"http://12.1.123.1/");
	testHyperlink(@"http://12.1.123.12/");
	testHyperlink(@"http://12.1.123.123/");
	testHyperlink(@"http://12.12.1.1/");
	testHyperlink(@"http://12.12.1.12/");
	testHyperlink(@"http://12.12.1.123/");
	testHyperlink(@"http://12.12.12.1/");
	testHyperlink(@"http://12.12.12.12/");
	testHyperlink(@"http://12.12.12.123/");
	testHyperlink(@"http://12.12.123.1/");
	testHyperlink(@"http://12.12.123.12/");
	testHyperlink(@"http://12.12.123.123/");
	testHyperlink(@"http://12.123.1.1/");
	testHyperlink(@"http://12.123.1.12/");
	testHyperlink(@"http://12.123.1.123/");
	testHyperlink(@"http://12.123.12.1/");
	testHyperlink(@"http://12.123.12.12/");
	testHyperlink(@"http://12.123.12.123/");
	testHyperlink(@"http://12.123.123.1/");
	testHyperlink(@"http://12.123.123.12/");
	testHyperlink(@"http://12.123.123.123/");
	testHyperlink(@"http://123.1.1.1/");
	testHyperlink(@"http://123.1.1.12/");
	testHyperlink(@"http://123.1.1.123/");
	testHyperlink(@"http://123.1.12.1/");
	testHyperlink(@"http://123.1.12.12/");
	testHyperlink(@"http://123.1.12.123/");
	testHyperlink(@"http://123.1.123.1/");
	testHyperlink(@"http://123.1.123.12/");
	testHyperlink(@"http://123.1.123.123/");
	testHyperlink(@"http://123.12.1.1/");
	testHyperlink(@"http://123.12.1.12/");
	testHyperlink(@"http://123.12.1.123/");
	testHyperlink(@"http://123.12.12.1/");
	testHyperlink(@"http://123.12.12.12/");
	testHyperlink(@"http://123.12.12.123/");
	testHyperlink(@"http://123.12.123.1/");
	testHyperlink(@"http://123.12.123.12/");
	testHyperlink(@"http://123.12.123.123/");
	testHyperlink(@"http://123.123.1.1/");
	testHyperlink(@"http://123.123.1.12/");
	testHyperlink(@"http://123.123.1.123/");
	testHyperlink(@"http://123.123.12.1/");
	testHyperlink(@"http://123.123.12.12/");
	testHyperlink(@"http://123.123.12.123/");
	testHyperlink(@"http://123.123.123.1/");
	testHyperlink(@"http://123.123.123.12/");
	testHyperlink(@"http://123.123.123.123/");
	testHyperlink(@"ftp://1.1.1.1/");
	testHyperlink(@"ftp://1.1.1.12/");
	testHyperlink(@"ftp://1.1.1.123/");
	testHyperlink(@"ftp://1.1.12.1/");
	testHyperlink(@"ftp://1.1.12.12/");
	testHyperlink(@"ftp://1.1.12.123/");
	testHyperlink(@"ftp://1.1.123.1/");
	testHyperlink(@"ftp://1.1.123.12/");
	testHyperlink(@"ftp://1.1.123.123/");
	testHyperlink(@"ftp://1.12.1.1/");
	testHyperlink(@"ftp://1.12.1.12/");
	testHyperlink(@"ftp://1.12.1.123/");
	testHyperlink(@"ftp://1.12.12.1/");
	testHyperlink(@"ftp://1.12.12.12/");
	testHyperlink(@"ftp://1.12.12.123/");
	testHyperlink(@"ftp://1.12.123.1/");
	testHyperlink(@"ftp://1.12.123.12/");
	testHyperlink(@"ftp://1.12.123.123/");
	testHyperlink(@"ftp://1.123.1.1/");
	testHyperlink(@"ftp://1.123.1.12/");
	testHyperlink(@"ftp://1.123.1.123/");
	testHyperlink(@"ftp://1.123.12.1/");
	testHyperlink(@"ftp://1.123.12.12/");
	testHyperlink(@"ftp://1.123.12.123/");
	testHyperlink(@"ftp://1.123.123.1/");
	testHyperlink(@"ftp://1.123.123.12/");
	testHyperlink(@"ftp://1.123.123.123/");
	testHyperlink(@"ftp://12.1.1.1/");
	testHyperlink(@"ftp://12.1.1.12/");
	testHyperlink(@"ftp://12.1.1.123/");
	testHyperlink(@"ftp://12.1.12.1/");
	testHyperlink(@"ftp://12.1.12.12/");
	testHyperlink(@"ftp://12.1.12.123/");
	testHyperlink(@"ftp://12.1.123.1/");
	testHyperlink(@"ftp://12.1.123.12/");
	testHyperlink(@"ftp://12.1.123.123/");
	testHyperlink(@"ftp://12.12.1.1/");
	testHyperlink(@"ftp://12.12.1.12/");
	testHyperlink(@"ftp://12.12.1.123/");
	testHyperlink(@"ftp://12.12.12.1/");
	testHyperlink(@"ftp://12.12.12.12/");
	testHyperlink(@"ftp://12.12.12.123/");
	testHyperlink(@"ftp://12.12.123.1/");
	testHyperlink(@"ftp://12.12.123.12/");
	testHyperlink(@"ftp://12.12.123.123/");
	testHyperlink(@"ftp://12.123.1.1/");
	testHyperlink(@"ftp://12.123.1.12/");
	testHyperlink(@"ftp://12.123.1.123/");
	testHyperlink(@"ftp://12.123.12.1/");
	testHyperlink(@"ftp://12.123.12.12/");
	testHyperlink(@"ftp://12.123.12.123/");
	testHyperlink(@"ftp://12.123.123.1/");
	testHyperlink(@"ftp://12.123.123.12/");
	testHyperlink(@"ftp://12.123.123.123/");
	testHyperlink(@"ftp://123.1.1.1/");
	testHyperlink(@"ftp://123.1.1.12/");
	testHyperlink(@"ftp://123.1.1.123/");
	testHyperlink(@"ftp://123.1.12.1/");
	testHyperlink(@"ftp://123.1.12.12/");
	testHyperlink(@"ftp://123.1.12.123/");
	testHyperlink(@"ftp://123.1.123.1/");
	testHyperlink(@"ftp://123.1.123.12/");
	testHyperlink(@"ftp://123.1.123.123/");
	testHyperlink(@"ftp://123.12.1.1/");
	testHyperlink(@"ftp://123.12.1.12/");
	testHyperlink(@"ftp://123.12.1.123/");
	testHyperlink(@"ftp://123.12.12.1/");
	testHyperlink(@"ftp://123.12.12.12/");
	testHyperlink(@"ftp://123.12.12.123/");
	testHyperlink(@"ftp://123.12.123.1/");
	testHyperlink(@"ftp://123.12.123.12/");
	testHyperlink(@"ftp://123.12.123.123/");
	testHyperlink(@"ftp://123.123.1.1/");
	testHyperlink(@"ftp://123.123.1.12/");
	testHyperlink(@"ftp://123.123.1.123/");
	testHyperlink(@"ftp://123.123.12.1/");
	testHyperlink(@"ftp://123.123.12.12/");
	testHyperlink(@"ftp://123.123.12.123/");
	testHyperlink(@"ftp://123.123.123.1/");
	testHyperlink(@"ftp://123.123.123.12/");
	testHyperlink(@"ftp://123.123.123.123/");
}

- (void)testIPv6URI {
	testHyperlink(@"http://[FEDC:BA98:7654:3210:FEDC:BA98:7654:3210]");
	testHyperlink(@"http://[1080:0:0:0:8:800:200C:417A]");
	testHyperlink(@"http://[3ffe:2a00:100:7031::1]");
	testHyperlink(@"http://[1080::8:800:200C:417A]");
	testHyperlink(@"http://[::192.9.5.5]");
	testHyperlink(@"http://[::FFFF:129.144.52.38]");
	testHyperlink(@"http://[2010:836B:4179::836B:4179]");
	testHyperlink(@"http://[::1]");

	testHyperlink(@"http://[FEDC:BA98:7654:3210:FEDC:BA98:7654:3210]/");
	testHyperlink(@"http://[1080:0:0:0:8:800:200C:417A]/");
	testHyperlink(@"http://[3ffe:2a00:100:7031::1]/");
	testHyperlink(@"http://[1080::8:800:200C:417A]/");
	testHyperlink(@"http://[::192.9.5.5]/");
	testHyperlink(@"http://[::FFFF:129.144.52.38]/");
	testHyperlink(@"http://[2010:836B:4179::836B:4179]/");
	testHyperlink(@"http://[::1]/");
}

- (void)testUniqueURI {
	testHyperlink(@"sip:foo@example.com");
	testHyperlink(@"xmpp:foo@example.com");
	testHyperlink(@"xmpp:foo@example.com/adium");
	testHyperlink(@"aim:goim?screenname=adiumx");
	testHyperlink(@"aim:goim?screenname=adiumx&message=Hey!+Does+this+work?");
	testHyperlink(@"ymsgr:sendim?adiumy");
	testHyperlink(@"yahoo:sendim?adiumy");
	testHyperlink(@"ymsgr://im?to=adiumy");
	testHyperlink(@"yahoo://im?to=adiumy");
	testHyperlink(@"rdar://1234");
	testHyperlink(@"rdar://problem/1234");
	testHyperlink(@"rdar://problems/1234&5678&9012");
	testHyperlink(@"radr://1234");
	testHyperlink(@"radr://problem/1234");
	testHyperlink(@"radr://problems/1234&5678&9012");
	testHyperlink(@"radar://1234");
	testHyperlink(@"radar://problem/1234");
	testHyperlink(@"radar://problems/1234&5678&9012");
	testHyperlink(@"x-radar://1234");
	testHyperlink(@"x-radar://problem/1234");
	testHyperlink(@"x-radar://problems/1234&5678&9012");
	testHyperlink(@"spotify:track:abcd1234");
	testHyperlink(@"spotify:album:abcd1234");
	testHyperlink(@"spotify:artist:abcd1234");
	testHyperlink(@"spotify:search:abcd1234");
	testHyperlink(@"spotify:playlist:abcd1234");
	testHyperlink(@"spotify:user:abcd1234");
	testHyperlink(@"spotify:radio:abcd1234");
}

- (void)testEmailAddress {
	testHyperlink(@"foo@example.com");
	testHyperlink(@"foo.bar@example.com");
}

- (void)testUserCases {
	testHyperlink(@"http://example.com/foo_(bar)");
	testHyperlink(@"http://example.not.a.tld/");
	testHyperlink(@"http://example.not.a.tld:8080/");
	testHyperlink(@"http://example.not.a.tld/stuff");
	testHyperlink(@"http://example.not.a.tld:8080/stuff");
}
@end
