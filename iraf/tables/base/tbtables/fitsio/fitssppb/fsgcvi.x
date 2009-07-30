include "fitsio.h"

procedure fsgcvi(iunit,colnum,frow,felem,nelem,nulval,array,
         anynul,status)

# read an array of I*2 values from a specified column of the table.
# Any undefined pixels will be set equal to the value of NULVAL,
# unless NULVAL=0, in which case no checks for undefined pixels
# will be made.

int     iunit           # i input file pointer
int     colnum          # i column number
long	frow            # i first row
long	felem           # i first element in row
long	nelem           # i number of elements
short   nulval          # i value for undefined pixels
short   array[ARB]      # o array of values
bool    anynul          # o any null values?
int     status          # o error status

int	i_frow
int	i_felem
int	i_nelem

begin
	i_frow = frow
	i_felem = felem
	i_nelem = nelem
	call ftgcvi(iunit,colnum,i_frow,i_felem,i_nelem,nulval,array,
		    anynul,status)
end
