include "nlfitdef.h"
include "../lib/nlfit.h"

# NLSOLVE -- Procedure to solve nonlinear system

procedure nlsolve (nl, ier)

pointer	nl	# pointer to the nlfit structure
int	ier	# error code

int	nfree

begin
	# Make temporary arrays.
	call amovr (ALPHA(NL_ALPHA(nl)), COVAR(NL_COVAR(nl)),
	    NL_NFPARAMS(nl) ** 2)
	call amovr (BETA(NL_BETA(nl)), DPARAM(NL_DPARAM(nl)), NL_NFPARAMS(nl))

	# Add the lambda damping factor.
	call nl_damp (COVAR(NL_COVAR(nl)), COVAR(NL_COVAR(nl)),
	    (1.0 + NL_LAMBDA(nl)), NL_NFPARAMS(nl), NL_NFPARAMS(nl))

	ier = OK
	nfree = NL_NPTS(nl) - NL_NFPARAMS(nl)
	if (nfree < 0) {
	    ier = NO_DEG_FREEDOM
	    return
	}

	# Compute the factorization of the matrix.
	call nl_chofac (COVAR(NL_COVAR(nl)), NL_NFPARAMS(nl), NL_NFPARAMS(nl),
	    CHOFAC(NL_CHOFAC(nl)), ier)

	# Solve the equations for the parameter increments.
	call nl_choslv (CHOFAC(NL_CHOFAC(nl)), NL_NFPARAMS(nl), NL_NFPARAMS(nl),
	    DPARAM(NL_DPARAM(nl)), DPARAM(NL_DPARAM(nl)))
end