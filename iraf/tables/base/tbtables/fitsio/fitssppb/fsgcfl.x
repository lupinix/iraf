include "fitsio.h"

procedure fsgcfl(iunit,colnum,frow,felem,nelem,lray,
          flgval,anynul,status)

# read an array of logical values from a specified column of the table.
# The binary table column being read from must have datatype 'L'
# and no datatype conversion will be perform if it is not.

int     iunit           # i input file pointer
int     colnum          # i column number
long	frow            # i first row
long	felem           # i first element in row
long	nelem           # i number of elements
bool    lray[ARB]       # o logical array
bool    flgval[ARB]     # o is corresponding value undefined?
bool    anynul          # o any null values?
int     status          # o error status

int	i_frow
int	i_felem
int	i_nelem

begin
	i_frow = frow
	i_felem = felem
	i_nelem = nelem

	call ftgcfl(iunit,colnum,i_frow,i_felem,i_nelem,lray,
		    flgval,anynul,status)
end
