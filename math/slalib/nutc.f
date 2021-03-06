      SUBROUTINE slNUTC (DATE, DPSI, DEPS, EPS0)
*+
*     - - - - -
*      N U T C
*     - - - - -
*
*  Nutation:  longitude & obliquity components and mean obliquity,
*  using the Shirai & Fukushima (2001) theory.
*
*  Given:
*     DATE        d    TDB (loosely ET) as Modified Julian Date
*                                            (JD-2400000.5)
*  Returned:
*     DPSI,DEPS   d    nutation in longitude,obliquity
*     EPS0        d    mean obliquity
*
*  Notes:
*
*  1  The routine predicts forced nutation (but not free core nutation)
*     plus corrections to the IAU 1976 precession model.
*
*  2  Earth attitude predictions made by combining the present nutation
*     model with IAU 1976 precession are accurate to 1 mas (with respect
*     to the ICRF) for a few decades around 2000.
*
*  3  The slNUTC80 routine is the equivalent of the present routine
*     but using the IAU 1980 nutation theory.  The older theory is less
*     accurate, leading to errors as large as 350 mas over the interval
*     1900-2100, mainly because of the error in the IAU 1976 precession.
*
*  References:
*
*     Shirai, T. & Fukushima, T., Astron.J. 121, 3270-3283 (2001).
*
*     Fukushima, T., Astron.Astrophys. 244, L11 (1991).
*
*     Simon, J. L., Bretagnon, P., Chapront, J., Chapront-Touze, M.,
*     Francou, G. & Laskar, J., Astron.Astrophys. 282, 663 (1994).
*
*  This revision:   24 November 2005
*
*  Copyright P.T.Wallace.  All rights reserved.
*
*  License:
*    This program is free software; you can redistribute it and/or modify
*    it under the terms of the GNU General Public License as published by
*    the Free Software Foundation; either version 2 of the License, or
*    (at your option) any later version.
*
*    This program is distributed in the hope that it will be useful,
*    but WITHOUT ANY WARRANTY; without even the implied warranty of
*    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
*    GNU General Public License for more details.
*
*    You should have received a copy of the GNU General Public License
*    along with this program (see SLA_CONDITIONS); if not, write to the
*    Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
*    Boston, MA  02110-1301  USA
*
*  Copyright (C) 1995 Association of Universities for Research in Astronomy Inc.
*-

      IMPLICIT NONE

      DOUBLE PRECISION DATE,DPSI,DEPS,EPS0

*  Degrees to radians
      DOUBLE PRECISION DD2R
      PARAMETER (DD2R=1.745329251994329576923691D-2)

*  Arc seconds to radians
      DOUBLE PRECISION DAS2R
      PARAMETER (DAS2R=4.848136811095359935899141D-6)

*  Arc seconds in a full circle
      DOUBLE PRECISION TURNAS
      PARAMETER (TURNAS=1296000D0)

*  Reference epoch (J2000), MJD
      DOUBLE PRECISION DJM0
      PARAMETER (DJM0=51544.5D0 )

*  Days per Julian century
      DOUBLE PRECISION DJC
      PARAMETER (DJC=36525D0)

      INTEGER I,J
      DOUBLE PRECISION T,EL,ELP,F,D,OM,VE,MA,JU,SA,THETA,C,S,DP,DE

*  Number of terms in the nutation model
      INTEGER NTERMS
      PARAMETER (NTERMS=194)

*  The SF2001 forced nutation model
      INTEGER NA(9,NTERMS)
      DOUBLE PRECISION PSI(4,NTERMS), EPS(4,NTERMS)

*  Coefficients of fundamental angles
      DATA ( ( NA(I,J), I=1,9 ), J=1,10 ) /
     :    0,   0,   0,   0,  -1,   0,   0,   0,   0,
     :    0,   0,   2,  -2,   2,   0,   0,   0,   0,
     :    0,   0,   2,   0,   2,   0,   0,   0,   0,
     :    0,   0,   0,   0,  -2,   0,   0,   0,   0,
     :    0,   1,   0,   0,   0,   0,   0,   0,   0,
     :    0,   1,   2,  -2,   2,   0,   0,   0,   0,
     :    1,   0,   0,   0,   0,   0,   0,   0,   0,
     :    0,   0,   2,   0,   1,   0,   0,   0,   0,
     :    1,   0,   2,   0,   2,   0,   0,   0,   0,
     :    0,  -1,   2,  -2,   2,   0,   0,   0,   0 /
      DATA ( ( NA(I,J), I=1,9 ), J=11,20 ) /
     :    0,   0,   2,  -2,   1,   0,   0,   0,   0,
     :   -1,   0,   2,   0,   2,   0,   0,   0,   0,
     :   -1,   0,   0,   2,   0,   0,   0,   0,   0,
     :    1,   0,   0,   0,   1,   0,   0,   0,   0,
     :    1,   0,   0,   0,  -1,   0,   0,   0,   0,
     :   -1,   0,   2,   2,   2,   0,   0,   0,   0,
     :    1,   0,   2,   0,   1,   0,   0,   0,   0,
     :   -2,   0,   2,   0,   1,   0,   0,   0,   0,
     :    0,   0,   0,   2,   0,   0,   0,   0,   0,
     :    0,   0,   2,   2,   2,   0,   0,   0,   0 /
      DATA ( ( NA(I,J), I=1,9 ), J=21,30 ) /
     :    2,   0,   0,  -2,   0,   0,   0,   0,   0,
     :    2,   0,   2,   0,   2,   0,   0,   0,   0,
     :    1,   0,   2,  -2,   2,   0,   0,   0,   0,
     :   -1,   0,   2,   0,   1,   0,   0,   0,   0,
     :    2,   0,   0,   0,   0,   0,   0,   0,   0,
     :    0,   0,   2,   0,   0,   0,   0,   0,   0,
     :    0,   1,   0,   0,   1,   0,   0,   0,   0,
     :   -1,   0,   0,   2,   1,   0,   0,   0,   0,
     :    0,   2,   2,  -2,   2,   0,   0,   0,   0,
     :    0,   0,   2,  -2,   0,   0,   0,   0,   0 /
      DATA ( ( NA(I,J), I=1,9 ), J=31,40 ) /
     :   -1,   0,   0,   2,  -1,   0,   0,   0,   0,
     :    0,   1,   0,   0,  -1,   0,   0,   0,   0,
     :    0,   2,   0,   0,   0,   0,   0,   0,   0,
     :   -1,   0,   2,   2,   1,   0,   0,   0,   0,
     :    1,   0,   2,   2,   2,   0,   0,   0,   0,
     :    0,   1,   2,   0,   2,   0,   0,   0,   0,
     :   -2,   0,   2,   0,   0,   0,   0,   0,   0,
     :    0,   0,   2,   2,   1,   0,   0,   0,   0,
     :    0,  -1,   2,   0,   2,   0,   0,   0,   0,
     :    0,   0,   0,   2,   1,   0,   0,   0,   0 /
      DATA ( ( NA(I,J), I=1,9 ), J=41,50 ) /
     :    1,   0,   2,  -2,   1,   0,   0,   0,   0,
     :    2,   0,   0,  -2,  -1,   0,   0,   0,   0,
     :    2,   0,   2,  -2,   2,   0,   0,   0,   0,
     :    2,   0,   2,   0,   1,   0,   0,   0,   0,
     :    0,   0,   0,   2,  -1,   0,   0,   0,   0,
     :    0,  -1,   2,  -2,   1,   0,   0,   0,   0,
     :   -1,  -1,   0,   2,   0,   0,   0,   0,   0,
     :    2,   0,   0,  -2,   1,   0,   0,   0,   0,
     :    1,   0,   0,   2,   0,   0,   0,   0,   0,
     :    0,   1,   2,  -2,   1,   0,   0,   0,   0 /
      DATA ( ( NA(I,J), I=1,9 ), J=51,60 ) /
     :    1,  -1,   0,   0,   0,   0,   0,   0,   0,
     :   -2,   0,   2,   0,   2,   0,   0,   0,   0,
     :    0,  -1,   0,   2,   0,   0,   0,   0,   0,
     :    3,   0,   2,   0,   2,   0,   0,   0,   0,
     :    0,   0,   0,   1,   0,   0,   0,   0,   0,
     :    1,  -1,   2,   0,   2,   0,   0,   0,   0,
     :    1,   0,   0,  -1,   0,   0,   0,   0,   0,
     :   -1,  -1,   2,   2,   2,   0,   0,   0,   0,
     :   -1,   0,   2,   0,   0,   0,   0,   0,   0,
     :    2,   0,   0,   0,  -1,   0,   0,   0,   0 /
      DATA ( ( NA(I,J), I=1,9 ), J=61,70 ) /
     :    0,  -1,   2,   2,   2,   0,   0,   0,   0,
     :    1,   1,   2,   0,   2,   0,   0,   0,   0,
     :    2,   0,   0,   0,   1,   0,   0,   0,   0,
     :    1,   1,   0,   0,   0,   0,   0,   0,   0,
     :    1,   0,  -2,   2,  -1,   0,   0,   0,   0,
     :    1,   0,   2,   0,   0,   0,   0,   0,   0,
     :   -1,   1,   0,   1,   0,   0,   0,   0,   0,
     :    1,   0,   0,   0,   2,   0,   0,   0,   0,
     :   -1,   0,   1,   0,   1,   0,   0,   0,   0,
     :    0,   0,   2,   1,   2,   0,   0,   0,   0 /
      DATA ( ( NA(I,J), I=1,9 ), J=71,80 ) /
     :   -1,   1,   0,   1,   1,   0,   0,   0,   0,
     :   -1,   0,   2,   4,   2,   0,   0,   0,   0,
     :    0,  -2,   2,  -2,   1,   0,   0,   0,   0,
     :    1,   0,   2,   2,   1,   0,   0,   0,   0,
     :    1,   0,   0,   0,  -2,   0,   0,   0,   0,
     :   -2,   0,   2,   2,   2,   0,   0,   0,   0,
     :    1,   1,   2,  -2,   2,   0,   0,   0,   0,
     :   -2,   0,   2,   4,   2,   0,   0,   0,   0,
     :   -1,   0,   4,   0,   2,   0,   0,   0,   0,
     :    2,   0,   2,  -2,   1,   0,   0,   0,   0 /
      DATA ( ( NA(I,J), I=1,9 ), J=81,90 ) /
     :    1,   0,   0,  -1,  -1,   0,   0,   0,   0,
     :    2,   0,   2,   2,   2,   0,   0,   0,   0,
     :    1,   0,   0,   2,   1,   0,   0,   0,   0,
     :    3,   0,   0,   0,   0,   0,   0,   0,   0,
     :    0,   0,   2,  -2,  -1,   0,   0,   0,   0,
     :    3,   0,   2,  -2,   2,   0,   0,   0,   0,
     :    0,   0,   4,  -2,   2,   0,   0,   0,   0,
     :   -1,   0,   0,   4,   0,   0,   0,   0,   0,
     :    0,   1,   2,   0,   1,   0,   0,   0,   0,
     :    0,   0,   2,  -2,   3,   0,   0,   0,   0 /
      DATA ( ( NA(I,J), I=1,9 ), J=91,100 ) /
     :   -2,   0,   0,   4,   0,   0,   0,   0,   0,
     :   -1,  -1,   0,   2,   1,   0,   0,   0,   0,
     :   -2,   0,   2,   0,  -1,   0,   0,   0,   0,
     :    0,   0,   2,   0,  -1,   0,   0,   0,   0,
     :    0,  -1,   2,   0,   1,   0,   0,   0,   0,
     :    0,   1,   0,   0,   2,   0,   0,   0,   0,
     :    0,   0,   2,  -1,   2,   0,   0,   0,   0,
     :    2,   1,   0,  -2,   0,   0,   0,   0,   0,
     :    0,   0,   2,   4,   2,   0,   0,   0,   0,
     :   -1,  -1,   0,   2,  -1,   0,   0,   0,   0 /
      DATA ( ( NA(I,J), I=1,9 ), J=101,110 ) /
     :   -1,   1,   0,   2,   0,   0,   0,   0,   0,
     :    1,  -1,   0,   0,   1,   0,   0,   0,   0,
     :    0,  -1,   2,  -2,   0,   0,   0,   0,   0,
     :    0,   1,   0,   0,  -2,   0,   0,   0,   0,
     :    1,  -1,   2,   2,   2,   0,   0,   0,   0,
     :    1,   0,   0,   2,  -1,   0,   0,   0,   0,
     :   -1,   1,   2,   2,   2,   0,   0,   0,   0,
     :    3,   0,   2,   0,   1,   0,   0,   0,   0,
     :    0,   1,   2,   2,   2,   0,   0,   0,   0,
     :    1,   0,   2,  -2,   0,   0,   0,   0,   0 /
      DATA ( ( NA(I,J), I=1,9 ), J=111,120 ) /
     :   -1,   0,  -2,   4,  -1,   0,   0,   0,   0,
     :   -1,  -1,   2,   2,   1,   0,   0,   0,   0,
     :    0,  -1,   2,   2,   1,   0,   0,   0,   0,
     :    2,  -1,   2,   0,   2,   0,   0,   0,   0,
     :    0,   0,   0,   2,   2,   0,   0,   0,   0,
     :    1,  -1,   2,   0,   1,   0,   0,   0,   0,
     :   -1,   1,   2,   0,   2,   0,   0,   0,   0,
     :    0,   1,   0,   2,   0,   0,   0,   0,   0,
     :    0,   1,   2,  -2,   0,   0,   0,   0,   0,
     :    0,   3,   2,  -2,   2,   0,   0,   0,   0 /
      DATA ( ( NA(I,J), I=1,9 ), J=121,130 ) /
     :    0,   0,   0,   1,   1,   0,   0,   0,   0,
     :   -1,   0,   2,   2,   0,   0,   0,   0,   0,
     :    2,   1,   2,   0,   2,   0,   0,   0,   0,
     :    1,   1,   0,   0,   1,   0,   0,   0,   0,
     :    2,   0,   0,   2,   0,   0,   0,   0,   0,
     :    1,   1,   2,   0,   1,   0,   0,   0,   0,
     :   -1,   0,   0,   2,   2,   0,   0,   0,   0,
     :    1,   0,  -2,   2,   0,   0,   0,   0,   0,
     :    0,  -1,   0,   2,  -1,   0,   0,   0,   0,
     :   -1,   0,   1,   0,   2,   0,   0,   0,   0 /
      DATA ( ( NA(I,J), I=1,9 ), J=131,140 ) /
     :    0,   1,   0,   1,   0,   0,   0,   0,   0,
     :    1,   0,  -2,   2,  -2,   0,   0,   0,   0,
     :    0,   0,   0,   1,  -1,   0,   0,   0,   0,
     :    1,  -1,   0,   0,  -1,   0,   0,   0,   0,
     :    0,   0,   0,   4,   0,   0,   0,   0,   0,
     :    1,  -1,   0,   2,   0,   0,   0,   0,   0,
     :    1,   0,   2,   1,   2,   0,   0,   0,   0,
     :    1,   0,   2,  -1,   2,   0,   0,   0,   0,
     :   -1,   0,   0,   2,  -2,   0,   0,   0,   0,
     :    0,   0,   2,   1,   1,   0,   0,   0,   0 /
      DATA ( ( NA(I,J), I=1,9 ), J=141,150 ) /
     :   -1,   0,   2,   0,  -1,   0,   0,   0,   0,
     :   -1,   0,   2,   4,   1,   0,   0,   0,   0,
     :    0,   0,   2,   2,   0,   0,   0,   0,   0,
     :    1,   1,   2,  -2,   1,   0,   0,   0,   0,
     :    0,   0,   1,   0,   1,   0,   0,   0,   0,
     :   -1,   0,   2,  -1,   1,   0,   0,   0,   0,
     :   -2,   0,   2,   2,   1,   0,   0,   0,   0,
     :    2,  -1,   0,   0,   0,   0,   0,   0,   0,
     :    4,   0,   2,   0,   2,   0,   0,   0,   0,
     :    2,   1,   2,  -2,   2,   0,   0,   0,   0 /
      DATA ( ( NA(I,J), I=1,9 ), J=151,160 ) /
     :    0,   1,   2,   1,   2,   0,   0,   0,   0,
     :    1,   0,   4,  -2,   2,   0,   0,   0,   0,
     :    1,   1,   0,   0,  -1,   0,   0,   0,   0,
     :   -2,   0,   2,   4,   1,   0,   0,   0,   0,
     :    2,   0,   2,   0,   0,   0,   0,   0,   0,
     :   -1,   0,   1,   0,   0,   0,   0,   0,   0,
     :    1,   0,   0,   1,   0,   0,   0,   0,   0,
     :    0,   1,   0,   2,   1,   0,   0,   0,   0,
     :   -1,   0,   4,   0,   1,   0,   0,   0,   0,
     :   -1,   0,   0,   4,   1,   0,   0,   0,   0 /
      DATA ( ( NA(I,J), I=1,9 ), J=161,170 ) /
     :    2,   0,   2,   2,   1,   0,   0,   0,   0,
     :    2,   1,   0,   0,   0,   0,   0,   0,   0,
     :    0,   0,   5,  -5,   5,  -3,   0,   0,   0,
     :    0,   0,   0,   0,   0,   0,   0,   2,   0,
     :    0,   0,   1,  -1,   1,   0,   0,  -1,   0,
     :    0,   0,  -1,   1,  -1,   1,   0,   0,   0,
     :    0,   0,  -1,   1,   0,   0,   2,   0,   0,
     :    0,   0,   3,  -3,   3,   0,   0,  -1,   0,
     :    0,   0,  -8,   8,  -7,   5,   0,   0,   0,
     :    0,   0,  -1,   1,  -1,   0,   2,   0,   0 /
      DATA ( ( NA(I,J), I=1,9 ), J=171,180 ) /
     :    0,   0,  -2,   2,  -2,   2,   0,   0,   0,
     :    0,   0,  -6,   6,  -6,   4,   0,   0,   0,
     :    0,   0,  -2,   2,  -2,   0,   8,  -3,   0,
     :    0,   0,   6,  -6,   6,   0,  -8,   3,   0,
     :    0,   0,   4,  -4,   4,  -2,   0,   0,   0,
     :    0,   0,  -3,   3,  -3,   2,   0,   0,   0,
     :    0,   0,   4,  -4,   3,   0,  -8,   3,   0,
     :    0,   0,  -4,   4,  -5,   0,   8,  -3,   0,
     :    0,   0,   0,   0,   0,   2,   0,   0,   0,
     :    0,   0,  -4,   4,  -4,   3,   0,   0,   0 /
      DATA ( ( NA(I,J), I=1,9 ), J=181,190 ) /
     :    0,   1,  -1,   1,  -1,   0,   0,   1,   0,
     :    0,   0,   0,   0,   0,   0,   0,   1,   0,
     :    0,   0,   1,  -1,   1,   1,   0,   0,   0,
     :    0,   0,   2,  -2,   2,   0,  -2,   0,   0,
     :    0,  -1,  -7,   7,  -7,   5,   0,   0,   0,
     :   -2,   0,   2,   0,   2,   0,   0,  -2,   0,
     :   -2,   0,   2,   0,   1,   0,   0,  -3,   0,
     :    0,   0,   2,  -2,   2,   0,   0,  -2,   0,
     :    0,   0,   1,  -1,   1,   0,   0,   1,   0,
     :    0,   0,   0,   0,   0,   0,   0,   0,   2 /
      DATA ( ( NA(I,J), I=1,9 ), J=191,NTERMS ) /
     :    0,   0,   0,   0,   0,   0,   0,   0,   1,
     :    2,   0,  -2,   0,  -2,   0,   0,   3,   0,
     :    0,   0,   1,  -1,   1,   0,   0,  -2,   0,
     :    0,   0,  -7,   7,  -7,   5,   0,   0,   0 /

*  Nutation series: longitude
      DATA ( ( PSI(I,J), I=1,4 ), J=1,10 ) /
     :  3341.5D0, 17206241.8D0,  3.1D0, 17409.5D0,
     : -1716.8D0, -1317185.3D0,  1.4D0,  -156.8D0,
     :   285.7D0,  -227667.0D0,  0.3D0,   -23.5D0,
     :   -68.6D0,  -207448.0D0,  0.0D0,   -21.4D0,
     :   950.3D0,   147607.9D0, -2.3D0,  -355.0D0,
     :   -66.7D0,   -51689.1D0,  0.2D0,   122.6D0,
     :  -108.6D0,    71117.6D0,  0.0D0,     7.0D0,
     :    35.6D0,   -38740.2D0,  0.1D0,   -36.2D0,
     :    85.4D0,   -30127.6D0,  0.0D0,    -3.1D0,
     :     9.0D0,    21583.0D0,  0.1D0,   -50.3D0 /
      DATA ( ( PSI(I,J), I=1,4 ), J=11,20 ) /
     :    22.1D0,    12822.8D0,  0.0D0,    13.3D0,
     :     3.4D0,    12350.8D0,  0.0D0,     1.3D0,
     :   -21.1D0,    15699.4D0,  0.0D0,     1.6D0,
     :     4.2D0,     6313.8D0,  0.0D0,     6.2D0,
     :   -22.8D0,     5796.9D0,  0.0D0,     6.1D0,
     :    15.7D0,    -5961.1D0,  0.0D0,    -0.6D0,
     :    13.1D0,    -5159.1D0,  0.0D0,    -4.6D0,
     :     1.8D0,     4592.7D0,  0.0D0,     4.5D0,
     :   -17.5D0,     6336.0D0,  0.0D0,     0.7D0,
     :    16.3D0,    -3851.1D0,  0.0D0,    -0.4D0 /
      DATA ( ( PSI(I,J), I=1,4 ), J=21,30 ) /
     :    -2.8D0,     4771.7D0,  0.0D0,     0.5D0,
     :    13.8D0,    -3099.3D0,  0.0D0,    -0.3D0,
     :     0.2D0,     2860.3D0,  0.0D0,     0.3D0,
     :     1.4D0,     2045.3D0,  0.0D0,     2.0D0,
     :    -8.6D0,     2922.6D0,  0.0D0,     0.3D0,
     :    -7.7D0,     2587.9D0,  0.0D0,     0.2D0,
     :     8.8D0,    -1408.1D0,  0.0D0,     3.7D0,
     :     1.4D0,     1517.5D0,  0.0D0,     1.5D0,
     :    -1.9D0,    -1579.7D0,  0.0D0,     7.7D0,
     :     1.3D0,    -2178.6D0,  0.0D0,    -0.2D0 /
      DATA ( ( PSI(I,J), I=1,4 ), J=31,40 ) /
     :    -4.8D0,     1286.8D0,  0.0D0,     1.3D0,
     :     6.3D0,     1267.2D0,  0.0D0,    -4.0D0,
     :    -1.0D0,     1669.3D0,  0.0D0,    -8.3D0,
     :     2.4D0,    -1020.0D0,  0.0D0,    -0.9D0,
     :     4.5D0,     -766.9D0,  0.0D0,     0.0D0,
     :    -1.1D0,      756.5D0,  0.0D0,    -1.7D0,
     :    -1.4D0,    -1097.3D0,  0.0D0,    -0.5D0,
     :     2.6D0,     -663.0D0,  0.0D0,    -0.6D0,
     :     0.8D0,     -714.1D0,  0.0D0,     1.6D0,
     :     0.4D0,     -629.9D0,  0.0D0,    -0.6D0 /
      DATA ( ( PSI(I,J), I=1,4 ), J=41,50 ) /
     :     0.3D0,      580.4D0,  0.0D0,     0.6D0,
     :    -1.6D0,      577.3D0,  0.0D0,     0.5D0,
     :    -0.9D0,      644.4D0,  0.0D0,     0.0D0,
     :     2.2D0,     -534.0D0,  0.0D0,    -0.5D0,
     :    -2.5D0,      493.3D0,  0.0D0,     0.5D0,
     :    -0.1D0,     -477.3D0,  0.0D0,    -2.4D0,
     :    -0.9D0,      735.0D0,  0.0D0,    -1.7D0,
     :     0.7D0,      406.2D0,  0.0D0,     0.4D0,
     :    -2.8D0,      656.9D0,  0.0D0,     0.0D0,
     :     0.6D0,      358.0D0,  0.0D0,     2.0D0 /
      DATA ( ( PSI(I,J), I=1,4 ), J=51,60 ) /
     :    -0.7D0,      472.5D0,  0.0D0,    -1.1D0,
     :    -0.1D0,     -300.5D0,  0.0D0,     0.0D0,
     :    -1.2D0,      435.1D0,  0.0D0,    -1.0D0,
     :     1.8D0,     -289.4D0,  0.0D0,     0.0D0,
     :     0.6D0,     -422.6D0,  0.0D0,     0.0D0,
     :     0.8D0,     -287.6D0,  0.0D0,     0.6D0,
     :   -38.6D0,     -392.3D0,  0.0D0,     0.0D0,
     :     0.7D0,     -281.8D0,  0.0D0,     0.6D0,
     :     0.6D0,     -405.7D0,  0.0D0,     0.0D0,
     :    -1.2D0,      229.0D0,  0.0D0,     0.2D0 /
      DATA ( ( PSI(I,J), I=1,4 ), J=61,70 ) /
     :     1.1D0,     -264.3D0,  0.0D0,     0.5D0,
     :    -0.7D0,      247.9D0,  0.0D0,    -0.5D0,
     :    -0.2D0,      218.0D0,  0.0D0,     0.2D0,
     :     0.6D0,     -339.0D0,  0.0D0,     0.8D0,
     :    -0.7D0,      198.7D0,  0.0D0,     0.2D0,
     :    -1.5D0,      334.0D0,  0.0D0,     0.0D0,
     :     0.1D0,      334.0D0,  0.0D0,     0.0D0,
     :    -0.1D0,     -198.1D0,  0.0D0,     0.0D0,
     :  -106.6D0,        0.0D0,  0.0D0,     0.0D0,
     :    -0.5D0,      165.8D0,  0.0D0,     0.0D0 /
      DATA ( ( PSI(I,J), I=1,4 ), J=71,80 ) /
     :     0.0D0,      134.8D0,  0.0D0,     0.0D0,
     :     0.9D0,     -151.6D0,  0.0D0,     0.0D0,
     :     0.0D0,     -129.7D0,  0.0D0,     0.0D0,
     :     0.8D0,     -132.8D0,  0.0D0,    -0.1D0,
     :     0.5D0,     -140.7D0,  0.0D0,     0.0D0,
     :    -0.1D0,      138.4D0,  0.0D0,     0.0D0,
     :     0.0D0,      129.0D0,  0.0D0,    -0.3D0,
     :     0.5D0,     -121.2D0,  0.0D0,     0.0D0,
     :    -0.3D0,      114.5D0,  0.0D0,     0.0D0,
     :    -0.1D0,      101.8D0,  0.0D0,     0.0D0 /
      DATA ( ( PSI(I,J), I=1,4 ), J=81,90 ) /
     :    -3.6D0,     -101.9D0,  0.0D0,     0.0D0,
     :     0.8D0,     -109.4D0,  0.0D0,     0.0D0,
     :     0.2D0,      -97.0D0,  0.0D0,     0.0D0,
     :    -0.7D0,      157.3D0,  0.0D0,     0.0D0,
     :     0.2D0,      -83.3D0,  0.0D0,     0.0D0,
     :    -0.3D0,       93.3D0,  0.0D0,     0.0D0,
     :    -0.1D0,       92.1D0,  0.0D0,     0.0D0,
     :    -0.5D0,      133.6D0,  0.0D0,     0.0D0,
     :    -0.1D0,       81.5D0,  0.0D0,     0.0D0,
     :     0.0D0,      123.9D0,  0.0D0,     0.0D0 /
      DATA ( ( PSI(I,J), I=1,4 ), J=91,100 ) /
     :    -0.3D0,      128.1D0,  0.0D0,     0.0D0,
     :     0.1D0,       74.1D0,  0.0D0,    -0.3D0,
     :    -0.2D0,      -70.3D0,  0.0D0,     0.0D0,
     :    -0.4D0,       66.6D0,  0.0D0,     0.0D0,
     :     0.1D0,      -66.7D0,  0.0D0,     0.0D0,
     :    -0.7D0,       69.3D0,  0.0D0,    -0.3D0,
     :     0.0D0,      -70.4D0,  0.0D0,     0.0D0,
     :    -0.1D0,      101.5D0,  0.0D0,     0.0D0,
     :     0.5D0,      -69.1D0,  0.0D0,     0.0D0,
     :    -0.2D0,       58.5D0,  0.0D0,     0.2D0 /
      DATA ( ( PSI(I,J), I=1,4 ), J=101,110 ) /
     :     0.1D0,      -94.9D0,  0.0D0,     0.2D0,
     :     0.0D0,       52.9D0,  0.0D0,    -0.2D0,
     :     0.1D0,       86.7D0,  0.0D0,    -0.2D0,
     :    -0.1D0,      -59.2D0,  0.0D0,     0.2D0,
     :     0.3D0,      -58.8D0,  0.0D0,     0.1D0,
     :    -0.3D0,       49.0D0,  0.0D0,     0.0D0,
     :    -0.2D0,       56.9D0,  0.0D0,    -0.1D0,
     :     0.3D0,      -50.2D0,  0.0D0,     0.0D0,
     :    -0.2D0,       53.4D0,  0.0D0,    -0.1D0,
     :     0.1D0,      -76.5D0,  0.0D0,     0.0D0 /
      DATA ( ( PSI(I,J), I=1,4 ), J=111,120 ) /
     :    -0.2D0,       45.3D0,  0.0D0,     0.0D0,
     :     0.1D0,      -46.8D0,  0.0D0,     0.0D0,
     :     0.2D0,      -44.6D0,  0.0D0,     0.0D0,
     :     0.2D0,      -48.7D0,  0.0D0,     0.0D0,
     :     0.1D0,      -46.8D0,  0.0D0,     0.0D0,
     :     0.1D0,      -42.0D0,  0.0D0,     0.0D0,
     :     0.0D0,       46.4D0,  0.0D0,    -0.1D0,
     :     0.2D0,      -67.3D0,  0.0D0,     0.1D0,
     :     0.0D0,      -65.8D0,  0.0D0,     0.2D0,
     :    -0.1D0,      -43.9D0,  0.0D0,     0.3D0 /
      DATA ( ( PSI(I,J), I=1,4 ), J=121,130 ) /
     :     0.0D0,      -38.9D0,  0.0D0,     0.0D0,
     :    -0.3D0,       63.9D0,  0.0D0,     0.0D0,
     :    -0.2D0,       41.2D0,  0.0D0,     0.0D0,
     :     0.0D0,      -36.1D0,  0.0D0,     0.2D0,
     :    -0.3D0,       58.5D0,  0.0D0,     0.0D0,
     :    -0.1D0,       36.1D0,  0.0D0,     0.0D0,
     :     0.0D0,      -39.7D0,  0.0D0,     0.0D0,
     :     0.1D0,      -57.7D0,  0.0D0,     0.0D0,
     :    -0.2D0,       33.4D0,  0.0D0,     0.0D0,
     :    36.4D0,        0.0D0,  0.0D0,     0.0D0 /
      DATA ( ( PSI(I,J), I=1,4 ), J=131,140 ) /
     :    -0.1D0,       55.7D0,  0.0D0,    -0.1D0,
     :     0.1D0,      -35.4D0,  0.0D0,     0.0D0,
     :     0.1D0,      -31.0D0,  0.0D0,     0.0D0,
     :    -0.1D0,       30.1D0,  0.0D0,     0.0D0,
     :    -0.3D0,       49.2D0,  0.0D0,     0.0D0,
     :    -0.2D0,       49.1D0,  0.0D0,     0.0D0,
     :    -0.1D0,       33.6D0,  0.0D0,     0.0D0,
     :     0.1D0,      -33.5D0,  0.0D0,     0.0D0,
     :     0.1D0,      -31.0D0,  0.0D0,     0.0D0,
     :    -0.1D0,       28.0D0,  0.0D0,     0.0D0 /
      DATA ( ( PSI(I,J), I=1,4 ), J=141,150 ) /
     :     0.1D0,      -25.2D0,  0.0D0,     0.0D0,
     :     0.1D0,      -26.2D0,  0.0D0,     0.0D0,
     :    -0.2D0,       41.5D0,  0.0D0,     0.0D0,
     :     0.0D0,       24.5D0,  0.0D0,     0.1D0,
     :   -16.2D0,        0.0D0,  0.0D0,     0.0D0,
     :     0.0D0,      -22.3D0,  0.0D0,     0.0D0,
     :     0.0D0,       23.1D0,  0.0D0,     0.0D0,
     :    -0.1D0,       37.5D0,  0.0D0,     0.0D0,
     :     0.2D0,      -25.7D0,  0.0D0,     0.0D0,
     :     0.0D0,       25.2D0,  0.0D0,     0.0D0 /
      DATA ( ( PSI(I,J), I=1,4 ), J=151,160 ) /
     :     0.1D0,      -24.5D0,  0.0D0,     0.0D0,
     :    -0.1D0,       24.3D0,  0.0D0,     0.0D0,
     :     0.1D0,      -20.7D0,  0.0D0,     0.0D0,
     :     0.1D0,      -20.8D0,  0.0D0,     0.0D0,
     :    -0.2D0,       33.4D0,  0.0D0,     0.0D0,
     :    32.9D0,        0.0D0,  0.0D0,     0.0D0,
     :     0.1D0,      -32.6D0,  0.0D0,     0.0D0,
     :     0.0D0,       19.9D0,  0.0D0,     0.0D0,
     :    -0.1D0,       19.6D0,  0.0D0,     0.0D0,
     :     0.0D0,      -18.7D0,  0.0D0,     0.0D0 /
      DATA ( ( PSI(I,J), I=1,4 ), J=161,170 ) /
     :     0.1D0,      -19.0D0,  0.0D0,     0.0D0,
     :     0.1D0,      -28.6D0,  0.0D0,     0.0D0,
     :     4.0D0,      178.8D0,-11.8D0,     0.3D0,
     :    39.8D0,     -107.3D0, -5.6D0,    -1.0D0,
     :     9.9D0,      164.0D0, -4.1D0,     0.1D0,
     :    -4.8D0,     -135.3D0, -3.4D0,    -0.1D0,
     :    50.5D0,       75.0D0,  1.4D0,    -1.2D0,
     :    -1.1D0,      -53.5D0,  1.3D0,     0.0D0,
     :   -45.0D0,       -2.4D0, -0.4D0,     6.6D0,
     :   -11.5D0,      -61.0D0, -0.9D0,     0.4D0 /
      DATA ( ( PSI(I,J), I=1,4 ), J=171,180 ) /
     :     4.4D0,      -68.4D0, -3.4D0,     0.0D0,
     :     7.7D0,      -47.1D0, -4.7D0,    -1.0D0,
     :   -42.9D0,      -12.6D0, -1.2D0,     4.2D0,
     :   -42.8D0,       12.7D0, -1.2D0,    -4.2D0,
     :    -7.6D0,      -44.1D0,  2.1D0,    -0.5D0,
     :   -64.1D0,        1.7D0,  0.2D0,     4.5D0,
     :    36.4D0,      -10.4D0,  1.0D0,     3.5D0,
     :    35.6D0,       10.2D0,  1.0D0,    -3.5D0,
     :    -1.7D0,       39.5D0,  2.0D0,     0.0D0,
     :    50.9D0,       -8.2D0, -0.8D0,    -5.0D0 /
      DATA ( ( PSI(I,J), I=1,4 ), J=181,190 ) /
     :     0.0D0,       52.3D0,  1.2D0,     0.0D0,
     :   -42.9D0,      -17.8D0,  0.4D0,     0.0D0,
     :     2.6D0,       34.3D0,  0.8D0,     0.0D0,
     :    -0.8D0,      -48.6D0,  2.4D0,    -0.1D0,
     :    -4.9D0,       30.5D0,  3.7D0,     0.7D0,
     :     0.0D0,      -43.6D0,  2.1D0,     0.0D0,
     :     0.0D0,      -25.4D0,  1.2D0,     0.0D0,
     :     2.0D0,       40.9D0, -2.0D0,     0.0D0,
     :    -2.1D0,       26.1D0,  0.6D0,     0.0D0,
     :    22.6D0,       -3.2D0, -0.5D0,    -0.5D0 /
      DATA ( ( PSI(I,J), I=1,4 ), J=191,NTERMS ) /
     :    -7.6D0,       24.9D0, -0.4D0,    -0.2D0,
     :    -6.2D0,       34.9D0,  1.7D0,     0.3D0,
     :     2.0D0,       17.4D0, -0.4D0,     0.1D0,
     :    -3.9D0,       20.5D0,  2.4D0,     0.6D0 /

*  Nutation series: obliquity
      DATA ( ( EPS(I,J), I=1,4 ), J=1,10 ) /
     : 9205365.8D0, -1506.2D0,  885.7D0, -0.2D0,
     :  573095.9D0,  -570.2D0, -305.0D0, -0.3D0,
     :   97845.5D0,   147.8D0,  -48.8D0, -0.2D0,
     :  -89753.6D0,    28.0D0,   46.9D0,  0.0D0,
     :    7406.7D0,  -327.1D0,  -18.2D0,  0.8D0,
     :   22442.3D0,   -22.3D0,  -67.6D0,  0.0D0,
     :    -683.6D0,    46.8D0,    0.0D0,  0.0D0,
     :   20070.7D0,    36.0D0,    1.6D0,  0.0D0,
     :   12893.8D0,    39.5D0,   -6.2D0,  0.0D0,
     :   -9593.2D0,    14.4D0,   30.2D0, -0.1D0 /
      DATA ( ( EPS(I,J), I=1,4 ), J=11,20 ) /
     :   -6899.5D0,     4.8D0,   -0.6D0,  0.0D0,
     :   -5332.5D0,    -0.1D0,    2.7D0,  0.0D0,
     :    -125.2D0,    10.5D0,    0.0D0,  0.0D0,
     :   -3323.4D0,    -0.9D0,   -0.3D0,  0.0D0,
     :    3142.3D0,     8.9D0,    0.3D0,  0.0D0,
     :    2552.5D0,     7.3D0,   -1.2D0,  0.0D0,
     :    2634.4D0,     8.8D0,    0.2D0,  0.0D0,
     :   -2424.4D0,     1.6D0,   -0.4D0,  0.0D0,
     :    -123.3D0,     3.9D0,    0.0D0,  0.0D0,
     :    1642.4D0,     7.3D0,   -0.8D0,  0.0D0 /
      DATA ( ( EPS(I,J), I=1,4 ), J=21,30 ) /
     :      47.9D0,     3.2D0,    0.0D0,  0.0D0,
     :    1321.2D0,     6.2D0,   -0.6D0,  0.0D0,
     :   -1234.1D0,    -0.3D0,    0.6D0,  0.0D0,
     :   -1076.5D0,    -0.3D0,    0.0D0,  0.0D0,
     :     -61.6D0,     1.8D0,    0.0D0,  0.0D0,
     :     -55.4D0,     1.6D0,    0.0D0,  0.0D0,
     :     856.9D0,    -4.9D0,   -2.1D0,  0.0D0,
     :    -800.7D0,    -0.1D0,    0.0D0,  0.0D0,
     :     685.1D0,    -0.6D0,   -3.8D0,  0.0D0,
     :     -16.9D0,    -1.5D0,    0.0D0,  0.0D0 /
      DATA ( ( EPS(I,J), I=1,4 ), J=31,40 ) /
     :     695.7D0,     1.8D0,    0.0D0,  0.0D0,
     :     642.2D0,    -2.6D0,   -1.6D0,  0.0D0,
     :      13.3D0,     1.1D0,   -0.1D0,  0.0D0,
     :     521.9D0,     1.6D0,    0.0D0,  0.0D0,
     :     325.8D0,     2.0D0,   -0.1D0,  0.0D0,
     :    -325.1D0,    -0.5D0,    0.9D0,  0.0D0,
     :      10.1D0,     0.3D0,    0.0D0,  0.0D0,
     :     334.5D0,     1.6D0,    0.0D0,  0.0D0,
     :     307.1D0,     0.4D0,   -0.9D0,  0.0D0,
     :     327.2D0,     0.5D0,    0.0D0,  0.0D0 /
      DATA ( ( EPS(I,J), I=1,4 ), J=41,50 ) /
     :    -304.6D0,    -0.1D0,    0.0D0,  0.0D0,
     :     304.0D0,     0.6D0,    0.0D0,  0.0D0,
     :    -276.8D0,    -0.5D0,    0.1D0,  0.0D0,
     :     268.9D0,     1.3D0,    0.0D0,  0.0D0,
     :     271.8D0,     1.1D0,    0.0D0,  0.0D0,
     :     271.5D0,    -0.4D0,   -0.8D0,  0.0D0,
     :      -5.2D0,     0.5D0,    0.0D0,  0.0D0,
     :    -220.5D0,     0.1D0,    0.0D0,  0.0D0,
     :     -20.1D0,     0.3D0,    0.0D0,  0.0D0,
     :    -191.0D0,     0.1D0,    0.5D0,  0.0D0 /
      DATA ( ( EPS(I,J), I=1,4 ), J=51,60 ) /
     :      -4.1D0,     0.3D0,    0.0D0,  0.0D0,
     :     130.6D0,    -0.1D0,    0.0D0,  0.0D0,
     :       3.0D0,     0.3D0,    0.0D0,  0.0D0,
     :     122.9D0,     0.8D0,    0.0D0,  0.0D0,
     :       3.7D0,    -0.3D0,    0.0D0,  0.0D0,
     :     123.1D0,     0.4D0,   -0.3D0,  0.0D0,
     :     -52.7D0,    15.3D0,    0.0D0,  0.0D0,
     :     120.7D0,     0.3D0,   -0.3D0,  0.0D0,
     :       4.0D0,    -0.3D0,    0.0D0,  0.0D0,
     :     126.5D0,     0.5D0,    0.0D0,  0.0D0 /
      DATA ( ( EPS(I,J), I=1,4 ), J=61,70 ) /
     :     112.7D0,     0.5D0,   -0.3D0,  0.0D0,
     :    -106.1D0,    -0.3D0,    0.3D0,  0.0D0,
     :    -112.9D0,    -0.2D0,    0.0D0,  0.0D0,
     :       3.6D0,    -0.2D0,    0.0D0,  0.0D0,
     :     107.4D0,     0.3D0,    0.0D0,  0.0D0,
     :     -10.9D0,     0.2D0,    0.0D0,  0.0D0,
     :      -0.9D0,     0.0D0,    0.0D0,  0.0D0,
     :      85.4D0,     0.0D0,    0.0D0,  0.0D0,
     :       0.0D0,   -88.8D0,    0.0D0,  0.0D0,
     :     -71.0D0,    -0.2D0,    0.0D0,  0.0D0 /
      DATA ( ( EPS(I,J), I=1,4 ), J=71,80 ) /
     :     -70.3D0,     0.0D0,    0.0D0,  0.0D0,
     :      64.5D0,     0.4D0,    0.0D0,  0.0D0,
     :      69.8D0,     0.0D0,    0.0D0,  0.0D0,
     :      66.1D0,     0.4D0,    0.0D0,  0.0D0,
     :     -61.0D0,    -0.2D0,    0.0D0,  0.0D0,
     :     -59.5D0,    -0.1D0,    0.0D0,  0.0D0,
     :     -55.6D0,     0.0D0,    0.2D0,  0.0D0,
     :      51.7D0,     0.2D0,    0.0D0,  0.0D0,
     :     -49.0D0,    -0.1D0,    0.0D0,  0.0D0,
     :     -52.7D0,    -0.1D0,    0.0D0,  0.0D0 /
      DATA ( ( EPS(I,J), I=1,4 ), J=81,90 ) /
     :     -49.6D0,     1.4D0,    0.0D0,  0.0D0,
     :      46.3D0,     0.4D0,    0.0D0,  0.0D0,
     :      49.6D0,     0.1D0,    0.0D0,  0.0D0,
     :      -5.1D0,     0.1D0,    0.0D0,  0.0D0,
     :     -44.0D0,    -0.1D0,    0.0D0,  0.0D0,
     :     -39.9D0,    -0.1D0,    0.0D0,  0.0D0,
     :     -39.5D0,    -0.1D0,    0.0D0,  0.0D0,
     :      -3.9D0,     0.1D0,    0.0D0,  0.0D0,
     :     -42.1D0,    -0.1D0,    0.0D0,  0.0D0,
     :     -17.2D0,     0.1D0,    0.0D0,  0.0D0 /
      DATA ( ( EPS(I,J), I=1,4 ), J=91,100 ) /
     :      -2.3D0,     0.1D0,    0.0D0,  0.0D0,
     :     -39.2D0,     0.0D0,    0.0D0,  0.0D0,
     :     -38.4D0,     0.1D0,    0.0D0,  0.0D0,
     :      36.8D0,     0.2D0,    0.0D0,  0.0D0,
     :      34.6D0,     0.1D0,    0.0D0,  0.0D0,
     :     -32.7D0,     0.3D0,    0.0D0,  0.0D0,
     :      30.4D0,     0.0D0,    0.0D0,  0.0D0,
     :       0.4D0,     0.1D0,    0.0D0,  0.0D0,
     :      29.3D0,     0.2D0,    0.0D0,  0.0D0,
     :      31.6D0,     0.1D0,    0.0D0,  0.0D0 /
      DATA ( ( EPS(I,J), I=1,4 ), J=101,110 ) /
     :       0.8D0,    -0.1D0,    0.0D0,  0.0D0,
     :     -27.9D0,     0.0D0,    0.0D0,  0.0D0,
     :       2.9D0,     0.0D0,    0.0D0,  0.0D0,
     :     -25.3D0,     0.0D0,    0.0D0,  0.0D0,
     :      25.0D0,     0.1D0,    0.0D0,  0.0D0,
     :      27.5D0,     0.1D0,    0.0D0,  0.0D0,
     :     -24.4D0,    -0.1D0,    0.0D0,  0.0D0,
     :      24.9D0,     0.2D0,    0.0D0,  0.0D0,
     :     -22.8D0,    -0.1D0,    0.0D0,  0.0D0,
     :       0.9D0,    -0.1D0,    0.0D0,  0.0D0 /
      DATA ( ( EPS(I,J), I=1,4 ), J=111,120 ) /
     :      24.4D0,     0.1D0,    0.0D0,  0.0D0,
     :      23.9D0,     0.1D0,    0.0D0,  0.0D0,
     :      22.5D0,     0.1D0,    0.0D0,  0.0D0,
     :      20.8D0,     0.1D0,    0.0D0,  0.0D0,
     :      20.1D0,     0.0D0,    0.0D0,  0.0D0,
     :      21.5D0,     0.1D0,    0.0D0,  0.0D0,
     :     -20.0D0,     0.0D0,    0.0D0,  0.0D0,
     :       1.4D0,     0.0D0,    0.0D0,  0.0D0,
     :      -0.2D0,    -0.1D0,    0.0D0,  0.0D0,
     :      19.0D0,     0.0D0,   -0.1D0,  0.0D0 /
      DATA ( ( EPS(I,J), I=1,4 ), J=121,130 ) /
     :      20.5D0,     0.0D0,    0.0D0,  0.0D0,
     :      -2.0D0,     0.0D0,    0.0D0,  0.0D0,
     :     -17.6D0,    -0.1D0,    0.0D0,  0.0D0,
     :      19.0D0,     0.0D0,    0.0D0,  0.0D0,
     :      -2.4D0,     0.0D0,    0.0D0,  0.0D0,
     :     -18.4D0,    -0.1D0,    0.0D0,  0.0D0,
     :      17.1D0,     0.0D0,    0.0D0,  0.0D0,
     :       0.4D0,     0.0D0,    0.0D0,  0.0D0,
     :      18.4D0,     0.1D0,    0.0D0,  0.0D0,
     :       0.0D0,    17.4D0,    0.0D0,  0.0D0 /
      DATA ( ( EPS(I,J), I=1,4 ), J=131,140 ) /
     :      -0.6D0,     0.0D0,    0.0D0,  0.0D0,
     :     -15.4D0,     0.0D0,    0.0D0,  0.0D0,
     :     -16.8D0,    -0.1D0,    0.0D0,  0.0D0,
     :      16.3D0,     0.0D0,    0.0D0,  0.0D0,
     :      -2.0D0,     0.0D0,    0.0D0,  0.0D0,
     :      -1.5D0,     0.0D0,    0.0D0,  0.0D0,
     :     -14.3D0,    -0.1D0,    0.0D0,  0.0D0,
     :      14.4D0,     0.0D0,    0.0D0,  0.0D0,
     :     -13.4D0,     0.0D0,    0.0D0,  0.0D0,
     :     -14.3D0,    -0.1D0,    0.0D0,  0.0D0 /
      DATA ( ( EPS(I,J), I=1,4 ), J=141,150 ) /
     :     -13.7D0,     0.0D0,    0.0D0,  0.0D0,
     :      13.1D0,     0.1D0,    0.0D0,  0.0D0,
     :      -1.7D0,     0.0D0,    0.0D0,  0.0D0,
     :     -12.8D0,     0.0D0,    0.0D0,  0.0D0,
     :       0.0D0,   -14.4D0,    0.0D0,  0.0D0,
     :      12.4D0,     0.0D0,    0.0D0,  0.0D0,
     :     -12.0D0,     0.0D0,    0.0D0,  0.0D0,
     :      -0.8D0,     0.0D0,    0.0D0,  0.0D0,
     :      10.9D0,     0.1D0,    0.0D0,  0.0D0,
     :     -10.8D0,     0.0D0,    0.0D0,  0.0D0 /
      DATA ( ( EPS(I,J), I=1,4 ), J=151,160 ) /
     :      10.5D0,     0.0D0,    0.0D0,  0.0D0,
     :     -10.4D0,     0.0D0,    0.0D0,  0.0D0,
     :     -11.2D0,     0.0D0,    0.0D0,  0.0D0,
     :      10.5D0,     0.1D0,    0.0D0,  0.0D0,
     :      -1.4D0,     0.0D0,    0.0D0,  0.0D0,
     :       0.0D0,     0.1D0,    0.0D0,  0.0D0,
     :       0.7D0,     0.0D0,    0.0D0,  0.0D0,
     :     -10.3D0,     0.0D0,    0.0D0,  0.0D0,
     :     -10.0D0,     0.0D0,    0.0D0,  0.0D0,
     :       9.6D0,     0.0D0,    0.0D0,  0.0D0 /
      DATA ( ( EPS(I,J), I=1,4 ), J=161,170 ) /
     :       9.4D0,     0.1D0,    0.0D0,  0.0D0,
     :       0.6D0,     0.0D0,    0.0D0,  0.0D0,
     :     -87.7D0,     4.4D0,   -0.4D0, -6.3D0,
     :      46.3D0,    22.4D0,    0.5D0, -2.4D0,
     :      15.6D0,    -3.4D0,    0.1D0,  0.4D0,
     :       5.2D0,     5.8D0,    0.2D0, -0.1D0,
     :     -30.1D0,    26.9D0,    0.7D0,  0.0D0,
     :      23.2D0,    -0.5D0,    0.0D0,  0.6D0,
     :       1.0D0,    23.2D0,    3.4D0,  0.0D0,
     :     -12.2D0,    -4.3D0,    0.0D0,  0.0D0 /
      DATA ( ( EPS(I,J), I=1,4 ), J=171,180 ) /
     :      -2.1D0,    -3.7D0,   -0.2D0,  0.1D0,
     :     -18.6D0,    -3.8D0,   -0.4D0,  1.8D0,
     :       5.5D0,   -18.7D0,   -1.8D0, -0.5D0,
     :      -5.5D0,   -18.7D0,    1.8D0, -0.5D0,
     :      18.4D0,    -3.6D0,    0.3D0,  0.9D0,
     :      -0.6D0,     1.3D0,    0.0D0,  0.0D0,
     :      -5.6D0,   -19.5D0,    1.9D0,  0.0D0,
     :       5.5D0,   -19.1D0,   -1.9D0,  0.0D0,
     :     -17.3D0,    -0.8D0,    0.0D0,  0.9D0,
     :      -3.2D0,    -8.3D0,   -0.8D0,  0.3D0 /
      DATA ( ( EPS(I,J), I=1,4 ), J=181,190 ) /
     :      -0.1D0,     0.0D0,    0.0D0,  0.0D0,
     :      -5.4D0,     7.8D0,   -0.3D0,  0.0D0,
     :     -14.8D0,     1.4D0,    0.0D0,  0.3D0,
     :      -3.8D0,     0.4D0,    0.0D0, -0.2D0,
     :      12.6D0,     3.2D0,    0.5D0, -1.5D0,
     :       0.1D0,     0.0D0,    0.0D0,  0.0D0,
     :     -13.6D0,     2.4D0,   -0.1D0,  0.0D0,
     :       0.9D0,     1.2D0,    0.0D0,  0.0D0,
     :     -11.9D0,    -0.5D0,    0.0D0,  0.3D0,
     :       0.4D0,    12.0D0,    0.3D0, -0.2D0 /
      DATA ( ( EPS(I,J), I=1,4 ), J=191,NTERMS ) /
     :       8.3D0,     6.1D0,   -0.1D0,  0.1D0,
     :       0.0D0,     0.0D0,    0.0D0,  0.0D0,
     :       0.4D0,   -10.8D0,    0.3D0,  0.0D0,
     :       9.6D0,     2.2D0,    0.3D0, -1.2D0 /



*  Interval between fundamental epoch J2000.0 and given epoch (JC).
      T = (DATE-DJM0)/DJC

*  Mean anomaly of the Moon.
      EL  = 134.96340251D0*DD2R+
     :      MOD(T*(1717915923.2178D0+
     :          T*(        31.8792D0+
     :          T*(         0.051635D0+
     :          T*(       - 0.00024470D0)))),TURNAS)*DAS2R

*  Mean anomaly of the Sun.
      ELP = 357.52910918D0*DD2R+
     :      MOD(T*( 129596581.0481D0+
     :          T*(       - 0.5532D0+
     :          T*(         0.000136D0+
     :          T*(       - 0.00001149D0)))),TURNAS)*DAS2R

*  Mean argument of the latitude of the Moon.
      F   =  93.27209062D0*DD2R+
     :      MOD(T*(1739527262.8478D0+
     :          T*(      - 12.7512D0+
     :          T*(      -  0.001037D0+
     :          T*(         0.00000417D0)))),TURNAS)*DAS2R

*  Mean elongation of the Moon from the Sun.
      D   = 297.85019547D0*DD2R+
     :      MOD(T*(1602961601.2090D0+
     :          T*(       - 6.3706D0+
     :          T*(         0.006539D0+
     :          T*(       - 0.00003169D0)))),TURNAS)*DAS2R

*  Mean longitude of the ascending node of the Moon.
      OM  = 125.04455501D0*DD2R+
     :      MOD(T*( - 6962890.5431D0+
     :          T*(         7.4722D0+
     :          T*(         0.007702D0+
     :          T*(       - 0.00005939D0)))),TURNAS)*DAS2R

*  Mean longitude of Venus.
      VE    = 181.97980085D0*DD2R+MOD(210664136.433548D0*T,TURNAS)*DAS2R

*  Mean longitude of Mars.
      MA    = 355.43299958D0*DD2R+MOD( 68905077.493988D0*T,TURNAS)*DAS2R

*  Mean longitude of Jupiter.
      JU    =  34.35151874D0*DD2R+MOD( 10925660.377991D0*T,TURNAS)*DAS2R

*  Mean longitude of Saturn.
      SA    =  50.07744430D0*DD2R+MOD(  4399609.855732D0*T,TURNAS)*DAS2R

*  Geodesic nutation (Fukushima 1991) in microarcsec.
      DP = -153.1D0*SIN(ELP)-1.9D0*SIN(2D0*ELP)
      DE = 0D0

*  Shirai & Fukushima (2001) nutation series.
      DO J=NTERMS,1,-1
         THETA = DBLE(NA(1,J))*EL+
     :           DBLE(NA(2,J))*ELP+
     :           DBLE(NA(3,J))*F+
     :           DBLE(NA(4,J))*D+
     :           DBLE(NA(5,J))*OM+
     :           DBLE(NA(6,J))*VE+
     :           DBLE(NA(7,J))*MA+
     :           DBLE(NA(8,J))*JU+
     :           DBLE(NA(9,J))*SA
         C = COS(THETA)
         S = SIN(THETA)
         DP = DP+(PSI(1,J)+PSI(3,J)*T)*C+(PSI(2,J)+PSI(4,J)*T)*S
         DE = DE+(EPS(1,J)+EPS(3,J)*T)*C+(EPS(2,J)+EPS(4,J)*T)*S
      END DO

*  Change of units, and addition of the precession correction.
      DPSI = (DP*1D-6-0.042888D0-0.29856D0*T)*DAS2R
      DEPS = (DE*1D-6-0.005171D0-0.02408D0*T)*DAS2R

*  Mean obliquity of date (Simon et al. 1994).
      EPS0 = (84381.412D0+
     :         (-46.80927D0+
     :          (-0.000152D0+
     :           (0.0019989D0+
     :          (-0.00000051D0+
     :          (-0.000000025D0)*T)*T)*T)*T)*T)*DAS2R

      END
