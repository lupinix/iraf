# Copyright(c) 1986 Association of Universities for Research in Astronomy Inc.

include	<plset.h>
include	<imhdr.h>
include	<imio.h>

# IMCSSZ -- Compute size of buffer needed to hold the section defined
# by the logical vectors VS and VE.  If type conversion is needed,
# must allow space for whichever pixel is largest.  If subsampling is
# in use (step size greater than one), must allow extra space for the
# unsampled data.

long procedure imcssz (im, vs, ve, ndim, dtype, npix, rwflag)

pointer	im			# image descriptor
long	vs[ARB], ve[ARB]	# endpoints of section
int	ndim			# dimensionality of section
int	dtype			# datatype of pixels in section
size_t	npix			# number of pixels in section (output)
int	rwflag			# section is to be read or written

long	step, npix_per_line, extra_pix, buf_size
int	i, sz_pixel
long	labs()
include	<szdtype.inc>

begin
	sz_pixel = max (ty_size[IM_PIXTYPE(im)], ty_size[dtype])
	
	if (IM_VMAP(im,1) == 1)
	    step = labs (IM_VSTEP(im,1))
	else
	    step = 1

	# Compute the total number of pixels in the subraster.

	npix_per_line = labs (ve[1] - vs[1]) + 1
	npix = npix_per_line

	for (i=2;  i <= ndim;  i=i+1)
	    npix = npix * (labs (ve[i] - vs[i]) + 1)

	# If the sample step size is greater than one, but less than
	# IM_MAXSTEP, allow extra space for the final unsampled line.
	# If not subsampling, and the buffer is for writing, add extra
	# space so that writes can be an integral number of device
	# blocks in size.

	extra_pix = 0
	if (step != 1) {
	    if (step <= IM_MAXSTEP && rwflag == IM_READ)
		extra_pix = (step - 1) * npix_per_line
	} else if (rwflag == IM_WRITE)
	    extra_pix = (IM_PHYSLEN(im,1) - IM_SVLEN(im,1))

	# If accessing a mask image with range list i/o, the maximum size
	# range list may be larger than the size of an image line in pixels.
	# Allow some extra space to permit such range lists to be read in
	# without buffer overflow; a runtime error is still possible if the
	# subraster contains multiple lines, and an individual range list
	# exceeds the length of the line in which it must be stored.

	if (and (IM_PLFLAGS(im), PL_RLIO) != 0)
	    extra_pix = max (extra_pix, RL_LENMAX(IM_PL(im)) - npix_per_line)

	buf_size = (npix + extra_pix) * sz_pixel	# size buf, chars

	return (buf_size)
end
