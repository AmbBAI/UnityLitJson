# Rules to build HTML versions of the software documentation
#
# Variables used:
#
#   MANUAL
#     Path to the main .xml file of the manual
#   MANUAL_SRC_DIR
#     Path to the directory where all the manual source files are located.
#     This path is used to generate the manual dependencies when 'make dep'
#     is run.


CSS_DIR       = $(LITDOC_DIR)/css
CSS_MAIN      = ld-default.css
CSS_HIGHLIGHT = ld-highlight.css

SOURCE_HL = source-highlight


include $(srcdir)/manual.dep

EXTRA_DIST = $(MANUAL_DEPS)

LITDOC_DIR = $(srcdir)/litdoc

DOCBOOK_XSD = $(LITDOC_DIR)/docbook/xsd/docbook.xsd

HTML_MANY_DIR   = $(srcdir)/html
HTML_SINGLE_DIR = $(srcdir)/html-single

MANUAL_HTML_SINGLE = $(HTML_SINGLE_DIR)/manual.html

MANUAL_PHASE1 = $(LITDOC_DIR)/genfiles/manual-p1.xml
LITDOC_XSL_PHASE1 = $(LITDOC_DIR)/xsl/ld-phase1.xsl

MANUAL_XSL_SINGLE  = $(LITDOC_DIR)/xsl/ld-docbook.xsl
MANUAL_XSL_CHUNK   = $(LITDOC_DIR)/xsl/ld-chunk.xsl

XMLLINT_FLAGS = --xinclude --noent --noout



install-data-local:
	if test -d $(srcdir)/html; then                      \
		$(mkinstalldirs) $(DESTDIR)$(htmldir) ;          \
		cp -udpR $(HTML_MANY_DIR) $(DESTDIR)$(htmldir) ; \
		chmod -R u+w $(DESTDIR)$(htmldir) ;              \
	fi

uninstall-local:
	rm -rf $(DESTDIR)$(htmldir)

dist-hook:
	if test -d $(LITDOC_DIR) ; then              \
		cd $(srcdir) && $(MAKE) html ;           \
		cp -udpR $(HTML_MANY_DIR) $(distdir) ;   \
		cp -udpR $(HTML_SINGLE_DIR) $(distdir) ; \
	fi


dep:
	echo "MANUAL_DEPS = \\" > $(srcdir)/manual.dep.tmp
	for f in `find $(MANUAL_SRC_DIR) -type f -printf '%P\n'`; do          \
		echo "	\$$(MANUAL_SRC_DIR)/$$f \\" >> $(srcdir)/manual.dep.tmp ; \
	done
	sed -e '$$s/\\//' manual.dep.tmp > manual.dep
	rm -f manual.dep.tmp

$(MANUAL_PHASE1): $(LITDOC_XSL_PHASE1) $(MANUAL_DEPS)
	rm -f $(LITDOC_DIR)/genfiles/highlight/source/*
	rm -f $(LITDOC_DIR)/genfiles/highlight/result/*
	xsltproc --xinclude -o $@ $(LITDOC_XSL_PHASE1) $(MANUAL)
	for src in $(LITDOC_DIR)/genfiles/highlight/source/*; do      \
		result=`echo $$src | sed -e 's~source/~result/~'` ;       \
		lang=`echo $$src | sed -e 's/.*\.//'` ;                   \
		echo "<highlighted>" > $$result ;                         \
		$(SOURCE_HL) -i $$src -s $$lang -f xhtml-css >> $$result; \
		echo "</highlighted>" >> $$result ;                       \
	done

html: html-many html-single

html-many: $(MANUAL_PHASE1)
	@echo "Building HTML manual (many files)"
	test -d $(HTML_MANY_DIR) || $(MKDIR_P) $(HTML_MANY_DIR)
	xsltproc --xinclude --xincludestyle $(XSLTPROC_FLAGS)     \
		--stringparam base.dir "$(HTML_MANY_DIR)/"            \
		--stringparam html.stylesheet "$(CSS_MAIN)"           \
		--stringparam litdoc.css.highlight "$(CSS_HIGHLIGHT)" \
		$(MANUAL_XSL_CHUNK) $(MANUAL_PHASE1)
	cp -f $(CSS_DIR)/$(CSS_MAIN) $(HTML_MANY_DIR)
	cp -f $(CSS_DIR)/$(CSS_HIGHLIGHT) $(HTML_MANY_DIR)

html-single: $(MANUAL_PHASE1)
	@echo "Building HTML manual (single file)"
	test -d $(HTML_SINGLE_DIR) || $(MKDIR_P) $(HTML_SINGLE_DIR)
	xsltproc --xinclude --xincludestyle $(XSLTPROC_FLAGS)     \
		--stringparam html.stylesheet "$(CSS_MAIN)"           \
		--stringparam litdoc.css.highlight "$(CSS_HIGHLIGHT)" \
		-o $(MANUAL_HTML_SINGLE)                              \
		$(MANUAL_XSL_SINGLE) $(MANUAL_PHASE1)
	cp -f $(CSS_DIR)/$(CSS_MAIN) $(HTML_SINGLE_DIR)
	cp -f $(CSS_DIR)/$(CSS_HIGHLIGHT) $(HTML_SINGLE_DIR)

test: $(MANUAL_PHASE1)
	@echo "Testing XML sources validity"
	xmllint $(XMLLINT_FLAGS) --schema $(DOCBOOK_XSD) $(MANUAL_PHASE1)
	xmllint $(XMLLINT_FLAGS) --schema $(DOCBOOK_XSD) $(MANUAL)


.PHONY: dep html html-many html-single test
