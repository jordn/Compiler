#
#
#Copyright (c) 1995,1996 The Regents of the University of California.
#All rights reserved.
#
#Permission to use, copy, modify, and distribute this software
#for any purpose, without fee, and without written agreement is
#hereby granted, provided that the above copyright notice and the following
#two paragraphs appear in all copies of this software.
#
#IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
#DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
#OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
#CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
#THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
#INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
#AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
#ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
#PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
#

#
# Top-level Makefile for student hierarchy
# 
#    This makefile is the skeleton makefile for the student's
# distribution.  To install a pre-compiled cool distribution,
# edit this Makefile as instructed below and run
#
#    gmake install
#
# The following variables are used to instantiate the skeleton makfiles and 
# for assignments. The modifications required for local installation are:

# The COOL_DIR variable should be set to the root directory of the
# distribution (the directory where this Makefile is).
#
COOL_DIR=/usr/class/cs143/cool

# SCRIPT_SHELL should be set to the full
# pathname of an `sh'-compatible shell
#
SCRIPT_SHELL=/bin/bash

# The CLASS variable should be an identifier for the couse (e.g., at Berkeley,
# this is cs164).
#
CLASS=cs143

# LIB should be any library flags needed for g++ to compile the assignments.
# The standard release only needs -lfl.  You might need to give the full
# pathname for "fl".
#
LIB=-lfl

# GMAKE should be the pathname of gmake, the GNU make utility.  
#
GMAKE=gmake

# AR should name an archiver (preferably gar, the GNU ar).  
#
AR= gar

#
# If you are using gar, you don't need to change the following settings.
# If you are not using gar, ARCHIVE_NEW should be the flags needed to
# create a new archive, and RANLIB should be a program that builds an
# archive's symbol table.

ARCHIVE_NEW = -cr
RANLIB = gar -qs

# If your archiver is gar, you don't need to change the following settings.
# If your archiver
# If for some reason you change the set of binaries or assignments the student's use,
# you may need to change the following two lines. 
#
BINARIES = spim xspim aps2c++ coolc
ASSIGNMENTS = PA1 PA2 PA2J PA3 PA3J PA4 PA4J PA5 PA5J

# 
# The cool distribution is designed to support multiple architecutres on a single
# file system.  The mechanism used in Cool is a shell program "ARCH" that returns a string
# identifying the architecture being used; the name of the architecture is used to
# select the correct executable file to run.  
#
# For example, if you have HP's and DECstations, then sitting at an HP and
# running ARCH should return `snake' while running the same command on a DECstation
# should return `pmax'.  The list of architecture names and the machine/OS configurations
# they correspond to is given below as well as in the installation notes.
#
# If you want to support Cool on multiple architectures on a single file
# system you will need an ARCH program and all students will need access to it.
# Edit the following line to set ARCH to the (full pathname of) this program on
# your system.  If you plan a single architecture installation, comment out
# this line (if it it hasn't already been instantiated to your particular
# architecture).
#
ARCH= echo i686 

# If you only want to install Cool on one architecture, comment out the preceding line
# and uncomment the one appropriate line below.
#
#ARCH= echo alpha    # for DEC Alpha running OSF
#ARCH= echo pmax     # for DECStation running Ultrix
#ARCH= echo snake    # HP running HPUX
#ARCH= echo sun4     # A sun4
#ARCH= echo i586     # Pentium running Linux
#ARCH= echo rs6000   # IBM RS6000 running AIX

#
# There is one final IMPORTANT detail. A pre-compiled distribution comes with a 
# pre-compiled spim. spim requires that the absolute path of the trap.handler be specified
# at compile time.  To enable spim, simply add a symbolic link as follows.
# If the distribution was compiled with COOL_DIR = X and you are installing
# with COOL_DIR = Y, add a symbolic link X => Y.
#
# The standard distribution is compiled in /tmp/cool; simply link /tmp/cool to 
# the COOL_DIR if you are installing from the standard distribution using
# the following command:
#
# ln -s ${COOL_DIR} /tmp/cool 
#
# Note that this last step is only necessary if you want to use spim.  All
# coolc compiler components work without this extra link.
#

#
#
# STOP; it is not necessary to modify anything below this line to install
# the system.
#

#
# This Makefile  creates
#
#    `bin/${BINARIES}'          from    `bin/dispatch.SKEL'
#    `${LINKAGE_SCRIPTS}'       from    `${LINKAGE_SCRIPTS}.SKEL'
#    `assignments/${ASSIGNMENTS}/Makefile'
#                   from `assignments/${ASSIGNMENTS}/Makefile.SKEL'
#
#    The target `install' will make these modifications.
#



#
# The DISPATCH_SCRIPTS are scripts used to dispatch to the appropriate
# binary for an architecture.  One script is created for each name in
# the BINARIES variable.
#
DISPATCH_SCRIPTS = ${BINARIES:%=bin/%}

#
# The LINKAGE_SCRIPTS are used by the makefiles in the assignments to
# set up the files in the student's assignment directories.
#
#    `etc/link-object' - This will link the object files and libraries
#          in the student's assignment directory to the version
#          appropriate for the architecture.
#    `etc/link-shared' - This will create a link in the student's
#          assignment directory to the corresponding file in the
#          distribution.  Used for files the student shouldn't modify.
#    `etc/copy-skel' - Copies a skeleton file to the student's directory.
#          Used for files the student must modify.
#
LINKAGE_SCRIPTS = etc/link-object etc/link-shared etc/copy-skel

force: 
install: ${DISPATCH_SCRIPTS} ${LINKAGE_SCRIPTS} ${ASSIGNMENTS:%=${COOL_DIR}/assignments/%/Makefile}

#
# assignments/${ASSIGNMENTS}/Makefile <== assignments/${ASSIGNMENTS}/Makefile.SKEL
#
${patsubst %,${COOL_DIR}/assignments/%/Makefile,${ASSIGNMENTS}}: %: %.SKEL Makefile force
	rm -f temp; \
	sed -e 's#CLASSDIR= ?#CLASSDIR= ${COOL_DIR}#g'  \
	    -e 's#CLASS= ?#CLASS= ${CLASS}#g'           \
	    -e 's#AR= ?#AR= ${AR}#g'			\
	    -e 's#ARCHIVE_NEW= ?#ARCHIVE_NEW= ${ARCHIVE_NEW}#g' \
	    -e 's#RANLIB= ?#RANLIB= ${RANLIB}#g' \
	    -e 's#LIB= ?#LIB= ${LIB}#g'  $< > temp;     \
	mv -f temp $@; chmod ugo+r $@

#
# bin/${BINARIES} <== bin/dispatch.SKEL
#
${DISPATCH_SCRIPTS}: ${COOL_DIR}/bin/dispatch.SKEL force
	sed -e 's#SHELL#${SCRIPT_SHELL}#g' \
	    -e 's#DIR#${COOL_DIR}#g' \
	    -e 's#ARCH#${ARCH}#g' \
	    -e 's#PROGRAM#${patsubst bin/%,%,$@}#g' $< > $@
	chmod ugo+rx $@

#
# ${LINKAGE_SCRIPTS} <== ${LINKAGE_SCRIPTS}.SKEL
#
${LINKAGE_SCRIPTS}: %: %.SKEL force
	sed -e 's#SHELL#${SCRIPT_SHELL}#g' \
	    -e 's#ARCH#${ARCH}#g' \
	    -e 's#DIR#${COOL_DIR}#g' $< > $@
	chmod ugo+rx $@



