# Copyright(c) 1986 Association of Universities for Research in Astronomy Inc.

include	"ki.h"

# KS_AWRITE -- Write to the kernel server device driver given the node
# descriptor of a kernel server channel.  If the error bit is set on the
# node return error w/o doing any i/o, since the channel will have been closed.

procedure ks_awrite (server, buf, nbytes)

int	server			# node descriptor index of server
char	buf[ARB]		# i/o buffer
size_t	nbytes			# nbytes to write

long	c_0
int	and()
include	"kinode.com"

begin
	c_0 = 0
	if (and (n_status[server], F_IOERR) == 0)
	    call zawrks (n_kschan[server], buf, nbytes, c_0)
end
