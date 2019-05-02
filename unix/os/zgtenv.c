/* Copyright(c) 1986 Association of Universities for Research in Astronomy Inc.
 */

#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include <libgen.h>
#define import_spp
#define	import_kernel
#define	import_knames
#include <iraf.h>

static char *_ev_scaniraf (char *envvar);
static int   _ev_loadcache (char *fname);


/* ZGTENV -- Get the value of a host system environment variable.  Look first
 * in the process environment.  If no entry is found there and the variable is
 * one of the standard named variables, get the system wide default value from
 * the file <iraf.h>, which is assumed to be located in /usr/include.
 */
int
ZGTENV (
  PKCHAR  *envvar,		/* name of variable to be fetched	*/
  PKCHAR  *outstr,		/* output string			*/
  XINT	  *maxch, 
  XINT    *status
)
{
	register char	*ip, *op;
	register int	n;


	op = (char *)outstr;
	if ((ip = getenv ((char *)envvar)) == NULL)
	    ip = _ev_scaniraf ((char *)envvar);

	if (ip == NULL) {
	    *op = EOS;
	    *status = XERR;
	} else {
	    *status = 0;
	    op[*maxch] = EOS;
	    for (n = *maxch;  --n >= 0 && (*op++ = *ip++);  )
		(*status)++;
	}

	return (XOK);
}


/*
 * Code to bootstrap the IRAF environment list for UNIX.
 */

int	ev_cacheloaded = 0;

/* SCANIRAF -- If the referenced environment variable is a well known standard
 * variable, hardcode them to their default value if not set.
 *
 * Virtually all IRAF environment variables are defined in the source code and
 * are portable.  In particular, virtually all source directories are defined
 * relative to the IRAF root directory "iraf$".  Only those definitions which
 * are both necessarily machine dependent and required for operation of the
 * bootstrap C programs (e.g., the CL, XC, etc.) are satisfied at this level.
 * These variables are the following.
 *
 *	iraf		The root directory of IRAF; if this is incorrect,
 *			    bootstrap programs like the CL will not be able
 *			    to find IRAF files.
 *
 *	host		The machine dependent subdirectory of iraf$.  The
 *			    actual name of this directory varies from system
 *			    to system (to avoid name collisions on tar tapes),
 *		 	    hence we cannot use "iraf$host/".
 *			    Examples: iraf$unix/, iraf$vms/, iraf$sun/, etc.
 *
 *	tmp		The place where IRAF is to put its temporary files.
 *			    This is normally /tmp/ for a UNIX system.  TMP
 *			    also serves as the default IMDIR.
 *	
 */
static char *
_ev_scaniraf (char *envvar)
{
	if (!ev_cacheloaded) {
	    if (_ev_loadcache (NULL) == ERR)
		return (NULL);
	    else
		ev_cacheloaded++;
	}

	return (getenv(envvar));
}


/* _EV_LOADCACHE -- Follow the link <iraf.h> to the path of the IRAF
 * installation.  Cache these in case we are called again (they do not
 * change so often that we cannot cache them in memory).  Any errors
 * in accessing the table probably indicate an error in installing
 * IRAF hence should be reported immediately.
 */
static int
_ev_loadcache (char *fname)
{
        static  char   *home, hpath[SZ_PATHNAME+1], *rpath, *lpath;

	setenv("iraf", "__LIBDIR__/iraf/", 0);
	setenv("host", "__LIBDIR__/iraf/unix/", 0);

	/* tmp */
	lpath = getenv("TMPDIR");
	if (lpath == NULL) {
	  lpath = P_tmpdir;
	}
	lpath = strdup(lpath);
	if (lpath[strlen(lpath)-1] != '/') {
	  lpath = realloc(lpath, strlen(lpath) + 2);
	  strcat(lpath, "/");
	}
	setenv("tmp", lpath, 0);
	free(lpath);

	/* Further environment variables required for compilation of
	   external packages */
	lpath = strdup("");
	rpath = getenv("CPPFLAGS");
	if (rpath != NULL) {
	  lpath = realloc(lpath, strlen(lpath) + strlen(rpath) + 2);
	  strcat(lpath, " ");
	  strcat(lpath, rpath);
	}
	rpath = getenv("CFLAGS");
	if (rpath != NULL) {
	  lpath = realloc(lpath, strlen(lpath) + strlen(rpath) + 2);
	  strcat(lpath, " ");
	  strcat(lpath, rpath);
	}
	rpath = getenv("iraf");
	if (rpath != NULL) {
	  lpath = realloc(lpath, strlen(lpath) + strlen(rpath) + 11);
	  strcat(lpath, " -I");
	  strcat(lpath, rpath);
	  strcat(lpath, "include");
	}
	
	setenv("XC_CFLAGS", lpath, 0);
	setenv("HSI_CF", lpath, 0);
	free(lpath);
	setenv("HSI_XF", "-x -Inolibc -/Wall -/O2", 0);
	setenv("HSI_FF", "-g -DBLD_KERNEL -O2", 0);
	rpath = getenv("LDFLAGS");
	if (rpath == NULL)
	  setenv("HSI_LF", " ", 0);
	else
	  setenv("HSI_LF", rpath, 0);

	return (OK);
}
