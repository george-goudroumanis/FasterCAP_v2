########################################################################
##
## Copyright (C) 2007-2023 The Octave Project Developers
##
## See the file COPYRIGHT.md in the top-level directory of this
## distribution or <https://octave.org/copyright/>.
##
## This file is part of Octave.
##
## Octave is free software: you can redistribute it and/or modify it
## under the terms of the GNU General Public License as published by
## the Free Software Foundation, either version 3 of the License, or
## (at your option) any later version.
##
## Octave is distributed in the hope that it will be useful, but
## WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with Octave; see the file COPYING.  If not, see
## <https://www.gnu.org/licenses/>.
##
########################################################################

## -*- texinfo -*-
## @deftypefn  {} {[@var{multp}, @var{idxp}] =} mpoles (@var{p})
## @deftypefnx {} {[@var{multp}, @var{idxp}] =} mpoles (@var{p}, @var{tol})
## @deftypefnx {} {[@var{multp}, @var{idxp}] =} mpoles (@var{p}, @var{tol}, @var{reorder})
## Identify unique poles in @var{p} and their associated multiplicity.
##
## The output is ordered from pole with largest magnitude to smallest
## magnitude.
##
## If the relative difference of two poles is less than @var{tol} then they are
## considered to be multiples.  The default value for @var{tol} is 0.001.
##
## If the optional parameter @var{reorder} is zero, poles are not sorted.
##
## The output @var{multp} is a vector specifying the multiplicity of the poles.
## @code{@var{multp}(n)} refers to the multiplicity of the Nth pole
## @code{@var{p}(@var{idxp}(n))}.
##
## For example:
##
## @example
## @group
## p = [2 3 1 1 2];
## [m, n] = mpoles (p)
##    @result{} m = [1; 1; 2; 1; 2]
##    @result{} n = [2; 5; 1; 4; 3]
##    @result{} p(n) = [3, 2, 2, 1, 1]
## @end group
## @end example
##
## @seealso{residue, poly, roots, conv, deconv}
## @end deftypefn

function [multp, indx] = mpoles (p, tol, reorder)

  if (nargin < 1)
    print_usage ();
  endif

   if (nargin < 2 || isempty (tol))
     tol = 0.001;
   endif

   if (nargin < 3 || isempty (reorder))
     reorder = true;
   endif

  Np = numel (p);

  ## force poles to be a column vector

  p = p(:);

  if (reorder)
    ## sort with largest magnitude first
    [~, ordr] = sort (abs (p), "descend");
    p = p(ordr);
  else
    ordr = (1:Np).';
  endif

  ## find pole multiplicity by comparing relative difference of poles

  multp = zeros (Np, 1);
  indx = [];
  n = find (multp == 0, 1);
  while (n)
    dp = abs (p-p(n));
    if (p(n) == 0.0)
      if (any (abs (p) > 0 & isfinite (p)))
        p0 = mean (abs (p(abs (p) > 0 & isfinite (p))));
      else
        p0 = 1;
      endif
    else
      p0 = abs (p(n));
    endif
    k = find (dp < tol * p0);
    ## Poles can only be members of one multiplicity group.
    if (numel (indx))
      k = k(! ismember (k, indx));
    endif
    m = 1:numel (k);
    multp(k) = m;
    indx = [indx; k];
    n = find (multp == 0, 1);
  endwhile
  multp = multp(indx);
  indx = ordr(indx);

endfunction


%!test
%! [mp, n] = mpoles ([0 0], 0.01);
%! assert (mp, [1; 2]);

%!test
%! [mp, n] = mpoles ([-1e4, -0.1, 0]);
%! assert (mp, ones (3, 1));
%! assert (n, [1; 2; 3]);
