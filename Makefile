#!/usr/bin/gmake

# Uncomment the following line to specify specific targets (instead
# of everything in the directory with the suffix .lyx or .tex)
PAPERS = dproofs

FIGSBASE = $(basename $(wildcard figures/*.svg)) 

#Uncomment the following line to anonymize PDF metadata
#ANONYMIZE=1

# Comment the following line to build PDF files as well
#NOPDF = 1

# Comment the following line to use dvips
USEPDFLATEX=1

# Comment the following line to prevent reverse indexing
# (also automatically turned off if ANONYMIZE is enabled)
REVERSEINDEX=1

# Uncomment the following line when using the nomencl package 
NOMENCL=1

# To prevent automatic use of pdftk, use "PDFTK=" on the make command line
# or uncomment the following line

#NOPDFTK=1

# To prevent automatic use of inkscape, use "INKSCAPE=" on the make command line
# or uncomment the following line

#NOINKSCAPE=1

# To prevent automatic use of subversion, use "SVN=" on the make command line
# or uncomment the following line

#NOSVN=1

# To prevent automatic use of mercurial, use "HG=" on the make command line
# or uncomment the following line

#NOHG=1

# To prevent automatic use of git, use "GIT=" on the make command line
# or uncomment the following line

#NOGIT=1


# To prevent automatic use of qpdf for linearization use "QPDF=" on the make 
# command line or uncomment the following line:

#NOQPDF=1

SEARCHPATH=$(subst :, ,$(PATH))
findcmd=$(firstword $(wildcard $(foreach cmd,$(cmds),$(addsuffix /$(cmd),$(SEARCHPATH)))))

## Uppercase macro

# A macro for converting a string to uppercase
uppercase_TABLE:=a,A b,B c,C d,D e,E f,F g,G h,H i,I j,J k,K l,L m,M n,N o,O p,P q,Q r,R s,S t,T u,U v,V w,W x,X y,Y z,Z

define uppercase_internal
$(if $1,$$(subst $(firstword $1),$(call uppercase_internal,$(wordlist 2,$(words $1),$1),$2)),$2)
endef

define uppercase
$(eval uppercase_RESULT:=$(call uppercase_internal,$(uppercase_TABLE),$1))$(uppercase_RESULT)
endef
##### End Uppercase macro

ifndef PERL
cmds=perl perl.exe
PERL:=$(findcmd)
ifeq ($(strip $(PERL)),)
PERL:=
endif
endif

ifndef M4
cmds=m4 m4.exe
M4:=$(findcmd)
ifeq ($(strip $(M4)),)
M4:=
endif
endif


ifndef ZIP
cmds=zip zip.exe pkzip
ZIP:=$(findcmd)
ifeq ($(strip $(ZIP)),)
ZIP:=
endif
endif

ifndef NOINKSCAPE
cmds=inkscape inkscape.exe
INKSCAPE:=$(findcmd)
else
INKSCAPE :=
endif

ifndef NOPDFTK
cmds=pdftk pdftk.exe
PDFTK:=$(findcmd)
else
PDFTK :=
endif

ifndef NOQPDF
cmds=qpdf qpdf.exe
QPDF :=$(findcmd)
else
QPDF :=
endif

ifndef NOSVN
cmds=svn svn.exe
SVN:=$(findcmd)
ifeq ($(wildcard .svn),)
SVN := # Didn't find .svn subdirectory
endif
else
SVN :=
endif

ifndef NOHG
cmds=hg hg.exe
HG:=$(findcmd)
ifeq ($(wildcard .hg),)
HG := # Didn't find .hg subdirectory
endif
else
HG :=
endif

ifndef NOGIT
cmds=git git.exe
GIT:=$(findcmd)
ifeq ($(wildcard .git),)
GIT := # Didn't find .git subdirectory
endif
else
GIT :=
endif

ifeq ($(strip $(PDFTK)),)
PDFTK :=
endif
ifeq ($(strip $(PDFOPT)),)
PDFOPT :=
endif
ifeq ($(strip $(QPDF)),)
QPDF :=
endif
ifeq ($(strip $(INKSCAPE)),)
INKSCAPE :=
endif
ifeq ($(strip $(SVN)),)
SVN :=
else
SVNREV := $(shell $(SVN) info -R | $(PERL) -ne '/Rev:\s(\d+)/ && ($$num = $$num < $$1 ? $$1 : $$num); END{print "$$num";}')
endif
ifeq ($(strip $(HG)),)
HG :=
else
HGREV := $(shell $(HG) id)
endif

ifeq ($(strip $(GIT)),)
GIT :=
else
GITREV := $(shell $(GIT) rev-list -1 HEAD)
endif


ifndef USEPDFLATEX
FIGS = $(addsuffix .eps,$(FIGSBASE) )
else
FIGS = $(addsuffix .pdf,$(FIGSBASE) )
endif

ifdef ANONYMIZE
REVERSEINDEX=
endif

ifdef REVERSEINDEX
SRCSPECIALS := $(shell latex -help | grep -q src-specials > /dev/null 2>&1 && echo -n 1)
ifeq ($(SRCSPECIALS),1)
LATEXFLAGS = -src-specials
endif

ifdef USEPDFLATEX
PDFLATEXFLAGS = -halt-on-error
SYNCTEX := $(shell pdflatex -help | grep -q synctex > /dev/null 2>&1 && echo -n 1)
ifeq ($(SYNCTEX),1)
PDFLATEXFLAGS += -synctex=1
endif
endif #USEPDFLATEX

endif #REVERSEINDEX

M4FLAGS = -DPDFTK=$(PDFTK) -DINKSCAPE=$(INKSCAPE) -DUSEPDFLATEX=$(USEPDFLATEX) -DANONYMIZE=$(ANONYMIZE)

DVIPSFLAGS = -t letter

# These are all phony targets that can be given to make
FINAL_VERSIONS = submit final eprint

FINAL_STEMS = $(foreach version,$(FINAL_VERSIONS),-$(version))


.PHONY: all $(FINAL_VERSIONS) flat zip rzip help clean cleanfigs cleanall showconfig setup commit fetch

SRC_SUFFIXES = .lyx .tex .svg       # Sources - Never erase these
ifndef NOPDF
TARGET_SUFFIXES = .pdf      # Targets - erase only on clean
ifndef USEPDFLATEX
TARGET_SUFFIXES += .ps
endif
else #NOPDF
TARGET_SUFFIXES = .ps
endif

FLAT_SUFFIXES = -draft.tex -release.tex

ZIP_SUFFIXES = .zip

CAMERA_SUFFIXES = -camera-ready.zip


# Byproducts - erase only on clean
PRECIOUS_SUFFIXES = .dvi .aux .bbl .nls .nlo .flt .synctex.gz
# Byproducts - erase after build
JUNK_SUFFIXES =  .log .blg .out .ilg 

FINAL_CLEAN_SUFFIXES = $(foreach version,$(FINAL_VERSIONS),$(foreach suff,.tex $(TARGET_SUFFIXES) $(PRECIOUS_SUFFIXES) $(JUNK_SUFFIXES),-$(version)$(suff) -$(version)-bib$(suff)))

CLEAN_SUFFIXES = $(CAMERA_SUFFIXES) $(ZIP_SUFFIXES) $(FLAT_SUFFIXES) $(FINAL_CLEAN_SUFFIXES) $(TARGET_SUFFIXES) $(PRECIOUS_SUFFIXES) $(JUNK_SUFFIXES) .flt

PRECIOUS_DEPENDS = $(addprefix %,$(PRECIOUS_SUFFIXES) $(SRC_SUFFIXES))

ifndef PAPERS

PAPERS = $(sort $(basename $(foreach suf,$(SRC_SUFFIXES),$(wildcard *$(suf)))))

endif #PAPERS

TARGETS = $(foreach suffix,$(TARGET_SUFFIXES),$(addsuffix $(suffix),$(PAPERS)))
ZIP_TARGETS = $(foreach suffix,$(ZIP_SUFFIXES),$(addsuffix $(suffix),$(PAPERS)))
CAMERA_TARGETS = $(foreach suffix,$(CAMERA_SUFFIXES),$(addsuffix $(suffix),$(PAPERS)))
FLAT_TARGETS = $(foreach suffix,$(FLAT_SUFFIXES),$(addsuffix $(suffix),$(PAPERS)))

.PRECIOUS: $(PRECIOUS_DEPENDS) $(FIGS) 

all: $(TARGETS)

help:
	@echo "Available targets:"
	@echo "  all         - make draft version of paper"
	@echo "                ($(TARGETS))"
	@echo "  $(FINAL_VERSIONS)"
	@echo "              - make submission versions of paper"
	@echo "                (add -DVERSION to m4), where version is the make target"
	@echo "  flat        - create a flat file from directory tree"
	@echo "                ($(FLAT_TARGETS))"
	@echo "  zip         - create a zip file containing flattened source (including draft, with separate bib file)"
	@echo "                ($(ZIP_TARGETS))"
	@echo "  camera      - create a zip file containing flattened source for camera-ready submission"
	@echo "                ($(CAMERA_TARGETS))"
	@echo "  clean       - clean everything except for figures"
	@echo "  cleanall    - clean everything including figures"
	@echo "  setup       - setup local mercurial/git repo (use once after first clone)"
	@echo "  showconfig  - show configuration and detected helper progs"


ifeq ($(FLAT),1)
all: submit
endif

zip: $(ZIP_TARGETS)

camera: $(CAMERA_TARGETS)

flat: $(FLAT_TARGETS)


# Flat file in release mode (run through m4)
define FINAL_template =
$1-$2-bib.tex: $1-draft.tex
	$$(M4) $$(M4FLAGS) -DSUBMIT=1 -D$(call uppercase,$(2))=1 m4.defs $$? > $$@

$1-$2.tex: $1-$2.flt
	mv $$? $$@
endef



ifneq ($(M4),)
$(FINAL_VERSIONS): %: $(foreach paper,$(PAPERS),$(paper)-%.pdf)

# A rule to build the source for each final version using M4 and flattened latex
$(foreach paper,$(PAPERS),$(foreach version,$(FINAL_VERSIONS),$(eval $(call FINAL_template, $(paper),$(version)))))

else
$(FINAL_VERSIONS):
	@echo "m4 is required to build final versions ($(FINAL_VERSIONS))."

endif


# Flat file including bibliography
%.flt: %-bib.tex %-bib.bbl 
	./latexpand --keep-comments --expand-bbl $(word 2,$^) $< -o $@

# Flat file with separate bibliography
%-draft.tex: %.tex 
	./latexpand --keep-comments $< -o $@

# An escaped open-parentheses (avoids problem in eval below)
ESC_PAREN := \\(
ifneq ($(ZIP),)
# Camera-ready version with flat file, compiled figures and included bibliography
%-camera-ready.zip: %-submit.tex %-submit.pdf $(FIGS) 
# Use Perl to parse the class and package names from the log file
# (we need the log file since it resolves the packages actually used during the build)
ifneq ($(PERL),)
	$(eval PACKAGES := $(shell $(PERL) -ne "m@$(ESC_PAREN)"'[.]/(\S+[.](sty|cls))@ && print "$$1 "' $(<:.tex=.log) ) )
	@echo "Including local packages: ($(PACKAGES))"
else
	$(eval PACKAGES := $(wildcard *.sty *.cls) )
	@echo "Perl not found, including all style and class files ($(PACKAGES))"
endif
	$(ZIP) $@ $^  $(PACKAGES)

# Package with flat file, figure sources and bibliography
%.zip: $(FLAT_TARGETS) $(FIGS)
	$(ZIP) $@ $^ $(addsuffix .svg,$(FIGSBASE)) $(wildcard *.bib *.sty *.cls) 
else
zip camera:
	@echo "zip is required to create zip files and camera-ready archive."

endif



%.tex: %.lyx
	lyx -e latex $?

#Cancel default rule that uses TeX
%.dvi: %.tex

ifdef NOMENCL
NOMENCLDEP=%.nls
else
NOMENCLDEP=
endif

%.dvi: %.tex %.bbl $(NOMENCLDEP) $(FIGS)
	latex $(LATEXFLAGS) $<
	((grep -q "Rerun to get cross-references" $*.log) && \
		latex $(LATEXFLAGS) $<) || echo "No need to rerun latex"

%.bbl: %.aux
	(grep -q bibdata $? && bibtex $*) || (touch $@)

%.aux %.nlo: %.tex $(FIGS)
ifndef USEPDFLATEX
	latex $(LATEXFLAGS) $<
else
	touch $@
	pdflatex $(PDFLATEXFLAGS) $<
endif

%.ps: %.dvi
	dvips $(DVIPSFLAGS) $? -o $@


ifndef USEPDFLATEX
%.pdf: %.dvi
	$(RM) $@
	dvips -Pcmz -Pamz -q -f $? | gs -q -dNOPAUSE -dBATCH -sDEVICE=pdfwrite -sOutputFile=$@ $(DVIPDFFLAGS) -c save pop -
else
%.pdf: %.tex %.bbl $(NOMENCLDEP) $(FIGS)
	$(RM) $@
	touch $*.aux
	pdflatex $(PDFLATEXFLAGS) $<
	((grep -q "Rerun to get cross-references" $*.log) && \
		pdflatex $(PDFLATEXFLAGS) $<) || echo "Running PDFLatex once was enough"
endif
ifdef PDFTK
	$(PDFTK) $*.pdf  dump_data output $*.dump
ifdef ANONYMIZE 
	echo "InfoKey: Author" >> $*.dump
	echo "InfoValue:" >> $*.dump
	echo "InfoKey: Creator" >> $*.dump
	echo "InfoValue:" >> $*.dump
endif	
ifdef SVNREV
	echo "InfoKey: SVN.Rev" >> $*.dump
	echo "InfoValue: $(SVNREV)" >> $*.dump
endif
ifdef HGREV
	echo "InfoKey: HG.Rev" >> $*.dump
	echo "InfoValue: $(HGREV)" >> $*.dump
endif
ifdef GITREV
	echo "InfoKey: GIT.Rev" >> $*.dump
	echo "InfoValue: $(GITREV)" >> $*.dump
endif
	mv $*.pdf $*-tmp.pdf
	$(PDFTK) $*-tmp.pdf update_info $*.dump output $*.pdf  compress || mv $*-tmp.pdf $*.pdf
	-$(RM) $*-tmp.pdf $*.dump
endif
ifdef PDFOPT
	$(PDFOPT) $@ $*-tmp-opt.pdf
	mv -f $*-tmp-opt.pdf $@
endif
ifdef QPDF
	$(QPDF) --linearize $@ $*-tmp-linear.pdf
	mv -f $*-tmp-linear.pdf $@
endif

# Nomenclature package dependencies:
%.nls: %.nlo
	makeindex -s nomencl.ist -o $@ $?	


clean:
	$(RM) $(foreach suf,$(CLEAN_SUFFIXES),$(addsuffix $(suf),$(PAPERS))) 

cleanfigs:
	$(RM) $(FIGS)

cleanall: clean cleanfigs


ifdef INKSCAPE
%.pdf: %.svg
	$(INKSCAPE) -z -f $?  --export-ignore-filters -A $@
ifdef PDFTK
	$(PDFTK) $@  dump_data output $*.dump
ifdef ANONYMIZE 
	echo "InfoKey: Author" >> $*.dump
	echo "InfoValue:" >> $*.dump
	echo "InfoKey: Creator" >> $*.dump
	echo "InfoValue:" >> $*.dump
endif	
ifdef SVNREV
	echo "InfoKey: SVN.Rev" >> $*.dump
	echo "InfoValue: $(SVNREV)" >> $*.dump
endif
ifdef HGREV
	echo "InfoKey: HG.Rev" >> $*.dump
	echo "InfoValue: $(HGREV)" >> $*.dump
endif
ifdef GITREV
	echo "InfoKey: GIT.Rev" >> $*.dump
	echo "InfoValue: $(GITREV)" >> $*.dump
endif
	mv $*.pdf $*-tmp.pdf
	$(PDFTK) $*-tmp.pdf update_info $*.dump output $@  compress || mv $*-tmp.pdf $@
	-$(RM) $*-tmp.pdf $*.dump
endif
ifdef PDFOPT
	$(PDFOPT) $@ $*-tmp-opt.pdf
	mv -f $*-tmp-opt.pdf $@
endif
ifdef QPDF
	$(QPDF) --linearize $@ $*-tmp-linear.pdf
	mv -f $*-tmp-linear.pdf $@
endif

%.eps: %.svg
	$(INKSCAPE) -z -f $< -T  --export-ignore-filters -E $@

%.eps: %.svgz
	$(INKSCAPE) -z -f $< -T  --export-ignore-filters -E $@
endif

ifdef HG

ifdef PERL
setup: .hg/hgrc-orig

.hg/hgrc-orig:
	mv .hg/hgrc .hg/hgrc-orig
	$(PERL) ./hgsetup.pl .hg/hgrc-orig > .hg/hgrc 
else # No perl
setup:
	@echo Automatic Mercurial setup requires PERL
endif

else # HG not defined
ifdef SVN
setup: 
	@echo No setup required for Subversion
else 
ifdef GIT
ifdef PERL
setup: .git/config-orig

.git/config-orig:
	mv .git/config .git/config-orig
	$(PERL) ./gitsetup.pl .git/config-orig > .git/config 
else # No perl
setup:
	@echo Automatic git setup requires PERL
endif

else # No version control system recognized
setup:
	@echo No version control system found (try "make showconfig")
endif
endif
endif

showconfig:
ifdef M4
	@echo "m4: $(M4)"
else
	@echo "m4 not found (needed to make submission version)"
endif
ifdef PERL
	@echo "Perl: $(PERL)"
else
	@echo "Perl not found (needed for some version control uses)"
endif
ifdef ZIP
	@echo "Zip: $(ZIP)"
else
	@echo "Zip not found (needed for creating source and camera-ready archives)"
endif
ifdef INKSCAPE
	@echo "Inkscape: $(INKSCAPE)"
else
	@echo "Inkscape not found (needed to automatically generate figures from svg)"
endif
ifdef PDFTK
	@echo "PDFtk: $(PDFTK)"
ifdef ANONYMIZE 
	@echo " Anonymizing PDF metadata"
endif
else
	@echo "PDFtk not found (needed for revision tagging and pdf anonymization)"
endif
ifdef QPDF
	@echo "qpdf: $(QPDF)"
else
	@echo "qpdf not found (used to linearize PDF output for faster web loading)"
endif
ifdef USEPDFLATEX
	@echo "Using pdflatex"
ifeq ($(SYNCTEX),1)
	@echo "  - using synctex for reverse indexing"
else 
ifdef REVERSEINDEX
	@echo "  - synctex not available for reverse indexing"
else
	@echo "  - reverse indexing is disabled"
endif #REVERSEINDEX
endif #SYNCTEX
else  #USEPDFLATEX
	@echo "Using latex and dvips"
ifeq ($(SRCSPECIALS),1)
	@echo "  - using src-specials for reverse indexing"
else 
ifdef REVERSEINDEX
	@echo "  - src-specials not available for reverse indexing"
else
	@echo "  - reverse indexing is disabled"
endif #REVERSEINDEX
endif #SRCSPECIALS
endif #USEPDFLATEX
ifdef HG
	@echo "Using Mercurial for version control: $(HG)"
	@echo " Current revision $(HGREV)"
else
ifdef SVN
	@echo "Using Subversion for version control: $(SVN)"
	@echo " Current revision $(SVNREV)"
else
ifdef GIT
	@echo "Using Git for version control: $(GIT)"
	@echo " Current revision $(GITREV)"
else
	@echo "Not using version control"
endif
endif
endif
	@echo "Targets: $(TARGETS)"
	@echo "Figures: $(FIGS)"

################ Dependencies ############
