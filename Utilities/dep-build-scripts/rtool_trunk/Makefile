# $rtool: Makefile,v 1.00 2007/05/24 23:25:01 mmw Exp $

DISTFILES = Makefile ReadMe Resources Version.plist rtool rtool.1
TAR = tar
GZIP = gzip
PACKAGE = rtool
SRCVERSION = 1.2.3

dist: ${DISTFILES}
	@mkdir -p $(PACKAGE)-$(SRCVERSION)
	@$(TAR) -cvf $(PACKAGE)-$(SRCVERSION).tar ${DISTFILES}
	cd $(PACKAGE)-$(SRCVERSION) && $(TAR) -xf ../$(PACKAGE)-$(SRCVERSION).tar && cd ..
	@rm $(PACKAGE)-$(SRCVERSION).tar
	@$(TAR) -cvf $(PACKAGE)-$(SRCVERSION).tar $(PACKAGE)-$(SRCVERSION)
	@rm -rf $(PACKAGE)-$(SRCVERSION)
	@$(GZIP) -9 $(PACKAGE)-$(SRCVERSION).tar
	@openssl sha1 $(PACKAGE)-$(SRCVERSION).tar.gz > $(PACKAGE)-$(SRCVERSION).sha1