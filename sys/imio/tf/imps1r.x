# Copyright(c) 1986 Association of Universities for Research in Astronomy Inc.

include	<imhdr.h>

# IMPS1? -- Put a section to an apparently one dimensional image.

pointer procedure imps1r (im, x1, x2)

pointer	im		# image header pointer
int	x1		# first column
int	x2		# last column

pointer	impgsr(), impl1r()

begin
	if (x1 == 1 && x2 == IM_LEN(im,1))
	    return (impl1r (im))
	else
	    return (impgsr (im, long(x1), long(x2), 1))
end
