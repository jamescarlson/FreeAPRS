# $Id: Makefile.am 195 2011-02-26 09:41:12Z oh2gve $


# Set library version info from configure.ac
libfap_la_LDFLAGS= -version-info $(FAP_LIBRARY_VERSION)


# Include the library.
lib_LTLIBRARIES = libfap.la
libfap_la_SOURCES = fap.h fap.c regs.h helpers.h helpers.c helpers2.h helpers2.c

# Include header file.
library_includedir=$(includedir)
library_include_HEADERS = fap.h
