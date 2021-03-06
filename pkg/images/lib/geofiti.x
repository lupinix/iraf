# Copyright(c) 1986 Assocation of Universities for Research in Astronomy Inc.

include <mach.h>
include <math.h>
include <math/gsurfit.h>
include "geomap.h"



# GEO_MINIT -- Initialize the fitting routines.

procedure geo_minit (fit, projection, geometry, function, xxorder, xyorder,
	xxterms, yxorder, yyorder, yxterms, maxiter, reject)

pointer	fit		#I pointer to the fit structure
int	projection	#I the coordinate projection type
int	geometry	#I the fitting geometry
int	function	#I fitting function
int	xxorder		#I order of x fit in x
int	xyorder		#I order of x fit in y
int	xxterms		#I include cross terms in x fit
int	yxorder		#I order of y fit in x
int	yyorder		#I order of y fit in y
int	yxterms		#I include cross-terms in y fit
int	maxiter		#I the maximum number of rejection interations
double	reject		#I rejection threshold in sigma

begin
	# Allocate the space.
	call malloc (fit, LEN_GEOMAP, TY_STRUCT)

	# Set function and order.
	GM_PROJECTION(fit) = projection
	GM_PROJSTR(fit) = EOS
	GM_FIT(fit) = geometry
	GM_FUNCTION(fit) = function
	GM_XXORDER(fit) = xxorder
	GM_XYORDER(fit) = xyorder
	GM_XXTERMS(fit) = xxterms
	GM_YXORDER(fit) = yxorder
	GM_YYORDER(fit) = yyorder
	GM_YXTERMS(fit) = yxterms

	# Set rejection parameters.
	GM_XRMS(fit) = 0.0d0
	GM_YRMS(fit) = 0.0d0
	GM_MAXITER(fit) = maxiter
	GM_REJECT(fit) = reject
	GM_NREJECT(fit) = 0
	GM_REJ(fit) = NULL

	# Set origin parameters.
	GM_XO(fit) = INDEFD
	GM_YO(fit) = INDEFD
	GM_XOREF(fit) = INDEFD
	GM_YOREF(fit) = INDEFD
end


# GEO_FREE -- Release the fitting space.

procedure geo_free (fit)

pointer	fit		#I pointer to the fitting structure

begin
	if (GM_REJ(fit) != NULL)
	    call mfree (GM_REJ(fit), TY_INT)
	call mfree (fit, TY_STRUCT)
end






# GEO_FIT -- Fit the surface in batch.

procedure geo_fitr (fit, sx1, sy1, sx2, sy2, xref, yref, xin, yin, wts, npts,
	xerrmsg, yerrmsg, maxch)

pointer	fit		#I pointer to fitting structure
pointer	sx1, sy1	#U pointer to linear surface
pointer	sx2, sy2	#U pointer to higher order correction
real	xref[ARB]	#I x reference array
real	yref[ARB]	#I y reference array
real	xin[ARB]	#I x array
real	yin[ARB]	#I y array
real	wts[ARB]	#I weight array
int	npts		#I the number of data points
char	xerrmsg[ARB]	#O the x fit error message
char	yerrmsg[ARB]	#O the y fit error message
int	maxch		#I maximum size of the error message

pointer	sp, xresidual, yresidual
errchk	geo_fxyr(), geo_mrejectr(), geo_fthetar(), geo_fmagnifyr()
errchk	geo_flinearr()

begin
	call smark (sp)
	call salloc (xresidual, npts, TY_REAL)
	call salloc (yresidual, npts, TY_REAL)

	switch (GM_FIT(fit)) {
	case GM_ROTATE:
	    call geo_fthetar (fit, sx1, sy1, xref, yref, xin, yin, wts,
	        Memr[xresidual], Memr[yresidual], npts, xerrmsg, maxch,
		yerrmsg, maxch)
		sx2 = NULL
		sy2 = NULL
	case GM_RSCALE:
	    call geo_fmagnifyr (fit, sx1, sy1, xref, yref, xin, yin, wts,
	        Memr[xresidual], Memr[yresidual], npts, xerrmsg, maxch,
		yerrmsg, maxch)
		sx2 = NULL
		sy2 = NULL
	case GM_RXYSCALE:
	    call geo_flinearr (fit, sx1, sy1, xref, yref, xin, yin, wts,
	        Memr[xresidual], Memr[yresidual], npts, xerrmsg, maxch,
		yerrmsg, maxch)
		sx2 = NULL
		sy2 = NULL
	default:
	    GM_ZO(fit) = GM_XOREF(fit)
	    call geo_fxyr (fit, sx1, sx2, xref, yref, xin, wts,
	        Memr[xresidual], npts, YES, xerrmsg, maxch)
	    GM_ZO(fit) = GM_YOREF(fit)
	    call geo_fxyr (fit, sy1, sy2, xref, yref, yin, wts,
	        Memr[yresidual], npts, NO, yerrmsg, maxch)
	}
	if (GM_MAXITER(fit) <= 0 || IS_INDEFD(GM_REJECT(fit)))
	    GM_NREJECT(fit) = 0
	else
	    call geo_mrejectr (fit, sx1, sy1, sx2, sy2, xref, yref, xin, yin,
		wts, Memr[xresidual], Memr[yresidual], npts, xerrmsg,
		maxch, yerrmsg, maxch)

	call sfree (sp)
end


# GEO_FTHETA -- Compute the shift and rotation angle required to match one
# set of coordinates to another.

procedure geo_fthetar (fit, sx1, sy1, xref, yref, xin, yin, wts, xresid,
	yresid, npts, xerrmsg, xmaxch, yerrmsg, ymaxch)

pointer	fit		#I pointer to the fit sturcture
pointer	sx1		#U pointer to linear x fit surface
pointer	sy1		#U pointer to linear y fit surface
real	xref[npts]	#I reference image x values
real	yref[npts]	#I reference image y values
real	xin[npts]	#I input image x values
real	yin[npts]	#I input image y values
real	wts[npts]	#I array of weights
real	xresid[npts]	#O x fit residuals
real	yresid[npts]	#O y fit residuals
int	npts		#I number of points
char	xerrmsg[ARB]	#O returned x fit error message
int	xmaxch		#I maximum number of characters in x fit error message
char	yerrmsg[ARB]	#O returned y fit error message
int	ymaxch		#I maximum number of characters in y fit error message

int	i
double	sw, sxr, syr, sxi, syi, xr0, yr0, xi0, yi0
double	syrxi, sxryi, sxrxi, syryi, num, denom, theta, det 
double	ctheta, stheta, cthetax, sthetax, cthetay, sthetay
real	xmin, xmax, ymin, ymax
pointer	sp, savefit
bool	fp_equald()

begin
	# Allocate some working space
	call smark (sp)
	call salloc (savefit, GS_SAVECOEFF + 3, TY_REAL)

	# Initialize the fit.
        if (sx1 != NULL)
            call gsfree (sx1)
        if (sy1 != NULL)
            call gsfree (sy1)

        # Determine the minimum and maximum values
        if (fp_equald (GM_XMIN(fit), GM_XMAX(fit))) {
            xmin = GM_XMIN(fit) - 0.5d0
            xmax = GM_XMAX(fit) + 0.5d0
        } else {
            xmin = GM_XMIN(fit)
            xmax = GM_XMAX(fit)
        }
        if (fp_equald (GM_YMIN(fit), GM_YMAX(fit))) {
            ymin = GM_YMIN(fit) - 0.5d0
            ymax = GM_YMAX(fit) + 0.5d0
        } else {
            ymin = GM_YMIN(fit)
            ymax = GM_YMAX(fit)
        }

	# Compute the sums required to determine the offsets.
	sw = 0.0d0
	sxr = 0.0d0
	syr = 0.0d0
	sxi = 0.0d0
	syi = 0.0d0
	do i = 1, npts {
	    sw = sw + wts[i]
	    sxr = sxr + wts[i] * xref[i]
	    syr = syr + wts[i] * yref[i]
	    sxi = sxi + wts[i] * xin[i]
	    syi = syi + wts[i] * yin[i]
	}

	# Do the fit.
	if (sw < 2) {
	    call sfree (sp)
	    if (GM_PROJECTION(fit) == GM_NONE) {
	        call sprintf (xerrmsg, xmaxch,
		    "Too few data points for X and Y fits.")
	        call sprintf (yerrmsg, ymaxch,
		    "Too few data points for X and Y fits.")
	        call error (1, "Too few data points for X and Y fits.")
	    } else {
	        call sprintf (xerrmsg, xmaxch,
		    "Too few data points for XI and ETA fits.")
	        call sprintf (yerrmsg, ymaxch,
		    "Too few data points for XI and ETA fits.")
	        call error (1, "Too few data points for XI and ETA fits.")
	    }

	} else {

	    # Compute the sums required to compute the rotation angle.
	    xr0 = sxr / sw
	    yr0 = syr / sw
	    xi0 = sxi / sw
	    yi0 = syi / sw
	    syrxi = 0.0d0
	    sxryi = 0.0d0
	    sxrxi = 0.0d0
	    syryi = 0.0d0
	    do i = 1, npts {
		syrxi = syrxi + wts[i] * (yref[i] - yr0) * (xin[i] - xi0)
		sxryi = sxryi + wts[i] * (xref[i] - xr0) * (yin[i] - yi0)
		sxrxi = sxrxi + wts[i] * (xref[i] - xr0) * (xin[i] - xi0)
		syryi = syryi + wts[i] * (yref[i] - yr0) * (yin[i] - yi0)
	    }

	    # Compute the rotation angle.
	    num = sxrxi * syryi
	    denom = syrxi * sxryi
	    if (fp_equald (num, denom))
		det = 0.0d0
	    else
		det = num - denom
	    if (det < 0.0d0) {
		num = syrxi + sxryi
	        denom = -sxrxi + syryi
	    } else {
	        num = syrxi - sxryi
	        denom = sxrxi + syryi
	    }
	    if (fp_equald (num, 0.0d0) && fp_equald (denom, 0.0d0)) {
		theta = 0.0d0
	        if (GM_PROJECTION(fit) == GM_NONE) {
	            call sprintf (xerrmsg, xmaxch, "Warning singular X fit.")
	            call sprintf (yerrmsg, ymaxch, "Warning singular Y fit.")
		} else {
	            call sprintf (xerrmsg, xmaxch, "Warning singular XI fit.")
	            call sprintf (yerrmsg, ymaxch, "Warning singular ETA fit.")
		}
	    } else {
		theta = atan2 (num, denom)
		if (theta < 0.0d0)
		    theta = theta + TWOPI
	        if (GM_PROJECTION(fit) == GM_NONE) {
		    call sprintf (xerrmsg, xmaxch, "X fit ok.")
		    call sprintf (yerrmsg, ymaxch, "Y fit ok.")
		} else {
		    call sprintf (xerrmsg, xmaxch, "XI fit ok.")
		    call sprintf (yerrmsg, ymaxch, "ETA fit ok.")
		}
	    }

	    # Compute the polynomial coefficients.
	    ctheta = cos (theta)
	    stheta = sin (theta)
	    if (det < 0.0d0) {
	        cthetax = -ctheta
	        sthetay = -stheta
	    } else {
	        cthetax = ctheta
	        sthetay = stheta
	    }
	    sthetax = stheta
	    cthetay = ctheta

	    # Compute the x fit coefficients.
	    call gsinit (sx1, GM_FUNCTION(fit), 2, 2, GS_XNONE, xmin, xmax,
	        ymin, ymax)
	    call gssave (sx1, Memr[savefit])
	    call gsfree (sx1)
	    if (GM_FUNCTION(fit) == GS_POLYNOMIAL) {
	        Memr[savefit+GS_SAVECOEFF] = xi0 - (xr0 * cthetax + yr0 *
		    sthetax)
	        Memr[savefit+GS_SAVECOEFF+1] = cthetax
	        Memr[savefit+GS_SAVECOEFF+2] = sthetax
	    } else {
	        Memr[savefit+GS_SAVECOEFF] = xi0 - (xr0 * cthetax + yr0 *
		    sthetax) + cthetax * (xmax + xmin) / 2.0 + sthetax * 
		    (ymax + ymin) / 2
	        Memr[savefit+GS_SAVECOEFF+1] = cthetax * (xmax - xmin) / 2.0
	        Memr[savefit+GS_SAVECOEFF+2] = sthetax * (ymax - ymin) / 2.0
	    }
	    call gsrestore (sx1, Memr[savefit])

	    # Compute the y fit coefficients.
	    call gsinit (sy1, GM_FUNCTION(fit), 2, 2, GS_XNONE, xmin, xmax,
	        ymin, ymax)
	    call gssave (sy1, Memr[savefit])
	    call gsfree (sy1)
	    if (GM_FUNCTION(fit) == GS_POLYNOMIAL) {
	        Memr[savefit+GS_SAVECOEFF] = yi0 - (-xr0 * sthetay + yr0 *
		    cthetay)
	        Memr[savefit+GS_SAVECOEFF+1] = -sthetay
	        Memr[savefit+GS_SAVECOEFF+2] = cthetay
	    } else {
	        Memr[savefit+GS_SAVECOEFF] = yi0 - (-xr0 * sthetay + yr0 *
		    cthetay) - sthetay * (xmax + xmin) / 2.0 + cthetay *
		    (ymax + ymin) / 2.0
	        Memr[savefit+GS_SAVECOEFF+1] = -sthetay * (xmax - xmin) / 2.0
	        Memr[savefit+GS_SAVECOEFF+2] = cthetay * (ymax - ymin) / 2.0
	    }
	    call gsrestore (sy1, Memr[savefit])

	    # Compute the residuals
	    call gsvector (sx1, xref, yref, xresid, npts)
	    call gsvector (sy1, xref, yref, yresid, npts)
	    call asubr (xin, xresid, xresid, npts) 
	    call asubr (yin, yresid, yresid, npts) 

            # Compute the number of zero weighted points.
            GM_NWTS0(fit) = 0
            do i = 1, npts {
                if (wts[i] <= real(0.0))
                    GM_NWTS0(fit) = GM_NWTS0(fit) + 1
            }

            # Compute the rms of the x and y fits.
            GM_XRMS(fit) = 0.0d0
            do i = 1, npts
                GM_XRMS(fit) = GM_XRMS(fit) + wts[i] * xresid[i] ** 2
            GM_YRMS(fit) = 0.0d0
            do i = 1, npts
                GM_YRMS(fit) = GM_YRMS(fit) + wts[i] * yresid[i] ** 2

            GM_NPTS(fit) = npts

	}

        call sfree (sp)
end


# GEO_FMAGNIFY -- Compute the shift, the rotation angle, and the magnification
# factor which is assumed to be the same in x and y, required to match one
# set of coordinates to another.

procedure geo_fmagnifyr (fit, sx1, sy1, xref, yref, xin, yin, wts, xresid,
	yresid, npts, xerrmsg, xmaxch, yerrmsg, ymaxch)

pointer	fit		#I pointer to the fit sturcture
pointer	sx1		#U pointer to linear x fit surface
pointer	sy1		#U pointer to linear y fit surface
real	xref[npts]	#I reference image x values
real	yref[npts]	#I reference image y values
real	xin[npts]	#I input image x values
real	yin[npts]	#I input image y values
real	wts[npts]	#I array of weights
real	xresid[npts]	#O x fit residuals
real	yresid[npts]	#O y fit residuals
int	npts		#I number of points
char	xerrmsg[ARB]	#O returned x fit error message
int	xmaxch		#I maximum number of characters in x fit error message
char	yerrmsg[ARB]	#O returned y fit error message
int	ymaxch		#I maximum number of characters in y fit error message

int	i
double	sw, sxr, syr, sxi, syi, xr0, yr0, xi0, yi0
double	syrxi, sxryi, sxrxi, syryi, sxrxr, syryr, num, denom, det, theta
double	mag, ctheta, stheta, cthetax, sthetax, cthetay, sthetay
real	xmin, xmax, ymin, ymax
pointer	sp, savefit
bool	fp_equald()

begin
	# Allocate some working space
	call smark (sp)
	call salloc (savefit, GS_SAVECOEFF + 3, TY_REAL)

	# Initialize the fit.
        if (sx1 != NULL)
            call gsfree (sx1)
        if (sy1 != NULL)
            call gsfree (sy1)

        # Determine the minimum and maximum values.
        if (fp_equald (GM_XMIN(fit), GM_XMAX(fit))) {
            xmin = GM_XMIN(fit) - 0.5d0
            xmax = GM_XMAX(fit) + 0.5d0
        } else {
            xmin = GM_XMIN(fit)
            xmax = GM_XMAX(fit)
        }
        if (fp_equald (GM_YMIN(fit), GM_YMAX(fit))) {
            ymin = GM_YMIN(fit) - 0.5d0
            ymax = GM_YMAX(fit) + 0.5d0
        } else {
            ymin = GM_YMIN(fit)
            ymax = GM_YMAX(fit)
        }

	# Compute the sums required to determine the offsets.
	sw = 0.0d0
	sxr = 0.0d0
	syr = 0.0d0
	sxi = 0.0d0
	syi = 0.0d0
	do i = 1, npts {
	    sw = sw + wts[i]
	    sxr = sxr + wts[i] * xref[i]
	    syr = syr + wts[i] * yref[i]
	    sxi = sxi + wts[i] * xin[i]
	    syi = syi + wts[i] * yin[i]
	}

	# Do the fit.
	if (sw < 2) {
	    call sfree (sp)
	    if (GM_PROJECTION(fit) == GM_NONE) {
	        call sprintf (xerrmsg, xmaxch,
		    "Too few data points for X and Y fits.")
	        call sprintf (yerrmsg, ymaxch,
		    "Too few data points for X and Y fits.")
	        call error (1, "Too few data points for X and Y fits.")
	    } else {
	        call sprintf (xerrmsg, xmaxch,
		    "Too few data points for XI and ETA fits.")
	        call sprintf (yerrmsg, ymaxch,
		    "Too few data points for XI and ETA fits.")
	        call error (1, "Too few data points for XI and ETA fits.")
	    }
	} else {

	    # Compute the sums.
	    xr0 = sxr / sw
	    yr0 = syr / sw
	    xi0 = sxi / sw
	    yi0 = syi / sw
	    sxrxr = 0.0d0
	    syryr = 0.0d0
	    syrxi = 0.0d0
	    sxryi = 0.0d0
	    sxrxi = 0.0d0
	    syryi = 0.0d0
	    do i = 1, npts {
		sxrxr = sxrxr + wts[i] * (xref[i] - xr0) * (xref[i] - xr0)
		syryr = syryr + wts[i] * (yref[i] - yr0) * (yref[i] - yr0)
		syrxi = syrxi + wts[i] * (yref[i] - yr0) * (xin[i] - xi0)
		sxryi = sxryi + wts[i] * (xref[i] - xr0) * (yin[i] - yi0)
		sxrxi = sxrxi + wts[i] * (xref[i] - xr0) * (xin[i] - xi0)
		syryi = syryi + wts[i] * (yref[i] - yr0) * (yin[i] - yi0)
	    }

	    # Compute the rotation angle.
	    num = sxrxi * syryi
	    denom = syrxi * sxryi
	    if (fp_equald (num, denom))
		det = 0.0d0
	    else
		det = num - denom
	    if (det < 0.0d0) {
		num = syrxi + sxryi
	        denom = -sxrxi + syryi
	    } else {
	        num = syrxi - sxryi
	        denom = sxrxi + syryi
	    }
	    if (fp_equald (num, 0.0d0) && fp_equald (denom, 0.0d0)) {
		theta = 0.0d0
	        if (GM_PROJECTION(fit) == GM_NONE) {
	            call sprintf (xerrmsg, xmaxch, "Warning singular X fit.")
	            call sprintf (yerrmsg, ymaxch, "Warning singular Y fit.")
		} else {
	            call sprintf (xerrmsg, xmaxch, "Warning singular XI fit.")
	            call sprintf (yerrmsg, ymaxch, "Warning singular ETA fit.")
		}
	    } else {
		theta = atan2 (num, denom)
		if (theta < 0.0d0)
		    theta = theta + TWOPI
	        if (GM_PROJECTION(fit) == GM_NONE) {
		    call sprintf (xerrmsg, xmaxch, "X fit ok.")
		    call sprintf (yerrmsg, ymaxch, "Y fit ok.")
		} else {
		    call sprintf (xerrmsg, xmaxch, "XI fit ok.")
		    call sprintf (yerrmsg, ymaxch, "ETA fit ok.")
		}
	    }

	    # Compute the magnification factor.
	    ctheta = cos (theta)
	    stheta = sin (theta)
	    num = denom * ctheta + num * stheta
	    denom = sxrxr + syryr
	    if (denom <= 0.0d0) {
		mag = 1.0 
	        if (GM_PROJECTION(fit) == GM_NONE) {
	            call sprintf (xerrmsg, xmaxch, "Warning singular X fit.")
	            call sprintf (yerrmsg, ymaxch, "Warning singular Y fit.")
		} else {
	            call sprintf (xerrmsg, xmaxch, "Warning singular XI fit.")
	            call sprintf (yerrmsg, ymaxch, "Warning singular ETA fit.")
		}
	    } else {
		mag = num / denom
	        if (GM_PROJECTION(fit) == GM_NONE) {
		    call sprintf (xerrmsg, xmaxch, "X fit ok.")
		    call sprintf (yerrmsg, ymaxch, "Y fit ok.")
		} else {
		    call sprintf (xerrmsg, xmaxch, "XI fit ok.")
		    call sprintf (yerrmsg, ymaxch, "ETA fit ok.")
		}
	    }

	    # Compute the polynomial coefficients.
	    if (det < 0.0d0) {
	        cthetax = -mag * ctheta
	        sthetay = -mag * stheta
	    } else {
	        cthetax = mag * ctheta
	        sthetay = mag * stheta
	    }
	    sthetax = mag * stheta
	    cthetay = mag * ctheta

	    # Compute the x fit coefficients.
	    call gsinit (sx1, GM_FUNCTION(fit), 2, 2, GS_XNONE, xmin, xmax,
	        ymin, ymax)
	    call gssave (sx1, Memr[savefit])
	    call gsfree (sx1)
	    if (GM_FUNCTION(fit) == GS_POLYNOMIAL) {
	        Memr[savefit+GS_SAVECOEFF] = xi0 - (xr0 * cthetax + yr0 *
		    sthetax)
	        Memr[savefit+GS_SAVECOEFF+1] = cthetax
	        Memr[savefit+GS_SAVECOEFF+2] = sthetax
	    } else {
	        Memr[savefit+GS_SAVECOEFF] = xi0 - (xr0 * cthetax + yr0 *
		    sthetax) + cthetax * (xmax + xmin) / 2.0 + sthetax * 
		    (ymax + ymin) / 2
	        Memr[savefit+GS_SAVECOEFF+1] = cthetax * (xmax - xmin) / 2.0
	        Memr[savefit+GS_SAVECOEFF+2] = sthetax * (ymax - ymin) / 2.0
	    }
	    call gsrestore (sx1, Memr[savefit])

	    # Compute the y fit coefficients.
	    call gsinit (sy1, GM_FUNCTION(fit), 2, 2, GS_XNONE, xmin, xmax,
	        ymin, ymax)
	    call gssave (sy1, Memr[savefit])
	    call gsfree (sy1)
	    if (GM_FUNCTION(fit) == GS_POLYNOMIAL) {
	        Memr[savefit+GS_SAVECOEFF] = yi0 - (-xr0 * sthetay + yr0 *
		    cthetay)
	        Memr[savefit+GS_SAVECOEFF+1] = -sthetay
	        Memr[savefit+GS_SAVECOEFF+2] = cthetay
	    } else {
	        Memr[savefit+GS_SAVECOEFF] = yi0 - (-xr0 * sthetay + yr0 *
		    cthetay) - sthetay * (xmax + xmin) / 2.0 + cthetay *
		    (ymax + ymin) / 2.0
	        Memr[savefit+GS_SAVECOEFF+1] = -sthetay * (xmax - xmin) / 2.0
	        Memr[savefit+GS_SAVECOEFF+2] = cthetay * (ymax - ymin) / 2.0
	    }
	    call gsrestore (sy1, Memr[savefit])

	    # Compute the residuals
	    call gsvector (sx1, xref, yref, xresid, npts)
	    call gsvector (sy1, xref, yref, yresid, npts)
	    call asubr (xin, xresid, xresid, npts) 
	    call asubr (yin, yresid, yresid, npts) 

            # Compute the number of zero weighted points.
            GM_NWTS0(fit) = 0
            do i = 1, npts {
                if (wts[i] <= real(0.0))
                    GM_NWTS0(fit) = GM_NWTS0(fit) + 1
            }

            # Compute the rms of the x and y fits.
            GM_XRMS(fit) = 0.0d0
            do i = 1, npts
                GM_XRMS(fit) = GM_XRMS(fit) + wts[i] * xresid[i] ** 2
            GM_YRMS(fit) = 0.0d0
            do i = 1, npts
                GM_YRMS(fit) = GM_YRMS(fit) + wts[i] * yresid[i] ** 2

            GM_NPTS(fit) = npts

	}

        call sfree (sp)
end


# GEO_FLINEAR -- Compute the shift, the rotation angle, and the x and y scale
# factors required to match one set of coordinates to another.

procedure geo_flinearr (fit, sx1, sy1, xref, yref, xin, yin, wts, xresid,
	yresid, npts, xerrmsg, xmaxch, yerrmsg, ymaxch)

pointer	fit		#I pointer to the fit sturcture
pointer	sx1		#U pointer to linear x fit surface
pointer	sy1		#U pointer to linear y fit surface
real	xref[npts]	#I reference image x values
real	yref[npts]	#I reference image y values
real	xin[npts]	#I input image x values
real	yin[npts]	#I input image y values
real	wts[npts]	#I array of weights
real	xresid[npts]	#O x fit residuals
real	yresid[npts]	#O y fit residuals
int	npts		#I number of points
char	xerrmsg[ARB]	#O returned x fit error message
int	xmaxch		#I maximum number of characters in x fit error message
char	yerrmsg[ARB]	#O returned y fit error message
int	ymaxch		#I maximum number of characters in y fit error message

int	i
double	sw, sxr, syr, sxi, syi, xr0, yr0, xi0, yi0
double	syrxi, sxryi, sxrxi, syryi, sxrxr, syryr, num, denom, theta
double	xmag, ymag, ctheta, stheta, cthetax, sthetax, cthetay, sthetay
real	xmin, xmax, ymin, ymax
pointer	sp, savefit
bool	fp_equald()

begin
	# Allocate some working space
	call smark (sp)
	call salloc (savefit, GS_SAVECOEFF + 3, TY_REAL)

	# Initialize the fit.
        if (sx1 != NULL)
            call gsfree (sx1)
        if (sy1 != NULL)
            call gsfree (sy1)

        # Determine the minimum and maximum values.
        if (fp_equald (GM_XMIN(fit), GM_XMAX(fit))) {
            xmin = GM_XMIN(fit) - 0.5d0
            xmax = GM_XMAX(fit) + 0.5d0
        } else {
            xmin = GM_XMIN(fit)
            xmax = GM_XMAX(fit)
        }
        if (fp_equald (GM_YMIN(fit), GM_YMAX(fit))) {
            ymin = GM_YMIN(fit) - 0.5d0
            ymax = GM_YMAX(fit) + 0.5d0
        } else {
            ymin = GM_YMIN(fit)
            ymax = GM_YMAX(fit)
        }

	# Compute the sums required to determine the offsets.
	sw = 0.0d0
	sxr = 0.0d0
	syr = 0.0d0
	sxi = 0.0d0
	syi = 0.0d0
	do i = 1, npts {
	    sw = sw + wts[i]
	    sxr = sxr + wts[i] * xref[i]
	    syr = syr + wts[i] * yref[i]
	    sxi = sxi + wts[i] * xin[i]
	    syi = syi + wts[i] * yin[i]
	}

	# Do the fit.
	if (sw < 3) {
	    call sfree (sp)
	    if (GM_PROJECTION(fit) == GM_NONE) {
	        call sprintf (xerrmsg, xmaxch,
		    "Too few data points for X and Y fits.")
	        call sprintf (yerrmsg, ymaxch,
		    "Too few data points for X and Y fits.")
	        call error (1, "Too few data points for X and Y fits.")
	    } else {
	        call sprintf (xerrmsg, xmaxch,
		    "Too few data points for XI and ETA fits.")
	        call sprintf (yerrmsg, ymaxch,
		    "Too few data points for XI and ETA fits.")
	        call error (1, "Too few data points for XI and ETA fits.")
	    }
	} else {
	    xr0 = sxr / sw
	    yr0 = syr / sw
	    xi0 = sxi / sw
	    yi0 = syi / sw
	    sxrxr = 0.0d0
	    syryr = 0.0d0
	    syrxi = 0.0d0
	    sxryi = 0.0d0
	    sxrxi = 0.0d0
	    syryi = 0.0d0
	    do i = 1, npts {
		sxrxr = sxrxr + wts[i] * (xref[i] - xr0) * (xref[i] - xr0)
		syryr = syryr + wts[i] * (yref[i] - yr0) * (yref[i] - yr0)
		syrxi = syrxi + wts[i] * (yref[i] - yr0) * (xin[i] - xi0)
		sxryi = sxryi + wts[i] * (xref[i] - xr0) * (yin[i] - yi0)
		sxrxi = sxrxi + wts[i] * (xref[i] - xr0) * (xin[i] - xi0)
		syryi = syryi + wts[i] * (yref[i] - yr0) * (yin[i] - yi0)
	    }

	    # Compute the rotation angle.
	    num = 2.0d0 * (sxrxr * syrxi * syryi - syryr * sxrxi * sxryi)
	    denom = syryr * (sxrxi - sxryi) * (sxrxi + sxryi) - sxrxr *
	        (syrxi + syryi) * (syrxi - syryi) 
	    if (fp_equald (num, 0.0d0) && fp_equald (denom, 0.0d0)) {
		theta = 0.0d0
	        if (GM_PROJECTION(fit) == GM_NONE) {
	            call sprintf (xerrmsg, xmaxch, "Warning singular X fit.")
	            call sprintf (yerrmsg, ymaxch, "Warning singular Y fit.")
		} else {
	            call sprintf (xerrmsg, xmaxch, "Warning singular XI fit.")
	            call sprintf (yerrmsg, ymaxch, "Warning singular ETA fit.")
		}
	    } else {
		theta = atan2 (num, denom) / 2.0d0
		if (theta < 0.0d0)
		    theta = theta + TWOPI
	        if (GM_PROJECTION(fit) == GM_NONE) {
		    call sprintf (xerrmsg, xmaxch, "X fit ok.")
		    call sprintf (yerrmsg, ymaxch, "Y fit ok.")
		} else {
		    call sprintf (xerrmsg, xmaxch, "XI fit ok.")
		    call sprintf (yerrmsg, ymaxch, "ETA fit ok.")
		}
	    }
	    ctheta = cos (theta)
	    stheta = sin (theta)

	    # Compute the x magnification factor.
	    num = sxrxi * ctheta - sxryi * stheta
	    denom = sxrxr
	    if (denom <= 0.0d0) {
		xmag = 1.0 
	        if (GM_PROJECTION(fit) == GM_NONE) {
	            call sprintf (xerrmsg, xmaxch, "Warning singular X fit.")
	            call sprintf (yerrmsg, ymaxch, "Warning singular Y fit.")
		} else {
	            call sprintf (xerrmsg, xmaxch, "Warning singular XI fit.")
	            call sprintf (yerrmsg, ymaxch, "Warning singular ETA fit.")
		}
	    } else {
		xmag = num / denom
	        if (GM_PROJECTION(fit) == GM_NONE) {
		    call sprintf (xerrmsg, xmaxch, "X fit ok.")
		    call sprintf (yerrmsg, ymaxch, "Y fit ok.")
		} else {
		    call sprintf (xerrmsg, xmaxch, "XI fit ok.")
		    call sprintf (yerrmsg, ymaxch, "ETA fit ok.")
		}
	    }

	    # Compute the y magnification factor.
	    num = syrxi * stheta + syryi * ctheta
	    denom = syryr
	    if (denom <= 0.0d0) {
		ymag = 1.0 
	        if (GM_PROJECTION(fit) == GM_NONE) {
	            call sprintf (xerrmsg, xmaxch, "Warning singular X fit.")
	            call sprintf (yerrmsg, ymaxch, "Warning singular Y fit.")
		} else {
	            call sprintf (xerrmsg, xmaxch, "Warning singular XI fit.")
	            call sprintf (yerrmsg, ymaxch, "Warning singular ETA fit.")
		}
	    } else {
		ymag = num / denom
	        if (GM_PROJECTION(fit) == GM_NONE) {
		    call sprintf (xerrmsg, xmaxch, "X fit ok.")
		    call sprintf (yerrmsg, ymaxch, "Y fit ok.")
		} else {
		    call sprintf (xerrmsg, xmaxch, "XI fit ok.")
		    call sprintf (yerrmsg, ymaxch, "ETA fit ok.")
		}
	    }

	    # Compute the polynomial coefficients.
	    cthetax = xmag * ctheta
	    sthetax = ymag * stheta
	    sthetay = xmag * stheta
	    cthetay = ymag * ctheta

	    # Compute the x fit coefficients.
	    call gsinit (sx1, GM_FUNCTION(fit), 2, 2, GS_XNONE, xmin, xmax,
	        ymin, ymax)
	    call gssave (sx1, Memr[savefit])
	    call gsfree (sx1)
	    if (GM_FUNCTION(fit) == GS_POLYNOMIAL) {
	        Memr[savefit+GS_SAVECOEFF] = xi0 - (xr0 * cthetax + yr0 *
		    sthetax)
	        Memr[savefit+GS_SAVECOEFF+1] = cthetax
	        Memr[savefit+GS_SAVECOEFF+2] = sthetax
	    } else {
	        Memr[savefit+GS_SAVECOEFF] = xi0 - (xr0 * cthetax + yr0 *
		    sthetax) + cthetax * (xmax + xmin) / 2.0 + sthetax * 
		    (ymax + ymin) / 2
	        Memr[savefit+GS_SAVECOEFF+1] = cthetax * (xmax - xmin) / 2.0
	        Memr[savefit+GS_SAVECOEFF+2] = sthetax * (ymax - ymin) / 2.0
	    }
	    call gsrestore (sx1, Memr[savefit])

	    # Compute the y fit coefficients.
	    call gsinit (sy1, GM_FUNCTION(fit), 2, 2, GS_XNONE, xmin, xmax,
	        ymin, ymax)
	    call gssave (sy1, Memr[savefit])
	    call gsfree (sy1)
	    if (GM_FUNCTION(fit) == GS_POLYNOMIAL) {
	        Memr[savefit+GS_SAVECOEFF] = yi0 - (-xr0 * sthetay + yr0 *
		    cthetay)
	        Memr[savefit+GS_SAVECOEFF+1] = -sthetay
	        Memr[savefit+GS_SAVECOEFF+2] = cthetay
	    } else {
	        Memr[savefit+GS_SAVECOEFF] = yi0 - (-xr0 * sthetay + yr0 *
		    cthetay) - sthetay * (xmax + xmin) / 2.0 + cthetay *
		    (ymax + ymin) / 2.0
	        Memr[savefit+GS_SAVECOEFF+1] = -sthetay * (xmax - xmin) / 2.0
	        Memr[savefit+GS_SAVECOEFF+2] = cthetay * (ymax - ymin) / 2.0
	    }
	    call gsrestore (sy1, Memr[savefit])

	    # Compute the residuals
	    call gsvector (sx1, xref, yref, xresid, npts)
	    call gsvector (sy1, xref, yref, yresid, npts)
	    call asubr (xin, xresid, xresid, npts) 
	    call asubr (yin, yresid, yresid, npts) 

            # Compute the number of zero weighted points.
            GM_NWTS0(fit) = 0
            do i = 1, npts {
                if (wts[i] <= real(0.0))
                    GM_NWTS0(fit) = GM_NWTS0(fit) + 1
            }

            # Compute the rms of the x and y fits.
            GM_XRMS(fit) = 0.0d0
            do i = 1, npts
                GM_XRMS(fit) = GM_XRMS(fit) + wts[i] * xresid[i] ** 2
            GM_YRMS(fit) = 0.0d0
            do i = 1, npts
                GM_YRMS(fit) = GM_YRMS(fit) + wts[i] * yresid[i] ** 2

            GM_NPTS(fit) = npts

	}

        call sfree (sp)
end


# GEO_FXY -- Fit the surface.

procedure geo_fxyr (fit, sf1, sf2, x, y, z, wts, resid, npts, xfit, errmsg,
	maxch)

pointer	fit		#I pointer to the fit sturcture
pointer	sf1		#U pointer to linear surface
pointer	sf2		#U pointer to higher order surface
real	x[npts]		#I reference image x values
real	y[npts]		#I reference image y values
real	z[npts]	        #I z values 
real	wts[npts]	#I array of weights
real	resid[npts]	#O fitted residuals
int	npts		#I number of points
int	xfit		#I X fit ?
char	errmsg[ARB]	#O returned error message
int	maxch		#I maximum number of characters in error message

int	i, ier, ncoeff
pointer	sp, zfit, savefit, coeff
real	xmin, xmax, ymin, ymax
bool	fp_equald()

begin
	# Allocate working space.
	call smark (sp)
	call salloc (zfit, npts, TY_REAL)
	call salloc (savefit, GS_SAVECOEFF + 3, TY_REAL)
	call salloc (coeff, 3, TY_REAL)

	# Determine the minimum and maximum values
	if (fp_equald (GM_XMIN(fit), GM_XMAX(fit))) {
	    xmin = GM_XMIN(fit) - 0.5d0
	    xmax = GM_XMAX(fit) + 0.5d0
	} else {
	    xmin = GM_XMIN(fit)
	    xmax = GM_XMAX(fit)
	}
	if (fp_equald (GM_YMIN(fit), GM_YMAX(fit))) {
	    ymin = GM_YMIN(fit) - 0.5d0
	    ymax = GM_YMAX(fit) + 0.5d0
	} else {
	    ymin = GM_YMIN(fit)
	    ymax = GM_YMAX(fit)
	}

	# Initalize fit
	if (sf1 != NULL)
	    call gsfree (sf1)
	if (sf2 != NULL)
	    call gsfree (sf2)

	if (xfit == YES) {

	    switch (GM_FIT(fit)) {

	    case GM_SHIFT:
	        call gsinit (sf1, GM_FUNCTION(fit), 2, 2, GS_XNONE, xmin, xmax,
	            ymin, ymax)
		call gssave (sf1, Memr[savefit])
		call gsfree (sf1)
	        call gsinit (sf1, GM_FUNCTION(fit), 1, 1, GS_XNONE, xmin, xmax,
	            ymin, ymax)
		call asubr (z, x, Memr[zfit], npts)
	        call gsfit (sf1, x, y, Memr[zfit], wts, npts, WTS_USER, ier)
		call gscoeff (sf1, Memr[coeff], ncoeff)
		if (GM_FUNCTION(fit) == GS_POLYNOMIAL) {
		    Memr[savefit+GS_SAVECOEFF] = Memr[coeff]
		    Memr[savefit+GS_SAVECOEFF+1] = 1.0
		    Memr[savefit+GS_SAVECOEFF+2] = 0.0
		} else {
		    Memr[savefit+GS_SAVECOEFF] = Memr[coeff] + (xmax + xmin) /
		        2.0
		    Memr[savefit+GS_SAVECOEFF+1] = (xmax - xmin) / 2.0
		    Memr[savefit+GS_SAVECOEFF+2] = 0.0
		}
		call gsfree (sf1)
		call gsrestore (sf1, Memr[savefit])
	        sf2 = NULL

	    case GM_XYSCALE:
	        call gsinit (sf1, GM_FUNCTION(fit), 2, 1, GS_XNONE, xmin, xmax,
	            ymin, ymax)
	        call gsfit (sf1, x, y, z, wts, npts, WTS_USER, ier)
	        sf2 = NULL

	    default:
	        call gsinit (sf1, GM_FUNCTION(fit), 2, 2, GS_XNONE, xmin, xmax,
	            ymin, ymax)
		call gsset (sf1, GSXREF, GM_XO(fit))
		call gsset (sf1, GSYREF, GM_YO(fit))
		call gsset (sf1, GSZREF, GM_ZO(fit))
	        call gsfit (sf1, x, y, z, wts, npts, WTS_USER, ier)
	        if (GM_XXORDER(fit) > 2 || GM_XYORDER(fit) > 2 ||
		    GM_XXTERMS(fit) == GS_XFULL)
	            call gsinit (sf2, GM_FUNCTION(fit), GM_XXORDER(fit),
		        GM_XYORDER(fit), GM_XXTERMS(fit), xmin, xmax, ymin,
			ymax)
	        else 
	            sf2 = NULL
	    }

	} else {

	    switch (GM_FIT(fit)) {

	    case GM_SHIFT:
	        call gsinit (sf1, GM_FUNCTION(fit), 2, 2, GS_XNONE, xmin, xmax,
	            ymin, ymax)
		call gssave (sf1, Memr[savefit])
		call gsfree (sf1)
	        call gsinit (sf1, GM_FUNCTION(fit), 1, 1, GS_XNONE, xmin, xmax,
	            ymin, ymax)
		call asubr (z, y, Memr[zfit], npts)
	        call gsfit (sf1, x, y, Memr[zfit], wts, npts, WTS_USER, ier)
		call gscoeff (sf1, Memr[coeff], ncoeff)
		if (GM_FUNCTION(fit) == GS_POLYNOMIAL) {
		    Memr[savefit+GS_SAVECOEFF] = Memr[coeff]
		    Memr[savefit+GS_SAVECOEFF+1] = 0.0
		    Memr[savefit+GS_SAVECOEFF+2] = 1.0
		} else {
		    Memr[savefit+GS_SAVECOEFF] = Memr[coeff] + (ymin + ymax) /
			2.0
		    Memr[savefit+GS_SAVECOEFF+1] = 0.0
		    Memr[savefit+GS_SAVECOEFF+2] = (ymax - ymin) / 2.0
		}
		call gsfree (sf1)
		call gsrestore (sf1, Memr[savefit])
	        sf2 = NULL

	    case GM_XYSCALE:
	        call gsinit (sf1, GM_FUNCTION(fit), 1, 2, GS_XNONE, xmin,
	            xmax, ymin, ymax)
	        call gsfit (sf1, x, y, z, wts, npts, WTS_USER, ier)
	        sf2 = NULL

	    default:
	        call gsinit (sf1, GM_FUNCTION(fit), 2, 2, GS_XNONE, xmin,
	            xmax, ymin, ymax)
		call gsset (sf1, GSXREF, GM_XO(fit))
		call gsset (sf1, GSYREF, GM_YO(fit))
		call gsset (sf1, GSZREF, GM_ZO(fit))
	        call gsfit (sf1, x, y, z, wts, npts, WTS_USER, ier)
	        if (GM_YXORDER(fit) > 2 || GM_YYORDER(fit) > 2 ||
	            GM_YXTERMS(fit) == GS_XFULL)
	            call gsinit (sf2, GM_FUNCTION(fit), GM_YXORDER(fit),
	                GM_YYORDER(fit), GM_YXTERMS(fit), xmin, xmax, ymin,
			ymax)
	        else 
	            sf2 = NULL

	    }

	}


	if (ier == NO_DEG_FREEDOM) {
	    call sfree (sp)
	    if (xfit == YES) {
		if (GM_PROJECTION(fit) == GM_NONE) {
	            call sprintf (errmsg, maxch,
		        "Too few data points for X fit.")
	            call error (1, "Too few data points for X fit.")
		} else {
	            call sprintf (errmsg, maxch,
		        "Too few data points for XI fit.")
	            call error (1, "Too few data points for XI fit.")
		}
	    } else {
		if (GM_PROJECTION(fit) == GM_NONE) {
	            call sprintf (errmsg, maxch,
		        "Too few data points for Y fit.")
	            call error (1, "Too few data points for Y fit.")
		} else {
	            call sprintf (errmsg, maxch,
		        "Too few data points for ETA fit.")
	            call error (1, "Too few data points for ETA fit.")
		}
	    }
	} else if (ier == SINGULAR) {
	    if (xfit == YES) {
		if (GM_PROJECTION(fit) == GM_NONE)
	            call sprintf (errmsg, maxch, "Warning singular X fit.")
		else
	            call sprintf (errmsg, maxch, "Warning singular XI fit.")
	    } else {
		if (GM_PROJECTION(fit) == GM_NONE)
		    call sprintf (errmsg, maxch, "Warning singular Y fit.")
		else
		    call sprintf (errmsg, maxch, "Warning singular ETA fit.")
	    }
	} else {
	    if (xfit == YES) {
		if (GM_PROJECTION(fit) == GM_NONE)
		    call sprintf (errmsg, maxch, "X fit ok.")
		else
		    call sprintf (errmsg, maxch, "XI fit ok.")
	    } else {
		if (GM_PROJECTION(fit) == GM_NONE)
		    call sprintf (errmsg, maxch, "Y fit ok.")
		else
		    call sprintf (errmsg, maxch, "ETA fit ok.")
	    }
	}

	call gsvector (sf1, x, y, resid, npts)
	call asubr (z, resid, resid, npts)

	# Calculate higher order fit.
	if (sf2 != NULL) {
	    call gsfit (sf2, x, y, resid, wts, npts, WTS_USER, ier)
	    if (ier == NO_DEG_FREEDOM) {
		call sfree (sp)
		if (xfit == YES) {
		    if (GM_PROJECTION(fit) == GM_NONE) {
		       call sprintf (errmsg, maxch,
		           "Too few data points for X fit.")
		       call error (1, "Too few data points for X fit.")
		    } else {
		       call sprintf (errmsg, maxch,
		           "Too few data points for XI fit.")
		       call error (1, "Too few data points for XI fit.")
		    }
		} else {
		    if (GM_PROJECTION(fit) == GM_NONE) {
		       call sprintf (errmsg, maxch,
		           "Too few data points for Y fit.")
			call error (1, "Too few data points for Y fit.")
		    } else {
		       call sprintf (errmsg, maxch,
		           "Too few data points for ETA fit.")
			call error (1, "Too few data points for ETA fit.")
		    }
		}
	    } else if (ier == SINGULAR) {
		if (xfit == YES) {
		    if (GM_PROJECTION(fit) == GM_NONE)
		        call sprintf (errmsg, maxch, "Warning singular X fit.")
		    else
		        call sprintf (errmsg, maxch, "Warning singular XI fit.")
		} else {
		    if (GM_PROJECTION(fit) == GM_NONE)
		        call sprintf (errmsg, maxch, "Warning singular Y fit.")
		    else
		        call sprintf (errmsg, maxch,
			    "Warning singular ETA fit.")
		}
	    } else {
		if (xfit == YES) {
		    if (GM_PROJECTION(fit) == GM_NONE)
		        call sprintf (errmsg, maxch, "X fit ok.")
		    else
		        call sprintf (errmsg, maxch, "XI fit ok.")
		} else {
		    if (GM_PROJECTION(fit) == GM_NONE)
		        call sprintf (errmsg, maxch, "Y fit ok.")
		    else
		        call sprintf (errmsg, maxch, "ETA fit ok.")
		}
	    }
	    call gsvector (sf2, x, y, Memr[zfit], npts)
	    call asubr (resid, Memr[zfit], resid, npts)
	}

	# Compute the number of zero weighted points.
	GM_NWTS0(fit) = 0
	do i = 1, npts {
	    if (wts[i] <= real(0.0))
	        GM_NWTS0(fit) = GM_NWTS0(fit) + 1
	}

	# calculate the rms of the fit
	if (xfit == YES) {
	    GM_XRMS(fit) = 0.0d0
	    do i = 1, npts
	        GM_XRMS(fit) = GM_XRMS(fit) + wts[i] * resid[i] ** 2
	} else {
	    GM_YRMS(fit) = 0.0d0
	    do i = 1, npts
		GM_YRMS(fit) = GM_YRMS(fit) + wts[i] * resid[i] ** 2
	}

	GM_NPTS(fit) = npts

	call sfree (sp)
end


# GEO_MREJECT -- Reject points from the fit.

procedure geo_mrejectr (fit, sx1, sy1, sx2, sy2, xref, yref, xin, yin, wts,
        xresid, yresid, npts, xerrmsg, xmaxch, yerrmsg, ymaxch) 

pointer	fit		#I pointer to the fit structure
pointer	sx1, sy1	#I pointers to the linear surface
pointer sx2, sy2	#I pointers to the higher order surface
real	xref[npts]	#I reference image x values
real	yref[npts]	#I yreference values
real	xin[npts]	#I x values
real	yin[npts]	#I yvalues
real	wts[npts]	#I weights
real	xresid[npts]	#I residuals
real	yresid[npts]	#I yresiduals
int	npts		#I number of data points
char	xerrmsg[ARB]	#O the output x error message
int	xmaxch		#I maximum number of characters in the x error message
char	yerrmsg[ARB]	#O the output y error message
int	ymaxch		#I maximum number of characters in the y error message

int	i
int	nreject, niter
pointer	sp, twts
real	cutx, cuty
errchk	geo_fxyr(), geo_fthetar(), geo_fmagnifyr(), geo_flinearr()

begin
	# Allocate working space.
	call smark (sp)
	call salloc (twts, npts, TY_REAL)

	# Allocate space for the residuals.
	if (GM_REJ(fit) != NULL)
	    call mfree (GM_REJ(fit), TY_INT)
	call malloc (GM_REJ(fit), npts, TY_INT)
	GM_NREJECT(fit) = 0

	# Initialize the temporary weights array and the number of rejected
	# points.
	call amovr (wts, Memr[twts], npts)
	nreject = 0

	niter = 0
	repeat {

	    # Compute the rejection limits.
	    if ((npts - GM_NWTS0(fit)) > 1) {
	        cutx = GM_REJECT(fit) * sqrt (GM_XRMS(fit) / (npts -
	            GM_NWTS0(fit) - 1))
	        cuty = GM_REJECT(fit) * sqrt (GM_YRMS(fit) / (npts -
	            GM_NWTS0(fit) - 1))
	    } else {
	        cutx = MAX_REAL
	        cuty = MAX_REAL
	    }

	    # Reject points from the fit.
	    do i = 1, npts {
	        if (Memr[twts+i-1] > 0.0 && ((abs (xresid[i]) > cutx) ||
		    (abs (yresid[i]) > cuty))) {
		    Memr[twts+i-1] = real(0.0)
		    nreject = nreject + 1
		    Memi[GM_REJ(fit)+nreject-1] = i
	        }
	    }
	    if ((nreject - GM_NREJECT(fit)) <= 0)
		break
	    GM_NREJECT(fit) = nreject

	    # Compute number of deleted points.
	    GM_NWTS0(fit) = 0
	    do i = 1, npts {
		if (wts[i] <= 0.0)
		    GM_NWTS0(fit) = GM_NWTS0(fit) + 1
	    }

	    # Recompute the X and Y fit.
	    switch (GM_FIT(fit)) {
	    case GM_ROTATE:
	        call geo_fthetar (fit, sx1, sy1, xref, yref, xin, yin,
		    Memr[twts], xresid, yresid, npts, xerrmsg, xmaxch,
		    yerrmsg, ymaxch)
		    sx2 = NULL
		    sy2 = NULL
	    case GM_RSCALE:
	        call geo_fmagnifyr (fit, sx1, sy1, xref, yref, xin, yin,
		    Memr[twts], xresid, yresid, npts, xerrmsg, xmaxch,
		    yerrmsg, ymaxch)
		    sx2 = NULL
		    sy2 = NULL
	    case GM_RXYSCALE:
	        call geo_flinearr (fit, sx1, sy1, xref, yref, xin, yin,
		    Memr[twts], xresid, yresid, npts, xerrmsg, xmaxch,
		    yerrmsg, ymaxch)
		    sx2 = NULL
		    sy2 = NULL
	    default:
		GM_ZO(fit) = GM_XOREF(fit)
	        call geo_fxyr (fit, sx1, sx2, xref, yref, xin, Memr[twts],
	            xresid, npts, YES, xerrmsg, xmaxch)
		GM_ZO(fit) = GM_YOREF(fit)
	        call geo_fxyr (fit, sy1, sy2, xref, yref, yin, Memr[twts],
	            yresid, npts, NO, yerrmsg, ymaxch)
	    }

	    # Compute the x fit rms.
	    GM_XRMS(fit) = 0.0d0
	    do i = 1, npts
	        GM_XRMS(fit) = GM_XRMS(fit) + Memr[twts+i-1] * xresid[i] ** 2

	    # Compute the y fit rms.
	    GM_YRMS(fit) = 0.0d0
	    do i = 1, npts
	        GM_YRMS(fit) = GM_YRMS(fit) + Memr[twts+i-1] * yresid[i] ** 2

	    niter = niter + 1

	} until (niter >= GM_MAXITER(fit))

	call sfree (sp)
end


# GEO_MMFREE - Free the space used to fit the surfaces.

procedure geo_mmfreer (sx1, sy1, sx2, sy2)

pointer	sx1		#U pointer to the x fits
pointer	sy1		#U pointer to the y fit
pointer	sx2		#U pointer to the higher order x fit
pointer	sy2		#U pointer to the higher order y fit

begin
	if (sx1 != NULL)
	    call gsfree (sx1)
	if (sy1 != NULL)
	    call gsfree (sy1)
	if (sx2 != NULL)
	    call gsfree (sx2)
	if (sy2 != NULL)
	    call gsfree (sy2)
end



# GEO_FIT -- Fit the surface in batch.

procedure geo_fitd (fit, sx1, sy1, sx2, sy2, xref, yref, xin, yin, wts, npts,
	xerrmsg, yerrmsg, maxch)

pointer	fit		#I pointer to fitting structure
pointer	sx1, sy1	#U pointer to linear surface
pointer	sx2, sy2	#U pointer to higher order correction
double	xref[ARB]	#I x reference array
double	yref[ARB]	#I y reference array
double	xin[ARB]	#I x array
double	yin[ARB]	#I y array
double	wts[ARB]	#I weight array
int	npts		#I the number of data points
char	xerrmsg[ARB]	#O the x fit error message
char	yerrmsg[ARB]	#O the y fit error message
int	maxch		#I maximum size of the error message

pointer	sp, xresidual, yresidual
errchk	geo_fxyd(), geo_mrejectd(), geo_fthetad(), geo_fmagnifyd()
errchk	geo_flineard()

begin
	call smark (sp)
	call salloc (xresidual, npts, TY_DOUBLE)
	call salloc (yresidual, npts, TY_DOUBLE)

	switch (GM_FIT(fit)) {
	case GM_ROTATE:
	    call geo_fthetad (fit, sx1, sy1, xref, yref, xin, yin, wts,
	        Memd[xresidual], Memd[yresidual], npts, xerrmsg, maxch,
		yerrmsg, maxch)
		sx2 = NULL
		sy2 = NULL
	case GM_RSCALE:
	    call geo_fmagnifyd (fit, sx1, sy1, xref, yref, xin, yin, wts,
	        Memd[xresidual], Memd[yresidual], npts, xerrmsg, maxch,
		yerrmsg, maxch)
		sx2 = NULL
		sy2 = NULL
	case GM_RXYSCALE:
	    call geo_flineard (fit, sx1, sy1, xref, yref, xin, yin, wts,
	        Memd[xresidual], Memd[yresidual], npts, xerrmsg, maxch,
		yerrmsg, maxch)
		sx2 = NULL
		sy2 = NULL
	default:
	    GM_ZO(fit) = GM_XOREF(fit)
	    call geo_fxyd (fit, sx1, sx2, xref, yref, xin, wts,
	        Memd[xresidual], npts, YES, xerrmsg, maxch)
	    GM_ZO(fit) = GM_YOREF(fit)
	    call geo_fxyd (fit, sy1, sy2, xref, yref, yin, wts,
	        Memd[yresidual], npts, NO, yerrmsg, maxch)
	}
	if (GM_MAXITER(fit) <= 0 || IS_INDEFD(GM_REJECT(fit)))
	    GM_NREJECT(fit) = 0
	else
	    call geo_mrejectd (fit, sx1, sy1, sx2, sy2, xref, yref, xin, yin,
		wts, Memd[xresidual], Memd[yresidual], npts, xerrmsg,
		maxch, yerrmsg, maxch)

	call sfree (sp)
end


# GEO_FTHETA -- Compute the shift and rotation angle required to match one
# set of coordinates to another.

procedure geo_fthetad (fit, sx1, sy1, xref, yref, xin, yin, wts, xresid,
	yresid, npts, xerrmsg, xmaxch, yerrmsg, ymaxch)

pointer	fit		#I pointer to the fit sturcture
pointer	sx1		#U pointer to linear x fit surface
pointer	sy1		#U pointer to linear y fit surface
double	xref[npts]	#I reference image x values
double	yref[npts]	#I reference image y values
double	xin[npts]	#I input image x values
double	yin[npts]	#I input image y values
double	wts[npts]	#I array of weights
double	xresid[npts]	#O x fit residuals
double	yresid[npts]	#O y fit residuals
int	npts		#I number of points
char	xerrmsg[ARB]	#O returned x fit error message
int	xmaxch		#I maximum number of characters in x fit error message
char	yerrmsg[ARB]	#O returned y fit error message
int	ymaxch		#I maximum number of characters in y fit error message

int	i
double	sw, sxr, syr, sxi, syi, xr0, yr0, xi0, yi0
double	syrxi, sxryi, sxrxi, syryi, num, denom, theta, det 
double	ctheta, stheta, cthetax, sthetax, cthetay, sthetay
double	xmin, xmax, ymin, ymax
pointer	sp, savefit
bool	fp_equald()

begin
	# Allocate some working space
	call smark (sp)
	call salloc (savefit, GS_SAVECOEFF + 3, TY_DOUBLE)

	# Initialize the fit.
        if (sx1 != NULL)
            call dgsfree (sx1)
        if (sy1 != NULL)
            call dgsfree (sy1)

        # Determine the minimum and maximum values
        if (fp_equald (GM_XMIN(fit), GM_XMAX(fit))) {
            xmin = GM_XMIN(fit) - 0.5d0
            xmax = GM_XMAX(fit) + 0.5d0
        } else {
            xmin = GM_XMIN(fit)
            xmax = GM_XMAX(fit)
        }
        if (fp_equald (GM_YMIN(fit), GM_YMAX(fit))) {
            ymin = GM_YMIN(fit) - 0.5d0
            ymax = GM_YMAX(fit) + 0.5d0
        } else {
            ymin = GM_YMIN(fit)
            ymax = GM_YMAX(fit)
        }

	# Compute the sums required to determine the offsets.
	sw = 0.0d0
	sxr = 0.0d0
	syr = 0.0d0
	sxi = 0.0d0
	syi = 0.0d0
	do i = 1, npts {
	    sw = sw + wts[i]
	    sxr = sxr + wts[i] * xref[i]
	    syr = syr + wts[i] * yref[i]
	    sxi = sxi + wts[i] * xin[i]
	    syi = syi + wts[i] * yin[i]
	}

	# Do the fit.
	if (sw < 2) {
	    call sfree (sp)
	    if (GM_PROJECTION(fit) == GM_NONE) {
	        call sprintf (xerrmsg, xmaxch,
		    "Too few data points for X and Y fits.")
	        call sprintf (yerrmsg, ymaxch,
		    "Too few data points for X and Y fits.")
	        call error (1, "Too few data points for X and Y fits.")
	    } else {
	        call sprintf (xerrmsg, xmaxch,
		    "Too few data points for XI and ETA fits.")
	        call sprintf (yerrmsg, ymaxch,
		    "Too few data points for XI and ETA fits.")
	        call error (1, "Too few data points for XI and ETA fits.")
	    }

	} else {

	    # Compute the sums required to compute the rotation angle.
	    xr0 = sxr / sw
	    yr0 = syr / sw
	    xi0 = sxi / sw
	    yi0 = syi / sw
	    syrxi = 0.0d0
	    sxryi = 0.0d0
	    sxrxi = 0.0d0
	    syryi = 0.0d0
	    do i = 1, npts {
		syrxi = syrxi + wts[i] * (yref[i] - yr0) * (xin[i] - xi0)
		sxryi = sxryi + wts[i] * (xref[i] - xr0) * (yin[i] - yi0)
		sxrxi = sxrxi + wts[i] * (xref[i] - xr0) * (xin[i] - xi0)
		syryi = syryi + wts[i] * (yref[i] - yr0) * (yin[i] - yi0)
	    }

	    # Compute the rotation angle.
	    num = sxrxi * syryi
	    denom = syrxi * sxryi
	    if (fp_equald (num, denom))
		det = 0.0d0
	    else
		det = num - denom
	    if (det < 0.0d0) {
		num = syrxi + sxryi
	        denom = -sxrxi + syryi
	    } else {
	        num = syrxi - sxryi
	        denom = sxrxi + syryi
	    }
	    if (fp_equald (num, 0.0d0) && fp_equald (denom, 0.0d0)) {
		theta = 0.0d0
	        if (GM_PROJECTION(fit) == GM_NONE) {
	            call sprintf (xerrmsg, xmaxch, "Warning singular X fit.")
	            call sprintf (yerrmsg, ymaxch, "Warning singular Y fit.")
		} else {
	            call sprintf (xerrmsg, xmaxch, "Warning singular XI fit.")
	            call sprintf (yerrmsg, ymaxch, "Warning singular ETA fit.")
		}
	    } else {
		theta = atan2 (num, denom)
		if (theta < 0.0d0)
		    theta = theta + TWOPI
	        if (GM_PROJECTION(fit) == GM_NONE) {
		    call sprintf (xerrmsg, xmaxch, "X fit ok.")
		    call sprintf (yerrmsg, ymaxch, "Y fit ok.")
		} else {
		    call sprintf (xerrmsg, xmaxch, "XI fit ok.")
		    call sprintf (yerrmsg, ymaxch, "ETA fit ok.")
		}
	    }

	    # Compute the polynomial coefficients.
	    ctheta = cos (theta)
	    stheta = sin (theta)
	    if (det < 0.0d0) {
	        cthetax = -ctheta
	        sthetay = -stheta
	    } else {
	        cthetax = ctheta
	        sthetay = stheta
	    }
	    sthetax = stheta
	    cthetay = ctheta

	    # Compute the x fit coefficients.
	    call dgsinit (sx1, GM_FUNCTION(fit), 2, 2, GS_XNONE, xmin, xmax,
	        ymin, ymax)
	    call dgssave (sx1, Memd[savefit])
	    call dgsfree (sx1)
	    if (GM_FUNCTION(fit) == GS_POLYNOMIAL) {
	        Memd[savefit+GS_SAVECOEFF] = xi0 - (xr0 * cthetax + yr0 *
		    sthetax)
	        Memd[savefit+GS_SAVECOEFF+1] = cthetax
	        Memd[savefit+GS_SAVECOEFF+2] = sthetax
	    } else {
	        Memd[savefit+GS_SAVECOEFF] = xi0 - (xr0 * cthetax + yr0 *
		    sthetax) + cthetax * (xmax + xmin) / 2.0 + sthetax * 
		    (ymin + ymax) / 2.0
	        Memd[savefit+GS_SAVECOEFF+1] = cthetax * (xmax - xmin) / 2.0
	        Memd[savefit+GS_SAVECOEFF+2] = sthetax * (ymax - ymin) / 2.0
	    }
	    call dgsrestore (sx1, Memd[savefit])

	    # Compute the y fit coefficients.
	    call dgsinit (sy1, GM_FUNCTION(fit), 2, 2, GS_XNONE, xmin, xmax,
	        ymin, ymax)
	    call dgssave (sy1, Memd[savefit])
	    call dgsfree (sy1)
	    if (GM_FUNCTION(fit) == GS_POLYNOMIAL) {
	        Memd[savefit+GS_SAVECOEFF] = yi0 - (-xr0 * sthetay + yr0 *
		    cthetay)
	        Memd[savefit+GS_SAVECOEFF+1] = -sthetay
	        Memd[savefit+GS_SAVECOEFF+2] = cthetay
	    } else {
	        Memd[savefit+GS_SAVECOEFF] = yi0 - (-xr0 * sthetay + yr0 *
		    cthetay) - sthetay * (xmax + xmin) / 2.0 + cthetay *
		    (ymin + ymax) / 2.0
	        Memd[savefit+GS_SAVECOEFF+1] = -sthetay * (xmax - xmin) / 2.0
	        Memd[savefit+GS_SAVECOEFF+2] = cthetay * (ymax - ymin) / 2.0
	    }
	    call dgsrestore (sy1, Memd[savefit])

	    # Compute the residuals
	    call dgsvector (sx1, xref, yref, xresid, npts)
	    call dgsvector (sy1, xref, yref, yresid, npts)
	    call asubd (xin, xresid, xresid, npts) 
	    call asubd (yin, yresid, yresid, npts) 

            # Compute the number of zero weighted points.
            GM_NWTS0(fit) = 0
            do i = 1, npts {
                if (wts[i] <= double(0.0))
                    GM_NWTS0(fit) = GM_NWTS0(fit) + 1
            }

            # Compute the rms of the x and y fits.
            GM_XRMS(fit) = 0.0d0
            do i = 1, npts
                GM_XRMS(fit) = GM_XRMS(fit) + wts[i] * xresid[i] ** 2
            GM_YRMS(fit) = 0.0d0
            do i = 1, npts
                GM_YRMS(fit) = GM_YRMS(fit) + wts[i] * yresid[i] ** 2

            GM_NPTS(fit) = npts

	}

        call sfree (sp)
end


# GEO_FMAGNIFY -- Compute the shift, the rotation angle, and the magnification
# factor which is assumed to be the same in x and y, required to match one
# set of coordinates to another.

procedure geo_fmagnifyd (fit, sx1, sy1, xref, yref, xin, yin, wts, xresid,
	yresid, npts, xerrmsg, xmaxch, yerrmsg, ymaxch)

pointer	fit		#I pointer to the fit sturcture
pointer	sx1		#U pointer to linear x fit surface
pointer	sy1		#U pointer to linear y fit surface
double	xref[npts]	#I reference image x values
double	yref[npts]	#I reference image y values
double	xin[npts]	#I input image x values
double	yin[npts]	#I input image y values
double	wts[npts]	#I array of weights
double	xresid[npts]	#O x fit residuals
double	yresid[npts]	#O y fit residuals
int	npts		#I number of points
char	xerrmsg[ARB]	#O returned x fit error message
int	xmaxch		#I maximum number of characters in x fit error message
char	yerrmsg[ARB]	#O returned y fit error message
int	ymaxch		#I maximum number of characters in y fit error message

int	i
double	sw, sxr, syr, sxi, syi, xr0, yr0, xi0, yi0
double	syrxi, sxryi, sxrxi, syryi, sxrxr, syryr, num, denom, det, theta
double	mag, ctheta, stheta, cthetax, sthetax, cthetay, sthetay
double	xmin, xmax, ymin, ymax
pointer	sp, savefit
bool	fp_equald()

begin
	# Allocate some working space
	call smark (sp)
	call salloc (savefit, GS_SAVECOEFF + 3, TY_DOUBLE)

	# Initialize the fit.
        if (sx1 != NULL)
            call dgsfree (sx1)
        if (sy1 != NULL)
            call dgsfree (sy1)

        # Determine the minimum and maximum values.
        if (fp_equald (GM_XMIN(fit), GM_XMAX(fit))) {
            xmin = GM_XMIN(fit) - 0.5d0
            xmax = GM_XMAX(fit) + 0.5d0
        } else {
            xmin = GM_XMIN(fit)
            xmax = GM_XMAX(fit)
        }
        if (fp_equald (GM_YMIN(fit), GM_YMAX(fit))) {
            ymin = GM_YMIN(fit) - 0.5d0
            ymax = GM_YMAX(fit) + 0.5d0
        } else {
            ymin = GM_YMIN(fit)
            ymax = GM_YMAX(fit)
        }

	# Compute the sums required to determine the offsets.
	sw = 0.0d0
	sxr = 0.0d0
	syr = 0.0d0
	sxi = 0.0d0
	syi = 0.0d0
	do i = 1, npts {
	    sw = sw + wts[i]
	    sxr = sxr + wts[i] * xref[i]
	    syr = syr + wts[i] * yref[i]
	    sxi = sxi + wts[i] * xin[i]
	    syi = syi + wts[i] * yin[i]
	}

	# Do the fit.
	if (sw < 2) {
	    call sfree (sp)
	    if (GM_PROJECTION(fit) == GM_NONE) {
	        call sprintf (xerrmsg, xmaxch,
		    "Too few data points for X and Y fits.")
	        call sprintf (yerrmsg, ymaxch,
		    "Too few data points for X and Y fits.")
	        call error (1, "Too few data points for X and Y fits.")
	    } else {
	        call sprintf (xerrmsg, xmaxch,
		    "Too few data points for XI and ETA fits.")
	        call sprintf (yerrmsg, ymaxch,
		    "Too few data points for XI and ETA fits.")
	        call error (1, "Too few data points for XI and ETA fits.")
	    }
	} else {

	    # Compute the sums.
	    xr0 = sxr / sw
	    yr0 = syr / sw
	    xi0 = sxi / sw
	    yi0 = syi / sw
	    sxrxr = 0.0d0
	    syryr = 0.0d0
	    syrxi = 0.0d0
	    sxryi = 0.0d0
	    sxrxi = 0.0d0
	    syryi = 0.0d0
	    do i = 1, npts {
		sxrxr = sxrxr + wts[i] * (xref[i] - xr0) * (xref[i] - xr0)
		syryr = syryr + wts[i] * (yref[i] - yr0) * (yref[i] - yr0)
		syrxi = syrxi + wts[i] * (yref[i] - yr0) * (xin[i] - xi0)
		sxryi = sxryi + wts[i] * (xref[i] - xr0) * (yin[i] - yi0)
		sxrxi = sxrxi + wts[i] * (xref[i] - xr0) * (xin[i] - xi0)
		syryi = syryi + wts[i] * (yref[i] - yr0) * (yin[i] - yi0)
	    }

	    # Compute the rotation angle.
	    num = sxrxi * syryi
	    denom = syrxi * sxryi
	    if (fp_equald (num, denom))
		det = 0.0d0
	    else
		det = num - denom
	    if (det < 0.0d0) {
		num = syrxi + sxryi
	        denom = -sxrxi + syryi
	    } else {
	        num = syrxi - sxryi
	        denom = sxrxi + syryi
	    }
	    if (fp_equald (num, 0.0d0) && fp_equald (denom, 0.0d0)) {
		theta = 0.0d0
	        if (GM_PROJECTION(fit) == GM_NONE) {
	            call sprintf (xerrmsg, xmaxch, "Warning singular X fit.")
	            call sprintf (yerrmsg, ymaxch, "Warning singular Y fit.")
		} else {
	            call sprintf (xerrmsg, xmaxch, "Warning singular XI fit.")
	            call sprintf (yerrmsg, ymaxch, "Warning singular ETA fit.")
		}
	    } else {
		theta = atan2 (num, denom)
		if (theta < 0.0d0)
		    theta = theta + TWOPI
	        if (GM_PROJECTION(fit) == GM_NONE) {
		    call sprintf (xerrmsg, xmaxch, "X fit ok.")
		    call sprintf (yerrmsg, ymaxch, "Y fit ok.")
		} else {
		    call sprintf (xerrmsg, xmaxch, "XI fit ok.")
		    call sprintf (yerrmsg, ymaxch, "ETA fit ok.")
		}
	    }

	    # Compute the magnification factor.
	    ctheta = cos (theta)
	    stheta = sin (theta)
	    num = denom * ctheta + num * stheta
	    denom = sxrxr + syryr
	    if (denom <= 0.0d0) {
		mag = 1.0 
	        if (GM_PROJECTION(fit) == GM_NONE) {
	            call sprintf (xerrmsg, xmaxch, "Warning singular X fit.")
	            call sprintf (yerrmsg, ymaxch, "Warning singular Y fit.")
		} else {
	            call sprintf (xerrmsg, xmaxch, "Warning singular XI fit.")
	            call sprintf (yerrmsg, ymaxch, "Warning singular ETA fit.")
		}
	    } else {
		mag = num / denom
	        if (GM_PROJECTION(fit) == GM_NONE) {
		    call sprintf (xerrmsg, xmaxch, "X fit ok.")
		    call sprintf (yerrmsg, ymaxch, "Y fit ok.")
		} else {
		    call sprintf (xerrmsg, xmaxch, "XI fit ok.")
		    call sprintf (yerrmsg, ymaxch, "ETA fit ok.")
		}
	    }

	    # Compute the polynomial coefficients.
	    if (det < 0.0d0) {
	        cthetax = -mag * ctheta
	        sthetay = -mag * stheta
	    } else {
	        cthetax = mag * ctheta
	        sthetay = mag * stheta
	    }
	    sthetax = mag * stheta
	    cthetay = mag * ctheta

	    # Compute the x fit coefficients.
	    call dgsinit (sx1, GM_FUNCTION(fit), 2, 2, GS_XNONE, xmin, xmax,
	        ymin, ymax)
	    call dgssave (sx1, Memd[savefit])
	    call dgsfree (sx1)
	    if (GM_FUNCTION(fit) == GS_POLYNOMIAL) {
	        Memd[savefit+GS_SAVECOEFF] = xi0 - (xr0 * cthetax + yr0 *
		    sthetax)
	        Memd[savefit+GS_SAVECOEFF+1] = cthetax
	        Memd[savefit+GS_SAVECOEFF+2] = sthetax
	    } else {
	        Memd[savefit+GS_SAVECOEFF] = xi0 - (xr0 * cthetax + yr0 *
		    sthetax) + cthetax * (xmax + xmin) / 2.0 + sthetax * 
		    (ymin + ymax) / 2.0
	        Memd[savefit+GS_SAVECOEFF+1] = cthetax * (xmax - xmin) / 2.0
	        Memd[savefit+GS_SAVECOEFF+2] = sthetax * (ymax - ymin) / 2.0
	    }
	    call dgsrestore (sx1, Memd[savefit])

	    # Compute the y fit coefficients.
	    call dgsinit (sy1, GM_FUNCTION(fit), 2, 2, GS_XNONE, xmin, xmax,
	        ymin, ymax)
	    call dgssave (sy1, Memd[savefit])
	    call dgsfree (sy1)
	    if (GM_FUNCTION(fit) == GS_POLYNOMIAL) {
	        Memd[savefit+GS_SAVECOEFF] = yi0 - (-xr0 * sthetay + yr0 *
		    cthetay)
	        Memd[savefit+GS_SAVECOEFF+1] = -sthetay
	        Memd[savefit+GS_SAVECOEFF+2] = cthetay
	    } else {
	        Memd[savefit+GS_SAVECOEFF] = yi0 - (-xr0 * sthetay + yr0 *
		    cthetay) - sthetay * (xmax + xmin) / 2.0 + cthetay *
		    (ymin + ymax) / 2.0
	        Memd[savefit+GS_SAVECOEFF+1] = -sthetay * (xmax - xmin) / 2.0
	        Memd[savefit+GS_SAVECOEFF+2] = cthetay * (ymax - ymin) / 2.0
	    }
	    call dgsrestore (sy1, Memd[savefit])

	    # Compute the residuals
	    call dgsvector (sx1, xref, yref, xresid, npts)
	    call dgsvector (sy1, xref, yref, yresid, npts)
	    call asubd (xin, xresid, xresid, npts) 
	    call asubd (yin, yresid, yresid, npts) 

            # Compute the number of zero weighted points.
            GM_NWTS0(fit) = 0
            do i = 1, npts {
                if (wts[i] <= double(0.0))
                    GM_NWTS0(fit) = GM_NWTS0(fit) + 1
            }

            # Compute the rms of the x and y fits.
            GM_XRMS(fit) = 0.0d0
            do i = 1, npts
                GM_XRMS(fit) = GM_XRMS(fit) + wts[i] * xresid[i] ** 2
            GM_YRMS(fit) = 0.0d0
            do i = 1, npts
                GM_YRMS(fit) = GM_YRMS(fit) + wts[i] * yresid[i] ** 2

            GM_NPTS(fit) = npts

	}

        call sfree (sp)
end


# GEO_FLINEAR -- Compute the shift, the rotation angle, and the x and y scale
# factors required to match one set of coordinates to another.

procedure geo_flineard (fit, sx1, sy1, xref, yref, xin, yin, wts, xresid,
	yresid, npts, xerrmsg, xmaxch, yerrmsg, ymaxch)

pointer	fit		#I pointer to the fit sturcture
pointer	sx1		#U pointer to linear x fit surface
pointer	sy1		#U pointer to linear y fit surface
double	xref[npts]	#I reference image x values
double	yref[npts]	#I reference image y values
double	xin[npts]	#I input image x values
double	yin[npts]	#I input image y values
double	wts[npts]	#I array of weights
double	xresid[npts]	#O x fit residuals
double	yresid[npts]	#O y fit residuals
int	npts		#I number of points
char	xerrmsg[ARB]	#O returned x fit error message
int	xmaxch		#I maximum number of characters in x fit error message
char	yerrmsg[ARB]	#O returned y fit error message
int	ymaxch		#I maximum number of characters in y fit error message

int	i
double	sw, sxr, syr, sxi, syi, xr0, yr0, xi0, yi0
double	syrxi, sxryi, sxrxi, syryi, sxrxr, syryr, num, denom, theta
double	xmag, ymag, ctheta, stheta, cthetax, sthetax, cthetay, sthetay
double	xmin, xmax, ymin, ymax
pointer	sp, savefit
bool	fp_equald()

begin
	# Allocate some working space
	call smark (sp)
	call salloc (savefit, GS_SAVECOEFF + 3, TY_DOUBLE)

	# Initialize the fit.
        if (sx1 != NULL)
            call dgsfree (sx1)
        if (sy1 != NULL)
            call dgsfree (sy1)

        # Determine the minimum and maximum values.
        if (fp_equald (GM_XMIN(fit), GM_XMAX(fit))) {
            xmin = GM_XMIN(fit) - 0.5d0
            xmax = GM_XMAX(fit) + 0.5d0
        } else {
            xmin = GM_XMIN(fit)
            xmax = GM_XMAX(fit)
        }
        if (fp_equald (GM_YMIN(fit), GM_YMAX(fit))) {
            ymin = GM_YMIN(fit) - 0.5d0
            ymax = GM_YMAX(fit) + 0.5d0
        } else {
            ymin = GM_YMIN(fit)
            ymax = GM_YMAX(fit)
        }

	# Compute the sums required to determine the offsets.
	sw = 0.0d0
	sxr = 0.0d0
	syr = 0.0d0
	sxi = 0.0d0
	syi = 0.0d0
	do i = 1, npts {
	    sw = sw + wts[i]
	    sxr = sxr + wts[i] * xref[i]
	    syr = syr + wts[i] * yref[i]
	    sxi = sxi + wts[i] * xin[i]
	    syi = syi + wts[i] * yin[i]
	}

	# Do the fit.
	if (sw < 3) {
	    call sfree (sp)
	    if (GM_PROJECTION(fit) == GM_NONE) {
	        call sprintf (xerrmsg, xmaxch,
		    "Too few data points for X and Y fits.")
	        call sprintf (yerrmsg, ymaxch,
		    "Too few data points for X and Y fits.")
	        call error (1, "Too few data points for X and Y fits.")
	    } else {
	        call sprintf (xerrmsg, xmaxch,
		    "Too few data points for XI and ETA fits.")
	        call sprintf (yerrmsg, ymaxch,
		    "Too few data points for XI and ETA fits.")
	        call error (1, "Too few data points for XI and ETA fits.")
	    }
	} else {
	    xr0 = sxr / sw
	    yr0 = syr / sw
	    xi0 = sxi / sw
	    yi0 = syi / sw
	    sxrxr = 0.0d0
	    syryr = 0.0d0
	    syrxi = 0.0d0
	    sxryi = 0.0d0
	    sxrxi = 0.0d0
	    syryi = 0.0d0
	    do i = 1, npts {
		sxrxr = sxrxr + wts[i] * (xref[i] - xr0) * (xref[i] - xr0)
		syryr = syryr + wts[i] * (yref[i] - yr0) * (yref[i] - yr0)
		syrxi = syrxi + wts[i] * (yref[i] - yr0) * (xin[i] - xi0)
		sxryi = sxryi + wts[i] * (xref[i] - xr0) * (yin[i] - yi0)
		sxrxi = sxrxi + wts[i] * (xref[i] - xr0) * (xin[i] - xi0)
		syryi = syryi + wts[i] * (yref[i] - yr0) * (yin[i] - yi0)
	    }

	    # Compute the rotation angle.
	    num = 2.0d0 * (sxrxr * syrxi * syryi - syryr * sxrxi * sxryi)
	    denom = syryr * (sxrxi - sxryi) * (sxrxi + sxryi) - sxrxr *
	        (syrxi + syryi) * (syrxi - syryi) 
	    if (fp_equald (num, 0.0d0) && fp_equald (denom, 0.0d0)) {
		theta = 0.0d0
	        if (GM_PROJECTION(fit) == GM_NONE) {
	            call sprintf (xerrmsg, xmaxch, "Warning singular X fit.")
	            call sprintf (yerrmsg, ymaxch, "Warning singular Y fit.")
		} else {
	            call sprintf (xerrmsg, xmaxch, "Warning singular XI fit.")
	            call sprintf (yerrmsg, ymaxch, "Warning singular ETA fit.")
		}
	    } else {
		theta = atan2 (num, denom) / 2.0d0
		if (theta < 0.0d0)
		    theta = theta + TWOPI
	        if (GM_PROJECTION(fit) == GM_NONE) {
		    call sprintf (xerrmsg, xmaxch, "X fit ok.")
		    call sprintf (yerrmsg, ymaxch, "Y fit ok.")
		} else {
		    call sprintf (xerrmsg, xmaxch, "XI fit ok.")
		    call sprintf (yerrmsg, ymaxch, "ETA fit ok.")
		}
	    }
	    ctheta = cos (theta)
	    stheta = sin (theta)

	    # Compute the x magnification factor.
	    num = sxrxi * ctheta - sxryi * stheta
	    denom = sxrxr
	    if (denom <= 0.0d0) {
		xmag = 1.0 
	        if (GM_PROJECTION(fit) == GM_NONE) {
	            call sprintf (xerrmsg, xmaxch, "Warning singular X fit.")
	            call sprintf (yerrmsg, ymaxch, "Warning singular Y fit.")
		} else {
	            call sprintf (xerrmsg, xmaxch, "Warning singular XI fit.")
	            call sprintf (yerrmsg, ymaxch, "Warning singular ETA fit.")
		}
	    } else {
		xmag = num / denom
	        if (GM_PROJECTION(fit) == GM_NONE) {
		    call sprintf (xerrmsg, xmaxch, "X fit ok.")
		    call sprintf (yerrmsg, ymaxch, "Y fit ok.")
		} else {
		    call sprintf (xerrmsg, xmaxch, "XI fit ok.")
		    call sprintf (yerrmsg, ymaxch, "ETA fit ok.")
		}
	    }

	    # Compute the y magnification factor.
	    num = syrxi * stheta + syryi * ctheta
	    denom = syryr
	    if (denom <= 0.0d0) {
		ymag = 1.0 
	        if (GM_PROJECTION(fit) == GM_NONE) {
	            call sprintf (xerrmsg, xmaxch, "Warning singular X fit.")
	            call sprintf (yerrmsg, ymaxch, "Warning singular Y fit.")
		} else {
	            call sprintf (xerrmsg, xmaxch, "Warning singular XI fit.")
	            call sprintf (yerrmsg, ymaxch, "Warning singular ETA fit.")
		}
	    } else {
		ymag = num / denom
	        if (GM_PROJECTION(fit) == GM_NONE) {
		    call sprintf (xerrmsg, xmaxch, "X fit ok.")
		    call sprintf (yerrmsg, ymaxch, "Y fit ok.")
		} else {
		    call sprintf (xerrmsg, xmaxch, "XI fit ok.")
		    call sprintf (yerrmsg, ymaxch, "ETA fit ok.")
		}
	    }

	    # Compute the polynomial coefficients.
	    cthetax = xmag * ctheta
	    sthetax = ymag * stheta
	    sthetay = xmag * stheta
	    cthetay = ymag * ctheta

	    # Compute the x fit coefficients.
	    call dgsinit (sx1, GM_FUNCTION(fit), 2, 2, GS_XNONE, xmin, xmax,
	        ymin, ymax)
	    call dgssave (sx1, Memd[savefit])
	    call dgsfree (sx1)
	    if (GM_FUNCTION(fit) == GS_POLYNOMIAL) {
	        Memd[savefit+GS_SAVECOEFF] = xi0 - (xr0 * cthetax + yr0 *
		    sthetax)
	        Memd[savefit+GS_SAVECOEFF+1] = cthetax
	        Memd[savefit+GS_SAVECOEFF+2] = sthetax
	    } else {
	        Memd[savefit+GS_SAVECOEFF] = xi0 - (xr0 * cthetax + yr0 *
		    sthetax) + cthetax * (xmax + xmin) / 2.0 + sthetax * 
		    (ymin + ymax) / 2.0
	        Memd[savefit+GS_SAVECOEFF+1] = cthetax * (xmax - xmin) / 2.0
	        Memd[savefit+GS_SAVECOEFF+2] = sthetax * (ymax - ymin) / 2.0
	    }
	    call dgsrestore (sx1, Memd[savefit])

	    # Compute the y fit coefficients.
	    call dgsinit (sy1, GM_FUNCTION(fit), 2, 2, GS_XNONE, xmin, xmax,
	        ymin, ymax)
	    call dgssave (sy1, Memd[savefit])
	    call dgsfree (sy1)
	    if (GM_FUNCTION(fit) == GS_POLYNOMIAL) {
	        Memd[savefit+GS_SAVECOEFF] = yi0 - (-xr0 * sthetay + yr0 *
		    cthetay)
	        Memd[savefit+GS_SAVECOEFF+1] = -sthetay
	        Memd[savefit+GS_SAVECOEFF+2] = cthetay
	    } else {
	        Memd[savefit+GS_SAVECOEFF] = yi0 - (-xr0 * sthetay + yr0 *
		    cthetay) - sthetay * (xmax + xmin) / 2.0 + cthetay *
		    (ymin + ymax) / 2.0
	        Memd[savefit+GS_SAVECOEFF+1] = -sthetay * (xmax - xmin) / 2.0
	        Memd[savefit+GS_SAVECOEFF+2] = cthetay * (ymax - ymin) / 2.0
	    }
	    call dgsrestore (sy1, Memd[savefit])

	    # Compute the residuals
	    call dgsvector (sx1, xref, yref, xresid, npts)
	    call dgsvector (sy1, xref, yref, yresid, npts)
	    call asubd (xin, xresid, xresid, npts) 
	    call asubd (yin, yresid, yresid, npts) 

            # Compute the number of zero weighted points.
            GM_NWTS0(fit) = 0
            do i = 1, npts {
                if (wts[i] <= double(0.0))
                    GM_NWTS0(fit) = GM_NWTS0(fit) + 1
            }

            # Compute the rms of the x and y fits.
            GM_XRMS(fit) = 0.0d0
            do i = 1, npts
                GM_XRMS(fit) = GM_XRMS(fit) + wts[i] * xresid[i] ** 2
            GM_YRMS(fit) = 0.0d0
            do i = 1, npts
                GM_YRMS(fit) = GM_YRMS(fit) + wts[i] * yresid[i] ** 2

            GM_NPTS(fit) = npts

	}

        call sfree (sp)
end


# GEO_FXY -- Fit the surface.

procedure geo_fxyd (fit, sf1, sf2, x, y, z, wts, resid, npts, xfit, errmsg,
	maxch)

pointer	fit		#I pointer to the fit sturcture
pointer	sf1		#U pointer to linear surface
pointer	sf2		#U pointer to higher order surface
double	x[npts]		#I reference image x values
double	y[npts]		#I reference image y values
double	z[npts]	        #I z values 
double	wts[npts]	#I array of weights
double	resid[npts]	#O fitted residuals
int	npts		#I number of points
int	xfit		#I X fit ?
char	errmsg[ARB]	#O returned error message
int	maxch		#I maximum number of characters in error message

int	i, ier, ncoeff
pointer	sp, zfit, savefit, coeff
double	xmin, xmax, ymin, ymax
bool	fp_equald()

begin
	# Allocate working space.
	call smark (sp)
	call salloc (zfit, npts, TY_DOUBLE)
	call salloc (savefit, GS_SAVECOEFF + 3, TY_DOUBLE)
	call salloc (coeff, 3, TY_DOUBLE)

	# Determine the minimum and maximum values
	if (fp_equald (GM_XMIN(fit), GM_XMAX(fit))) {
	    xmin = GM_XMIN(fit) - 0.5d0
	    xmax = GM_XMAX(fit) + 0.5d0
	} else {
	    xmin = GM_XMIN(fit)
	    xmax = GM_XMAX(fit)
	}
	if (fp_equald (GM_YMIN(fit), GM_YMAX(fit))) {
	    ymin = GM_YMIN(fit) - 0.5d0
	    ymax = GM_YMAX(fit) + 0.5d0
	} else {
	    ymin = GM_YMIN(fit)
	    ymax = GM_YMAX(fit)
	}

	# Initalize fit
	if (sf1 != NULL)
	    call dgsfree (sf1)
	if (sf2 != NULL)
	    call dgsfree (sf2)

	if (xfit == YES) {

	    switch (GM_FIT(fit)) {

	    case GM_SHIFT:
	        call dgsinit (sf1, GM_FUNCTION(fit), 2, 2, GS_XNONE, xmin, xmax,
	            ymin, ymax)
		call dgssave (sf1, Memd[savefit])
		call dgsfree (sf1)
	        call dgsinit (sf1, GM_FUNCTION(fit), 1, 1, GS_XNONE, xmin, xmax,
	            ymin, ymax)
		call asubd (z, x, Memd[zfit], npts)
	        call dgsfit (sf1, x, y, Memd[zfit], wts, npts, WTS_USER, ier)
		call dgscoeff (sf1, Memd[coeff], ncoeff)
		if (GM_FUNCTION(fit) == GS_POLYNOMIAL) {
		    Memd[savefit+GS_SAVECOEFF] = Memd[coeff]
		    Memd[savefit+GS_SAVECOEFF+1] = 1.0d0
		    Memd[savefit+GS_SAVECOEFF+2] = 0.0d0
		} else {
		    Memd[savefit+GS_SAVECOEFF] = Memd[coeff] + (xmax + xmin) /
			2.0d0
		    Memd[savefit+GS_SAVECOEFF+1] = (xmax - xmin) / 2.0d0
		    Memd[savefit+GS_SAVECOEFF+2] = 0.0d0
		}
		call dgsfree (sf1)
		call dgsrestore (sf1, Memd[savefit])
	        sf2 = NULL

	    case GM_XYSCALE:
	        call dgsinit (sf1, GM_FUNCTION(fit), 2, 1, GS_XNONE, xmin, xmax,
	            ymin, ymax)
	        call dgsfit (sf1, x, y, z, wts, npts, WTS_USER, ier)
		sf2 = NULL

	    default:
	        call dgsinit (sf1, GM_FUNCTION(fit), 2, 2, GS_XNONE, xmin, xmax,
	            ymin, ymax)
		call dgsset (sf1, GSXREF, GM_XO(fit))
		call dgsset (sf1, GSYREF, GM_YO(fit))
		call dgsset (sf1, GSZREF, GM_ZO(fit))
	        call dgsfit (sf1, x, y, z, wts, npts, WTS_USER, ier)
	        if (GM_XXORDER(fit) > 2 || GM_XYORDER(fit) > 2 ||
		    GM_XXTERMS(fit) == GS_XFULL)
	            call dgsinit (sf2, GM_FUNCTION(fit), GM_XXORDER(fit),
		        GM_XYORDER(fit), GM_XXTERMS(fit), xmin, xmax, ymin,
			ymax)
	        else 
	            sf2 = NULL
	    }

	} else {

	    switch (GM_FIT(fit)) {

	    case GM_SHIFT:
	        call dgsinit (sf1, GM_FUNCTION(fit), 2, 2, GS_XNONE, xmin, xmax,
	            ymin, ymax)
		call dgssave (sf1, Memd[savefit])
		call dgsfree (sf1)
	        call dgsinit (sf1, GM_FUNCTION(fit), 1, 1, GS_XNONE, xmin, xmax,
	            ymin, ymax)
		call asubd (z, y, Memd[zfit], npts)
	        call dgsfit (sf1, x, y, Memd[zfit], wts, npts, WTS_USER, ier)
		call dgscoeff (sf1, Memd[coeff], ncoeff)
		if (GM_FUNCTION(fit) == GS_POLYNOMIAL) {
		    Memd[savefit+GS_SAVECOEFF] = Memd[coeff]
		    Memd[savefit+GS_SAVECOEFF+1] = 0.0d0
		    Memd[savefit+GS_SAVECOEFF+2] = 1.0d0
		} else {
		    Memd[savefit+GS_SAVECOEFF] = Memd[coeff] + (ymin + ymax) /
			2.0d0
		    Memd[savefit+GS_SAVECOEFF+1] = 0.0d0
		    Memd[savefit+GS_SAVECOEFF+2] = (ymax - ymin) / 2.0d0
		}
		call dgsfree (sf1)
		call dgsrestore (sf1, Memd[savefit])
	        sf2 = NULL

	    case GM_XYSCALE:
	        call dgsinit (sf1, GM_FUNCTION(fit), 1, 2, GS_XNONE, xmin, xmax,
	            ymin, ymax)
	        call dgsfit (sf1, x, y, z, wts, npts, WTS_USER, ier)
		sf2 = NULL

	    default:
	        call dgsinit (sf1, GM_FUNCTION(fit), 2, 2, GS_XNONE, xmin, xmax,
	            ymin, ymax)
		call dgsset (sf1, GSXREF, GM_XO(fit))
		call dgsset (sf1, GSYREF, GM_YO(fit))
		call dgsset (sf1, GSZREF, GM_ZO(fit))
	        call dgsfit (sf1, x, y, z, wts, npts, WTS_USER, ier)
	        if (GM_YXORDER(fit) > 2 || GM_YYORDER(fit) > 2 ||
	            GM_YXTERMS(fit) == GS_XFULL)
	            call dgsinit (sf2, GM_FUNCTION(fit), GM_YXORDER(fit),
	                GM_YYORDER(fit), GM_YXTERMS(fit), xmin, xmax, ymin,
			ymax)
	        else 
	            sf2 = NULL
	    }
	}


	if (ier == NO_DEG_FREEDOM) {
	    call sfree (sp)
	    if (xfit == YES) {
		if (GM_PROJECTION(fit) == GM_NONE) {
	            call sprintf (errmsg, maxch,
		        "Too few data points for X fit.")
	            call error (1, "Too few data points for X fit.")
		} else {
	            call sprintf (errmsg, maxch,
		        "Too few data points for XI fit.")
	            call error (1, "Too few data points for XI fit.")
		}
	    } else {
		if (GM_PROJECTION(fit) == GM_NONE) {
	            call sprintf (errmsg, maxch,
		        "Too few data points for Y fit.")
	            call error (1, "Too few data points for Y fit.")
		} else {
	            call sprintf (errmsg, maxch,
		        "Too few data points for ETA fit.")
	            call error (1, "Too few data points for ETA fit.")
		}
	    }
	} else if (ier == SINGULAR) {
	    if (xfit == YES) {
		if (GM_PROJECTION(fit) == GM_NONE)
	            call sprintf (errmsg, maxch, "Warning singular X fit.")
		else
	            call sprintf (errmsg, maxch, "Warning singular XI fit.")
	    } else {
		if (GM_PROJECTION(fit) == GM_NONE)
		    call sprintf (errmsg, maxch, "Warning singular Y fit.")
		else
		    call sprintf (errmsg, maxch, "Warning singular ETA fit.")
	    }
	} else {
	    if (xfit == YES) {
		if (GM_PROJECTION(fit) == GM_NONE)
		    call sprintf (errmsg, maxch, "X fit ok.")
		else
		    call sprintf (errmsg, maxch, "XI fit ok.")
	    } else {
		if (GM_PROJECTION(fit) == GM_NONE)
		    call sprintf (errmsg, maxch, "Y fit ok.")
		else
		    call sprintf (errmsg, maxch, "ETA fit ok.")
	    }
	}

	call dgsvector (sf1, x, y, resid, npts)
	call asubd (z, resid, resid, npts)

	# Calculate higher order fit.
	if (sf2 != NULL) {
	    call dgsfit (sf2, x, y, resid, wts, npts, WTS_USER, ier)
	    if (ier == NO_DEG_FREEDOM) {
		call sfree (sp)
		if (xfit == YES) {
		    if (GM_PROJECTION(fit) == GM_NONE) {
		       call sprintf (errmsg, maxch,
		           "Too few data points for X fit.")
		       call error (1, "Too few data points for X fit.")
		    } else {
		       call sprintf (errmsg, maxch,
		           "Too few data points for XI fit.")
		       call error (1, "Too few data points for XI fit.")
		    }
		} else {
		    if (GM_PROJECTION(fit) == GM_NONE) {
		       call sprintf (errmsg, maxch,
		           "Too few data points for Y fit.")
			call error (1, "Too few data points for Y fit.")
		    } else {
		       call sprintf (errmsg, maxch,
		           "Too few data points for ETA fit.")
			call error (1, "Too few data points for ETA fit.")
		    }
		}
	    } else if (ier == SINGULAR) {
		if (xfit == YES) {
		    if (GM_PROJECTION(fit) == GM_NONE)
		        call sprintf (errmsg, maxch, "Warning singular X fit.")
		    else
		        call sprintf (errmsg, maxch, "Warning singular XI fit.")
		} else {
		    if (GM_PROJECTION(fit) == GM_NONE)
		        call sprintf (errmsg, maxch, "Warning singular Y fit.")
		    else
		        call sprintf (errmsg, maxch,
			    "Warning singular ETA fit.")
		}
	    } else {
		if (xfit == YES) {
		    if (GM_PROJECTION(fit) == GM_NONE)
		        call sprintf (errmsg, maxch, "X fit ok.")
		    else
		        call sprintf (errmsg, maxch, "XI fit ok.")
		} else {
		    if (GM_PROJECTION(fit) == GM_NONE)
		        call sprintf (errmsg, maxch, "Y fit ok.")
		    else
		        call sprintf (errmsg, maxch, "ETA fit ok.")
		}
	    }
	    call dgsvector (sf2, x, y, Memd[zfit], npts)
	    call asubd (resid, Memd[zfit], resid, npts)
	}

	# Compute the number of zero weighted points.
	GM_NWTS0(fit) = 0
	do i = 1, npts {
	    if (wts[i] <= double(0.0))
	        GM_NWTS0(fit) = GM_NWTS0(fit) + 1
	}

	# calculate the rms of the fit
	if (xfit == YES) {
	    GM_XRMS(fit) = 0.0d0
	    do i = 1, npts
	        GM_XRMS(fit) = GM_XRMS(fit) + wts[i] * resid[i] ** 2
	} else {
	    GM_YRMS(fit) = 0.0d0
	    do i = 1, npts
		GM_YRMS(fit) = GM_YRMS(fit) + wts[i] * resid[i] ** 2
	}

	GM_NPTS(fit) = npts

	call sfree (sp)
end


# GEO_MREJECT -- Reject points from the fit.

procedure geo_mrejectd (fit, sx1, sy1, sx2, sy2, xref, yref, xin, yin, wts,
        xresid, yresid, npts, xerrmsg, xmaxch, yerrmsg, ymaxch) 

pointer	fit		#I pointer to the fit structure
pointer	sx1, sy1	#I pointers to the linear surface
pointer sx2, sy2	#I pointers to the higher order surface
double	xref[npts]	#I reference image x values
double	yref[npts]	#I yreference values
double	xin[npts]	#I x values
double	yin[npts]	#I yvalues
double	wts[npts]	#I weights
double	xresid[npts]	#I residuals
double	yresid[npts]	#I yresiduals
int	npts		#I number of data points
char	xerrmsg[ARB]	#O the output x error message
int	xmaxch		#I maximum number of characters in the x error message
char	yerrmsg[ARB]	#O the output y error message
int	ymaxch		#I maximum number of characters in the y error message

int	i
int	nreject, niter
pointer	sp, twts
double	cutx, cuty
errchk	geo_fxyd(), geo_fthetad(), geo_fmagnifyd(), geo_flineard()

begin
	# Allocate working space.
	call smark (sp)
	call salloc (twts, npts, TY_DOUBLE)

	# Allocate space for the residuals.
	if (GM_REJ(fit) != NULL)
	    call mfree (GM_REJ(fit), TY_INT)
	call malloc (GM_REJ(fit), npts, TY_INT)
	GM_NREJECT(fit) = 0

	# Initialize the temporary weights array and the number of rejected
	# points.
	call amovd (wts, Memd[twts], npts)
	nreject = 0

	niter = 0
	repeat {

	    # Compute the rejection limits.
	    if ((npts - GM_NWTS0(fit)) > 1) {
	        cutx = GM_REJECT(fit) * sqrt (GM_XRMS(fit) / (npts -
	            GM_NWTS0(fit) - 1))
	        cuty = GM_REJECT(fit) * sqrt (GM_YRMS(fit) / (npts -
	            GM_NWTS0(fit) - 1))
	    } else {
	        cutx = MAX_REAL
	        cuty = MAX_REAL
	    }

	    # Reject points from the fit.
	    do i = 1, npts {
	        if (Memd[twts+i-1] > 0.0 && ((abs (xresid[i]) > cutx) ||
		    (abs (yresid[i]) > cuty))) {
		    Memd[twts+i-1] = double(0.0)
		    nreject = nreject + 1
		    Memi[GM_REJ(fit)+nreject-1] = i
	        }
	    }
	    if ((nreject - GM_NREJECT(fit)) <= 0)
		break
	    GM_NREJECT(fit) = nreject

	    # Compute number of deleted points.
	    GM_NWTS0(fit) = 0
	    do i = 1, npts {
		if (wts[i] <= 0.0)
		    GM_NWTS0(fit) = GM_NWTS0(fit) + 1
	    }

	    # Recompute the X and Y fit.
	    switch (GM_FIT(fit)) {
	    case GM_ROTATE:
	        call geo_fthetad (fit, sx1, sy1, xref, yref, xin, yin,
		    Memd[twts], xresid, yresid, npts, xerrmsg, xmaxch,
		    yerrmsg, ymaxch)
		    sx2 = NULL
		    sy2 = NULL
	    case GM_RSCALE:
	        call geo_fmagnifyd (fit, sx1, sy1, xref, yref, xin, yin,
		    Memd[twts], xresid, yresid, npts, xerrmsg, xmaxch,
		    yerrmsg, ymaxch)
		    sx2 = NULL
		    sy2 = NULL
	    case GM_RXYSCALE:
	        call geo_flineard (fit, sx1, sy1, xref, yref, xin, yin,
		    Memd[twts], xresid, yresid, npts, xerrmsg, xmaxch,
		    yerrmsg, ymaxch)
		    sx2 = NULL
		    sy2 = NULL
	    default:
		GM_ZO(fit) = GM_XOREF(fit)
	        call geo_fxyd (fit, sx1, sx2, xref, yref, xin, Memd[twts],
	            xresid, npts, YES, xerrmsg, xmaxch)
		GM_ZO(fit) = GM_YOREF(fit)
	        call geo_fxyd (fit, sy1, sy2, xref, yref, yin, Memd[twts],
	            yresid, npts, NO, yerrmsg, ymaxch)
	    }

	    # Compute the x fit rms.
	    GM_XRMS(fit) = 0.0d0
	    do i = 1, npts
	        GM_XRMS(fit) = GM_XRMS(fit) + Memd[twts+i-1] * xresid[i] ** 2

	    # Compute the y fit rms.
	    GM_YRMS(fit) = 0.0d0
	    do i = 1, npts
	        GM_YRMS(fit) = GM_YRMS(fit) + Memd[twts+i-1] * yresid[i] ** 2

	    niter = niter + 1

	} until (niter >= GM_MAXITER(fit))

	call sfree (sp)
end


# GEO_MMFREE - Free the space used to fit the surfaces.

procedure geo_mmfreed (sx1, sy1, sx2, sy2)

pointer	sx1		#U pointer to the x fits
pointer	sy1		#U pointer to the y fit
pointer	sx2		#U pointer to the higher order x fit
pointer	sy2		#U pointer to the higher order y fit

begin
	if (sx1 != NULL)
	    call dgsfree (sx1)
	if (sy1 != NULL)
	    call dgsfree (sy1)
	if (sx2 != NULL)
	    call dgsfree (sx2)
	if (sy2 != NULL)
	    call dgsfree (sy2)
end


