########################################################################
##
## Copyright (C) 2006-2023 The Octave Project Developers
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

## FIXME: we should skip (or mark as a known bug) the test for
## saving sparse matrices to MAT files when using 64-bit indexing since
## that is not implemented yet.

%!function [ret, files] = testls (input)
%!  ## flag a1 global so as to test the storage of global flags
%!  global a1;
%!
%!  ## Input or output, so as to be able to exchange between versions
%!  if (nargin < 1)
%!    input = 0;
%!  endif
%!
%!  ## Setup some variable to be saved or compared to loaded variables
%!
%!  ## scalar
%!  a1 = 1;
%!  ## matrix
%!  persistent a2 = hilb (3);
%!  ## complex scalar
%!  persistent a3 = 1 + 1i;
%!  ## complex matrix
%!  persistent a4 = hilb (3) + 1i*hilb (3);
%!  ## bool
%!  persistent a5 = (1 == 1);
%!  ## bool matrix
%!  persistent a6 = ([ones(1,5), zeros(1,5)] == ones (1,10));
%!  ## range
%!  persistent a7 = 1:10;
%!  ## structure
%!  persistent a8 = struct ("a", a1, "b", a3);
%!  ## cell array
%!  persistent a9 = {a1, a3};
%!  ## string
%!  persistent a10 = ["test"; "strings"];
%!  ## int8 array
%!  persistent a11 = int8 (floor (256*rand (2,2)));
%!  ## int16 array
%!  persistent a12 = int16 (floor (65536*rand (2,2)));
%!  ## int32 array
%!  persistent a13 = int32 (floor (1e6*rand (2,2)));
%!  ## int64 array
%!  persistent a14 = int64 (floor (10*rand (2,2)));
%!  ## uint8 array
%!  persistent a15 = uint8 (floor (256*rand (2,2)));
%!  ## uint16 array
%!  persistent a16 = uint16 (floor (65536*rand (2,2)));
%!  ## int32 array
%!  persistent a17 = uint32 (floor (1e6*rand (2,2)));
%!  ## uint64 array
%!  persistent a18 = uint64 (floor (10*rand (2,2)));
%!  ## sparse
%!  persistent a19 = sprandn (100,100,0.01);
%!  ## complex sparse
%!  persistent a20 = sprandn (100,100,0.01) + 1i * sprandn (100,100,0.01);
%!
%!  ret = 0;
%!
%!  files = cellfun (@fullfile, {P_tmpdir},
%!                   {"text.mat", "binary.mat", "mat5.mat", "mat7.mat"},
%!                   "UniformOutput", false);
%!  opts = {"-z -text", "-z -binary", "-z -mat", "-v7"};
%!  tols = {2*eps, 0, 0, 0};
%!
%!  vars = "a1 a2 a3 a4 a5 a6 a7 a8 a9 a10 a11 a12 a13 a14 a15 a16 a17 a18 a19 a20";
%!  if (! input)
%!    for i = 1:length (files)
%!      eval (sprintf ("save %s %s %s", opts{i}, files{i}, vars));
%!    endfor
%!  else
%!    b1 = a1; b2 = a2; b3 = a3; b4 = a4; b5 = a5;
%!    b6 = a6; b7 = a7; b8 = a8; b9 = a9;
%!    b10 = a10; b11 = a11; b12 = a12; b13 = a13; b14 = a14; b15 = a15;
%!    b16 = a16; b17 = a17; b18 = a18; b19 = a19; b20 = a20;
%!
%!    for i = length (files)
%!
%!      clear a1 a2 a3 a4 a5 a6 a7 a8 a9 a10 a11 a12 a13 a14 a15 a16 a17 a19 a20;
%!
%!      file = files{i};
%!      tol = tols{i};
%!
%!      load (file);
%!
%!      assert (a1, b1, tol);
%!      assert (a2, b2, tol);
%!      assert (a3, b3, tol);
%!      assert (a4, b4, tol);
%!
%!      if (! isequal (a5, b5))
%!        error ("failed: %s boolean", file);
%!      endif
%!
%!      if (! strcmp (file, "mat5") && ! strcmp (file, "mat7"))
%!        if (! isequal (a6, b6))
%!          error ("failed: %s boolean matrix", file);
%!        endif
%!      endif
%!
%!      assert ([a7], [b7], tol);
%!
%!      if (! isequal (a8, b8))
%!        error ("failed: %s struct", file);
%!      endif
%!
%!      if (! isequal (a9, b9))
%!        error ("failed: %s cell", file);
%!      endif
%!
%!      if (! isequal (a10, b10))
%!        error ("failed: %s string", file);
%!      endif
%!
%!      if (! isequal (a11, b11))
%!        error ("failed: %s int8", file);
%!      endif
%!
%!      if (! isequal (a12, b12))
%!        error ("failed: %s int16", file);
%!      endif
%!
%!      if (! isequal (a13, b13))
%!        error ("failed: %s int32", file);
%!      endif
%!
%!      if (! isequal (a14, b14))
%!        error ("failed: %s int64", file);
%!      endif
%!
%!      if (! isequal (a15, b15))
%!        error ("failed: %s uint8", file);
%!      endif
%!
%!      if (! isequal (a16, b16))
%!        error ("failed: %s uint16", file);
%!      endif
%!
%!      if (! isequal (a17, b17))
%!        error ("failed: %s uint32", file);
%!      endif
%!
%!      if (! isequal (a18, b18))
%!        error ("failed: %s uint64", file);
%!      endif
%!
%!      assert (a19, b19, tol);
%!      assert (a20, b20, tol);
%!
%!      ## Test for global flags
%!      if (! isglobal ("a1") || isglobal ("a2") || isglobal ("a3")
%!          || isglobal ("a4") || isglobal ("a5") || isglobal ("a6")
%!          || isglobal ("a7") || isglobal ("a8") || isglobal ("a9")
%!          || isglobal ("a10") || isglobal ("a11") || isglobal ("a12")
%!          || isglobal ("a13") || isglobal ("a14") || isglobal ("a15")
%!          || isglobal ("a16") || isglobal ("a17") || isglobal ("a18")
%!          || isglobal ("a19") || isglobal ("a20"))
%!        error ("failed: %s global test", file);
%!      endif
%!    endfor
%!  endif
%!
%!  ## Cleanup after test
%!  clear -global a1;
%!
%!  ret = 1;
%!endfunction

%!testif HAVE_ZLIB
%!
%! [save_status, save_files] = testls (0);
%! [load_status, load_files] = testls (1);
%!
%! for f = [save_files, load_files]
%!   sts = unlink (f{1});
%! endfor
%!
%! assert (save_status && load_status);
%! clear -global a1;  # cleanup after test

%!testif HAVE_HDF5
%!
%! s8  =   int8 (fix ((2^8  - 1) * (rand (2, 2) - 0.5)));
%! u8  =  uint8 (fix ((2^8  - 1) * (rand (2, 2) - 0.5)));
%! s16 =  int16 (fix ((2^16 - 1) * (rand (2, 2) - 0.5)));
%! u16 = uint16 (fix ((2^16 - 1) * (rand (2, 2) - 0.5)));
%! s32 =  int32 (fix ((2^32 - 1) * (rand (2, 2) - 0.5)));
%! u32 = uint32 (fix ((2^32 - 1) * (rand (2, 2) - 0.5)));
%! s64 =  int64 (fix ((2^64 - 1) * (rand (2, 2) - 0.5)));
%! u64 = uint64 (fix ((2^64 - 1) * (rand (2, 2) - 0.5)));
%! s8t = s8; u8t = u8; s16t = s16; u16t = u16; s32t = s32; u32t = u32;
%! s64t = s64; u64t = u64;
%! h5file = tempname ();
%! unwind_protect
%!   eval (sprintf ("save -hdf5 %s %s", h5file, "s8 u8 s16 u16 s32 u32 s64 u64"));
%!   clear s8 u8 s16 u16 s32 u32 s64 u64;
%!   load (h5file);
%!   assert (s8, s8t);
%!   assert (u8, u8t);
%!   assert (s16, s16t);
%!   assert (u16, u16t);
%!   assert (s32, s32t);
%!   assert (u32, u32t);
%!   assert (s64, s64t);
%!   assert (u64, u64t);
%! unwind_protect_cleanup
%!   sts = unlink (h5file);
%! end_unwind_protect

%!test
%!
%! STR.scalar_fld = 1;
%! STR.matrix_fld = [1.1,2;3,4];
%! STR.string_fld = "Octave";
%! STR.struct_fld.x = 0;
%! STR.struct_fld.y = 1;
%!
%! struct_dat = fullfile (P_tmpdir, "struct.dat");
%! save_default_options ("-text", "local");
%! save_precision (17, "local");
%! save (struct_dat, "-struct", "STR");
%! STR = load (struct_dat);
%!
%! assert (STR.scalar_fld == 1 && ...
%!         STR.matrix_fld == [1.1,2;3,4] && ...
%!         STR.string_fld == "Octave" && ...
%!         STR.struct_fld.x == 0 && ...
%!         STR.struct_fld.y == 1 );
%!
%!
%! save ("-binary", struct_dat,
%!       "-struct", "STR", "matrix_fld", "str*_fld");
%! STR = load (struct_dat);
%!
%! assert (! isfield (STR,"scalar_fld") && ...
%!         STR.matrix_fld == [1.1,2;3,4] && ...
%!         STR.string_fld == "Octave" && ...
%!         STR.struct_fld.x == 0 && ...
%!         STR.struct_fld.y == 1);
%!
%! delete (struct_dat);

%!test
%! matrix1 = rand (100, 2);
%! matrix_ascii = fullfile (P_tmpdir, "matrix.ascii");
%! save ("-ascii", matrix_ascii, "matrix1");
%! matrix2 = load (matrix_ascii);
%! assert (matrix1, matrix2, 1e-9);
%!
%! delete (matrix_ascii);

%!error <unable to find file> load ("")

%% FIXME: This test is disabled as it writes to stdout and there is no easy
%% way to recover output.  Need to spawn new octave process and pipe stdout
%% somewhere to treat this case.
%!#test
%! puts ("foo\n");

%!assert (puts (1),-1)

%!error <Invalid call to puts> puts ()
%!error <Invalid call to puts> puts (1, 2)

%!assert (sscanf ('123456', '%10c'), '123456')
%!assert (sscanf ('123456', '%10s'), '123456')

%!assert (sscanf (['ab'; 'cd'], '%s'), 'acbd')

%!assert (sscanf ('02:08:30', '%i:%i:%i'), [2; 0])
%!assert (sscanf ('02:08:30', '%d:%d:%d'), [2; 8; 30])

%!assert (sscanf ('0177 08', '%i'), [127; 0; 8])
%!assert (sscanf ('0177 08', '%d'), [177; 8])

## Extensive testing of '%c'
%!test
%! [val, cnt, msg, pos] = sscanf ('abcde', '%c');
%! assert (val, 'abcde');
%! assert (cnt, 5);
%! assert (msg, '');
%! assert (pos, 6);
%! [val, cnt, msg, pos] = sscanf ('abcde', '%10c');
%! assert (val, 'abcde');
%! assert (cnt, 1);
%! assert (msg, '');
%! assert (pos, 6);
%! [val, cnt, msg, pos] = sscanf ('abcde', '%3c');
%! assert (val, 'abcde');
%! assert (cnt, 2);
%! assert (msg, '');
%! assert (pos, 6);
%! [val, cnt, msg, pos] = sscanf ('abcde', '%3c', 1);
%! assert (val, 'abc');
%! assert (cnt, 1);
%! assert (msg, '');
%! assert (pos, 4);
%! [val, cnt, msg, pos] = sscanf ('abcde', '%c', 5);
%! assert (val, 'abcde');
%! assert (cnt, 5);
%! assert (msg, '');
%! assert (pos, 6);

## Extensive testing of '%s'
%!test
%! [val, cnt, msg, pos] = sscanf ('abcde', '%s');
%! assert (val, 'abcde');
%! assert (cnt, 1);
%! assert (msg, '');
%! assert (pos, 6);
%! [val, cnt, msg, pos] = sscanf ('abcde', '%10s');
%! assert (val, 'abcde');
%! assert (cnt, 1);
%! assert (msg, '');
%! assert (pos, 6);
%! [val, cnt, msg, pos] = sscanf ('abcde', '%3s');
%! assert (val, 'abcde');
%! assert (cnt, 2);
%! assert (msg, '');
%! assert (pos, 6);
%! [val, cnt, msg, pos] = sscanf ('abcde', '%3s', 1);
%! assert (val, 'abc');
%! assert (cnt, 1);
%! assert (msg, '');
%! assert (pos, 4);
%! [val, cnt, msg, pos] = sscanf ('abcde', '%1s', 5);
%! assert (val, 'abcde');
%! assert (cnt, 5);
%! assert (msg, '');
%! assert (pos, 6);

## Extensive testing of '%[]'
%!test
%! [val, cnt, msg, pos] = sscanf ('abcde', '%[a-c]');
%! assert (val, 'abc');
%! assert (cnt, 1);
%! assert (msg, 'sscanf: format failed to match');
%! assert (pos, 4);
%! [val, cnt, msg, pos] = sscanf ('abcde', '%10[a-c]');
%! assert (val, 'abc');
%! assert (cnt, 1);
%! assert (msg, 'sscanf: format failed to match');
%! assert (pos, 4);
%! [val, cnt, msg, pos] = sscanf ('abcde', '%2[a-c]');
%! assert (val, 'abc');
%! assert (cnt, 2);
%! assert (msg, 'sscanf: format failed to match');
%! assert (pos, 4);
%! [val, cnt, msg, pos] = sscanf ('abcde', '%2[a-c]', 1);
%! assert (val, 'ab');
%! assert (cnt, 1);
%! assert (msg, '');
%! assert (pos, 3);
%! [val, cnt, msg, pos] = sscanf ('abcde', '%[a-c]', 1);
%! assert (val, 'abc');
%! assert (cnt, 1);
%! assert (msg, '');
%! assert (pos, 4);

## Extensive testing of '%[^]'
%!test
%! [val, cnt, msg, pos] = sscanf ('abcde', '%[^de]');
%! assert (val, 'abc');
%! assert (cnt, 1);
%! assert (msg, 'sscanf: format failed to match');
%! assert (pos, 4);
%! [val, cnt, msg, pos] = sscanf ('abcde', '%10[^de]');
%! assert (val, 'abc');
%! assert (cnt, 1);
%! assert (msg, 'sscanf: format failed to match');
%! assert (pos, 4);
%! [val, cnt, msg, pos] = sscanf ('abcde', '%2[^de]');
%! assert (val, 'abc');
%! assert (cnt, 2);
%! assert (msg, 'sscanf: format failed to match');
%! assert (pos, 4);
%! [val, cnt, msg, pos] = sscanf ('abcde', '%2[^de]', 1);
%! assert (val, 'ab');
%! assert (cnt, 1);
%! assert (msg, '');
%! assert (pos, 3);
%! [val, cnt, msg, pos] = sscanf ('abcde', '%[^de]', 1);
%! assert (val, 'abc');
%! assert (cnt, 1);
%! assert (msg, '');
%! assert (pos, 4);

## bug #47741
%!assert (sscanf ('2147483647', '%d'), 2147483647)
%!assert (sscanf ('2147483647', '%i'), 2147483647)
%!assert (sscanf ('4294967295', '%u'), 4294967295)
%!assert (sscanf ('37777777777', '%o'), 4294967295)
%!assert (sscanf ('ffffffff', '%x'), 4294967295)
## FIXME: scanf should return int64/uint64 if all conversions are %l[dioux].
## Until then only test values that are within precision range of a double.
%!assert (sscanf ('281474976710655', '%ld'), 281474976710655)
%!assert (sscanf ('281474976710655', '%li'), 281474976710655)
%!assert (sscanf ('281474976710655', '%lu'), 281474976710655)
%!assert (sscanf ('7777777777777777', '%lo'), 281474976710655)
%!assert (sscanf ('ffffffffffff', '%lx'), 281474976710655)

## bug #47759
%!assert (sscanf ('999999999999999', '%d'), double (intmax ("int32")))
%!assert (sscanf ('999999999999999', '%i'), double (intmax ("int32")))
%!assert (sscanf ('999999999999999', '%u'), double (intmax ("uint32")))
%!assert (sscanf ('777777777777777', '%o'), double (intmax ("uint32")))
%!assert (sscanf ('fffffffffffffff', '%x'), double (intmax ("uint32")))
## FIXME: scanf should return int64/uint64 if all conversions are %l[dioux].
## Until then cast to a double (and lose precision) for comparison.
%!assert (sscanf ('9999999999999999999999', '%ld'), double (intmax ("int64")))
%!assert (sscanf ('9999999999999999999999', '%li'), double (intmax ("int64")))
%!assert (sscanf ('9999999999999999999999', '%lu'), double (intmax ("uint64")))
%!assert (sscanf ('7777777777777777777777', '%lo'), double (intmax ("uint64")))
%!assert (sscanf ('ffffffffffffffffffffff', '%lx'), double (intmax ("uint64")))

## bug 51794
%!assert (sscanf ('2147483647', '%d', 'C'), 2147483647)
%!assert (sscanf ('2147483647', '%i', 'C'), 2147483647)
%!assert (sscanf ('4294967295', '%u', 'C'), 4294967295)
%!assert (sscanf ('37777777777', '%o', 'C'), 4294967295)
%!assert (sscanf ('ffffffff', '%x', 'C'), 4294967295)
## FIXME: scanf should return int64/uint64 if all conversions are %l[dioux].
## Until then only test values that are within precision range of a double.
%!assert (sscanf ('281474976710655', '%ld', 'C'), 281474976710655)
%!assert (sscanf ('281474976710655', '%li', 'C'), 281474976710655)
%!assert (sscanf ('281474976710655', '%lu', 'C'), 281474976710655)
%!assert (sscanf ('7777777777777777', '%lo', 'C'), 281474976710655)
%!assert (sscanf ('ffffffffffff', '%lx', 'C'), 281474976710655)

%!testif ; ! ismac ()
%! [val, count, msg, pos] = sscanf ("3I2", "%f");
%! assert (val, 3);
%! assert (count, 1);
%! assert (msg, "sscanf: format failed to match");
%! assert (pos, 2);

%!test <47413>
%! ## Same test code as above, but intended only for test statistics on Mac.
%! if (! ismac ()), return; endif
%! [val, count, msg, pos] = sscanf ("3I2", "%f");
%! assert (val, 3);
%! assert (count, 1);
%! assert (msg, "sscanf: format failed to match");
%! assert (pos, 2);

%!testif ; ! ismac ()
%! [val, count, msg, pos] = sscanf ("3In2", "%f");
%! assert (val, 3);
%! assert (count, 1);
%! assert (msg, "sscanf: format failed to match");
%! assert (pos, 2);

%!test <47413>
%! ## Same test code as above, but intended only for test statistics on Mac.
%! if (! ismac ()), return; endif
%! [val, count, msg, pos] = sscanf ("3In2", "%f");
%! assert (val, 3);
%! assert (count, 1);
%! assert (msg, "");
%! assert (pos, 2);

%!testif ; ! ismac ()
%! [val, count, msg, pos] = sscanf ("3Inf2", "%f");
%! assert (val, [3; Inf; 2]);
%! assert (count, 3);
%! assert (msg, "");
%! assert (pos, 6);

%!test <47413>
%! ## Same test code as above, but intended only for test statistics on Mac.
%! if (! ismac ()), return; endif
%! [val, count, msg, pos] = sscanf ("3Inf2", "%f");
%! assert (val, [3; Inf; 2]);
%! assert (count, 3);
%! assert (msg, "");
%! assert (pos, 6);

%!test <*62723>
%! [val, count, msg, pos] = sscanf ("p", "%c");
%! assert (val, 'p');
%! assert (count, 1);
%! assert (msg, '');
%! assert (pos, 2);

%!test <*62723>
%! [val, count, msg, pos] = sscanf (' ,1 ', ' %s ', 1);
%! assert (val, ',1');
%! assert (count, 1);
%! assert (msg, '');
%! assert (pos, 5);

## Test NaN at EOF
%!test <*63383>
%! [val, count, msg, pos] = sscanf ('2 3 n', '%f');
%! assert (val, [2; 3]);
%! assert (count, 2);
%! assert (msg, 'sscanf: format failed to match');
%! assert (pos, 5);
%! [val, count, msg, pos] = sscanf ('2 3 na', '%f');
%! assert (val, [2; 3; NA]);
%! assert (count, 3);
%! assert (msg, '');
%! assert (pos, 7);
%! [val, count, msg, pos] = sscanf ('2 3 nan', '%f');
%! assert (val, [2; 3; NaN]);
%! assert (count, 3);
%! assert (msg, '');
%! assert (pos, 8);

## Test NaN within string
%!test <*63383>
%! [val, count, msg, pos] = sscanf ('2 3 n 4', '%f');
%! assert (val, [2; 3]);
%! assert (count, 2);
%! assert (msg, 'sscanf: format failed to match');
%! assert (pos, 5);
%! [val, count, msg, pos] = sscanf ('2 3 na 4', '%f');
%! assert (val, [2; 3; NA; 4]);
%! assert (count, 4);
%! assert (msg, '');
%! assert (pos, 9);
%! [val, count, msg, pos] = sscanf ('2 3 nan 4', '%f');
%! assert (val, [2; 3; NaN; 4]);
%! assert (count, 4);
%! assert (msg, '');
%! assert (pos, 10);

## Test Inf at EOF
%!test <*63383>
%! [val, count, msg, pos] = sscanf ('2 3 i', '%f');
%! assert (val, [2; 3]);
%! assert (count, 2);
%! assert (msg, 'sscanf: format failed to match');
%! assert (pos, 5);
%! [val, count, msg, pos] = sscanf ('2 3 in', '%f');
%! assert (val, [2; 3]);
%! assert (count, 2);
%! assert (msg, 'sscanf: format failed to match');
%! assert (pos, 5);
%! [val, count, msg, pos] = sscanf ('2 3 inf', '%f');
%! assert (val, [2; 3; Inf]);
%! assert (count, 3);
%! assert (msg, '');
%! assert (pos, 8);

## Test Inf within string
%!test <*63383>
%! [val, count, msg, pos] = sscanf ('2 3 i 4', '%f');
%! assert (val, [2; 3]);
%! assert (count, 2);
%! assert (msg, 'sscanf: format failed to match');
%! assert (pos, 5);
%! [val, count, msg, pos] = sscanf ('2 3 in 4', '%f');
%! assert (val, [2; 3]);
%! assert (count, 2);
%! assert (msg, 'sscanf: format failed to match');
%! assert (pos, 5);
%! [val, count, msg, pos] = sscanf ('2 3 inf 4', '%f');
%! assert (val, [2; 3; Inf; 4]);
%! assert (count, 4);
%! assert (msg, '');
%! assert (pos, 10);

## Test '-' at EOF
%!test <*63383>
%! [val, count, msg, pos] = sscanf ('2 3 -', '%d');
%! assert (val, [2; 3]);
%! assert (count, 2);
%! assert (msg, 'sscanf: format failed to match');
%! assert (pos, 5);
%! [val, count, msg, pos] = sscanf ('2 3 -', '%f');
%! assert (val, [2; 3]);
%! assert (count, 2);
%! assert (msg, 'sscanf: format failed to match');
%! assert (pos, 5);

## Test '-' within string
%!test <63383>
%! [val, count, msg, pos] = sscanf ('1 2 - 3', '%d');
%! assert (val, [1; 2]);
%! assert (count, 2);
%! assert (msg, 'sscanf: format failed to match');
%! assert (pos, 5);
%! [val, count, msg, pos] = sscanf ('1 2 - 3', '%f');
%! assert (val, [1; 2]);
%! assert (count, 2);
%! assert (msg, 'sscanf: format failed to match');
%! assert (pos, 5);

## Test '+' at EOF
%!test <*63383>
%! [val, count, msg, pos] = sscanf ('2 3 +', '%d');
%! assert (val, [2; 3]);
%! assert (count, 2);
%! assert (msg, 'sscanf: format failed to match');
%! assert (pos, 5);
%! [val, count, msg, pos] = sscanf ('2 3 +', '%f');
%! assert (val, [2; 3]);
%! assert (count, 2);
%! assert (msg, 'sscanf: format failed to match');
%! assert (pos, 5);

## Test '+' within string
%!test <63383>
%! [val, count, msg, pos] = sscanf ('1 2 + 3', '%d');
%! assert (val, [1; 2]);
%! assert (count, 2);
%! assert (msg, 'sscanf: format failed to match');
%! assert (pos, 5);
%! [val, count, msg, pos] = sscanf ('1 2 + 3', '%f');
%! assert (val, [1; 2]);
%! assert (count, 2);
%! assert (msg, 'sscanf: format failed to match');
%! assert (pos, 5);

%## Test +NA, -NA, +NAN, -NAN
%!test <*63383>
%! [val, count, msg, pos] = sscanf ('+NA -NA 1 +NAN -NAN', '%f');
%! assert (val, [NA; NA; 1; NaN; NaN]);
%! assert (count, 5);
%! assert (msg, '');
%! assert (pos, 20);
%! [val, count, msg, pos] = sscanf ('-NA', '%f');
%! assert (val, NA);
%! assert (count, 1);
%! assert (msg, '');
%! assert (pos, 4);
%! [val, count, msg, pos] = sscanf ('+NA', '%f');
%! assert (val, NA);
%! assert (count, 1);
%! assert (msg, '');
%! assert (pos, 4);
%! [val, count, msg, pos] = sscanf ('-NaN', '%f');
%! assert (val, NaN);
%! assert (count, 1);
%! assert (msg, '');
%! assert (pos, 5);
%! [val, count, msg, pos] = sscanf ('+NaN', '%f');
%! assert (val, NaN);
%! assert (count, 1);
%! assert (msg, '');
%! assert (pos, 5);

%!test
%! [a, b, c] = sscanf ("1.2 3 foo", "%f%d%s", "C");
%! [v1, c1, m1] = sscanf ("1 2 3 4 5 6", "%d");
%! [v2, c2, m2] = sscanf ("1 2 bar 3 4 5 6", "%d");
%!
%! assert ((a == 1.2 && b == 3 && c == "foo"
%!          && v1 == [1; 2; 3; 4; 5; 6] && c1 == 6 && ischar (m1)
%!          && v2 == [1; 2] && c2 == 2 && ischar (m2)));

%!test
%! [x, n] = sscanf ("   0.024000 0.200 0.200 2.000         1987           5           0  0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0    0 2 1 0 0 0 0 0 0 0 1 0 0 0 0 0 0 2 0 0 1 1 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0    0 0 0 0 0 0 0 0 0 0 0 0 0 2 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 2 0 4 5 1 2    2 5 5 8 2 8 12 6 15 18 28 26 47 88 118 162 192 130 88 56 27 23 14 9 6 3 4 1 0    2 3 1 0 0 0 0 1 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0    0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0    1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0   0.026000 0.250 0.250 2.100         3115           3           0  0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0    0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 1 1 0 0 0 0    0 0 0 0 1 0 1 0 0 0 0 0 0 0 2 0 0 0 0 1 0 0 0 0 0 0 0 1 0 0 0 0 0 1 0 1 1 0 1    1 1 0 1 0 1 3 2 0 5 15 25 44 66 145 179 193 172 104 57 17 11 12 2 1 0 1 1 0 1    0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 1 0 0 1 0 0 0 0    0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0    0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0   0.028000 0.300 0.300 2.200         4929           3           0  1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0    0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 1 0    0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1 0 0 0 0 0 0 0 0 0 0 0 1 0    1 0 1 0 1 2 2 3 2 3 14 21 49 80 148 184 218 159 124 63 37 13 12 3 1 1 0 0 0 0    0 0 0 1 0 0 0 0 0 0 0 1 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 1 1 0 0    0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0    0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0   0.030000 0.350 0.350 2.300         7051           5           0  0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 1 1 0 1 0 0    0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1    0 0 1 0 0 0 2 0 1 1 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 1 0 1 1    0 0 0 2 0 0 0 1 5 6 14 28 51 88 154 177 208 169 124 65 39 15 5 3 3 2 1 0 1 0 1   0 0 0 0 1 1 1 0 0 0 0 0 0 1 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 2 0 0 0 0 1 0 0 0    0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0    0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0   0.032000 0.400 0.400 2.400         9113           4           0  0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 1 0    1 0 0 0 0 2 0 0 0 0 0 0 0 1 0 0 0 0 0 0 1 0 0 1 0 0 1 0 0 0 0 1 0 0 0 0 0 0 0    0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 1 1 1 1 0 0 2 0    1 0 0 1 1 0 2 3 5 3 17 30 60 117 156 189 209 129 102 64 56 16 11 4 2 2 0 0 0 0   1 1 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0    1 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0    0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0   0.034000 0.450 0.450 2.500        11811           6           0  0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0    0 0 0 0 0 0 1 1 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 1 0 0    0 0 0 0 0 0 0 0 0 0 0 1 0 1 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 1 1 0 0 0 0 0 0 0 0    0 0 2 1 0 0 1 0 5 5 15 21 57 99 149 190 195 159 130 69 41 16 10 2 5 3 0 1 0 0    0 0 0 1 0 1 0 1 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0    0 0 0 1 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 1 0 0    0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0   0.036000 0.500 0.500 2.600        14985           3           0  0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0    0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0    0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1 1 0 0 1 0 0 1 0 0 0 0    0 0 0 0 1 0 0 2 2 6 10 34 60 95 126 177 194 155 99 71 44 17 6 7 2 0 0 0 3 0 0    1 0 0 0 1 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 1 0 0 0 1 0 0    0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0    0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0   0.038000 0.550 0.550 2.700        18391           3           0  0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 1 0 0 0 1 0 0 0 0    0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 2    1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 1 0 0 0 0 0 0 0 2 0 0 1 1 0 1    2 1 0 0 0 1 0 1 3 6 19 27 52 95 161 154 169 134 94 64 37 19 9 6 0 2 1 0 0 0 0    1 2 0 1 0 0 0 0 0 0 0 0 0 0 0 1 0 2 2 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0    0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0    0 0 0 0 0 2 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0   0.040000 0.600 0.600 2.800        22933           5           0  0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0    0 0 0 0 0 0 0 2 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 1 0 0 0 0 1 0 0 0 0 0 0 0 1 0    0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 1 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 1 1 0 1    0 0 0 0 0 2 0 3 4 7 18 27 47 82 134 163 133 138 101 58 34 26 10 5 2 1 2 1 1 0    2 1 0 0 0 0 1 0 0 1 0 0 0 0 0 0 0 0 1 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0    0 0 0 0 0 0 0 0 0 0 0 0 0 2 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0    0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0   0.042000 0.650 0.650 2.900        27719           5           0  0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0    0 0 1 0 0 0 0 0 0 0 0 0 0 1 0 0 1 0 0 0 0 0 0 1 0 0 2 0 0 0 0 0 0 0 0 0 0 0 0    0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 2 0 0 0 0 0 0 0 0 0 0 0 0 0 0    0 0 1 0 0 0 1 1 2 8 16 37 51 87 128 153 146 123 105 62 35 24 8 3 5 0 1 2 1 0 0   0 1 1 1 0 0 0 1 0 1 0 0 2 1 0 0 0 0 0 0 0 0 0 0 0 1 1 0 0 0 0 0 0 1 0 0 0 0 0    0 0 1 0 1 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 1 0 0 0 0 0 1 0 0 0 0 0 0    0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0   0.044000 0.700 0.700 3.000        32922           5           0  0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 1 0 0 0 0 0 0 0 0 0 0 0 1 0 0    0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 1 0 0 0 1 0 0 0 0 2 0    0 0 0 0 0 0 0 2 1 0 0 0 0 1 1 1 1 0 0 1 0 0 0 1 0 0 0 0 0 0 1 1 0 0 0 1 0 1 1    1 1 0 0 0 1 4 3 5 5 15 35 54 88 132 168 149 105 92 62 30 16 17 4 5 1 0 0 1 0 1   1 0 1 1 0 0 0 1 0 0 1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 2 0 0 0 1 0 0 0 0 0 0 0    0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0    0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0   0.046000 0.750 0.750 3.100        38973           3           0  0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0    0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1    0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 1 0 1 0 0    0 0 0 1 0 0 0 4 3 5 20 37 56 94 110 135 149 124 84 58 36 17 14 7 1 0 2 0 1 0 0   1 1 0 0 0 0 0 1 1 0 0 0 1 0 1 1 0 0 1 1 1 0 0 0 0 1 1 0 0 1 0 0 0 0 1 0 0 0 1    1 0 1 0 1 0 1 1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0    1 0 0 0 0 0 1 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0   0.048000 0.800 0.800 3.200        45376           5           0  1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0    0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 1 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0    0 0 0 0 0 0 0 1 0 0 0 1 1 0 0 1 1 0 0 2 1 1 2 0 0 0 1 0 0 0 0 0 1 0 0 0 0 1 0    0 0 0 1 0 0 0 0 1 3 18 34 55 82 104 135 116 99 79 60 51 29 10 4 3 1 1 1 0 0 1    0 0 0 1 0 0 3 1 2 1 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 2 0 0 0 0 0 0 0 0 0 0 0 1    0 0 0 0 1 0 0 0 1 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0    1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0   0.050000 0.850 0.850 3.300        52060           3           0  0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0    0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 1 0 1 0 0 0 0 0 0 0 0 1 0 0    0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 1 0 0 0 1 1 0 0 0 0 1 1 0 0 0 1    0 0 0 0 0 2 2 1 3 12 24 40 39 107 121 127 138 100 86 68 44 23 15 7 3 1 1 0 1 1   0 0 2 0 0 0 0 0 1 0 1 0 1 0 0 0 0 0 0 0 0 1 0 0 1 1 0 1 0 0 0 2 0 0 0 1 0 0 0    0 0 0 0 0 0 0 0 0 0 0 0 2 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0    0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0   0.052000 0.900 0.900 3.400        59454           3           0  0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 2 0 0 0 0 1 0 0 0 1    0 0 0 1 0 1 1 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 1 0 1 0 0 0 0 0 0 0 0    0 0 0 0 0 1 0 0 0 0 0 2 0 0 0 0 0 0 1 0 0 0 0 1 0 1 0 1 0 0 2 0 2 1 0 0 0 1 0    0 1 0 0 0 0 0 3 3 6 21 32 68 90 132 111 122 107 73 57 47 24 11 7 4 2 2 1 0 0 0   0 0 0 0 0 1 0 0 1 0 0 2 0 1 1 0 0 1 0 0 0 0 0 3 0 1 0 0 0 0 1 1 0 0 0 1 0 0 0    0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0    0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0   0.054000 0.950 0.950 3.500        67013           3           0  0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0    0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0    0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 1 0 1 0 1 0 0 0 0 1 0 0 1 1 0 0 0    1 0 1 0 1 2 4 3 7 9 28 31 71 94 115 96 108 78 82 60 38 17 12 11 4 3 1 1 0 2 1    0 0 0 2 1 3 0 0 0 0 3 0 0 1 0 0 0 0 0 0 0 2 0 0 0 1 0 2 0 1 0 2 0 1 0 0 1 0 0    0 1 0 0 0 1 0 0 1 0 1 0 0 0 0 0 1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0    0 0 0 0 0 1 0 0 0 0 1 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0   0.056000 1.000 1.000 3.600        75475           3           0  0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0    0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0    0 2 0 0 0 0 0 0 0 0 0 0 0 0 1 2 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1 0 0 0 1 3 0 0 1    1 2 0 1 4 0 1 8 6 7 17 41 56 71 109 113 84 103 72 54 35 22 6 9 1 7 5 4 0 0 1 0   0 0 0 0 0 1 0 0 2 1 0 0 0 0 2 0 0 1 0 0 1 0 0 0 0 0 0 1 0 2 0 1 0 0 0 0 1 0 1    0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 3 0 0 0 1 0 0 0 0 0 0 1 1 0 0 2 0 0 0 0    0 0 0 0 1 0 0 0 1 0 1 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0   0.058000 1.050 1.050 3.700        83558           3           0  0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0    0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 1 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1 1 0 0    0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 1 0 0 1 0 1 0 1 0 0 0 0 0 0 0 0 1 2 0 0    2 0 0 1 0 3 2 3 6 15 27 41 77 73 94 94 92 76 61 56 42 23 13 11 6 2 1 2 0 1 2 0   0 1 0 1 0 0 1 0 0 1 1 1 0 0 0 1 0 0 0 1 0 0 0 0 1 1 0 0 0 0 2 0 0 0 0 0 1 2 0    0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 1 1 0 0 0 1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0    0 0 1 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0   0.060000 1.100 1.100 3.800        93087           3           0  0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 1    0 0 0 1 0 0 0 0 0 0 1 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 1 0 0 1 0 0 0 0 0 0    0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 1 0 0 0 0 1 2 2 0 0 0 1 0 1 1 0 0 0 1 1 0 4    0 0 1 2 0 3 1 3 5 13 33 31 65 75 77 96 97 80 59 45 36 32 18 2 5 0 1 0 0 1 0 0    3 0 0 0 0 1 0 0 0 0 0 1 0 0 1 2 0 0 0 0 1 0 0 0 0 1 0 1 1 1 0 0 2 0 0 2 0 1 0    0 0 0 0 0 0 1 2 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0    0 1 1 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0   0.062000 1.150 1.150 3.900       102829           3           0  0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 1 0    0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 1 0 0 1 0 1 0 0 0 1 0 1 0 0 0 0 0 0 0 0 0 1 0 0    0 0 0 0 0 1 1 1 0 0 0 0 1 1 0 0 1 0 1 0 0 0 0 0 1 1 1 0 1 0 1 1 0 1 1 0 2 0 2    1 2 0 0 2 4 3 5 11 9 23 43 53 68 65 87 83 77 59 49 34 18 15 9 4 2 3 2 0 0 0 4    0 1 1 0 0 2 0 0 1 0 0 0 0 1 1 1 0 1 0 0 0 0 2 0 0 0 0 1 0 0 1 1 1 1 0 0 0 1 0    0 1 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 1 0 0 0 1 0 0 1 0 1 0 0 0 0 0 0 1 0 0 0    0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0   0.064000 1.200 1.200 4.000       113442           3           0  0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0    0 0 1 0 0 0 0 0 0 0 1 0 0 0 0 0 1 0 0 0 1 0 1 0 0 1 0 0 0 1 0 0 0 0 0 1 0 0 0    0 0 0 0 0 1 0 1 0 1 0 0 0 0 0 1 0 0 0 0 1 0 0 0 1 0 1 1 1 0 1 1 1 1 1 0 0 0 1    2 0 0 0 2 0 4 5 11 13 29 39 61 68 61 75 76 74 73 44 37 29 19 6 3 3 2 0 1 2 1 0   0 0 0 1 1 1 0 1 1 0 0 0 1 0 1 1 0 1 2 0 2 1 1 1 0 0 0 0 1 0 0 1 1 1 1 1 0 0 0    0 0 0 0 1 0 0 0 0 2 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 1 0 0 0 0 0    0 1 0 0 1 0 0 0 0 0 0 0 0 0 1 0 0 1 0 0 0 0 0 0 0 0 0 0 0   0.066000 1.250 1.250 4.100       126668           3           0  0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0    0 0 1 0 0 0 0 0 0 0 0 0 2 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 1 0 0 0 0 0 0 0 1 0 1    0 0 0 0 0 1 0 0 0 0 0 1 0 0 1 1 0 0 0 1 1 2 3 0 2 1 2 0 1 0 3 0 0 0 1 0 1 1 3    0 0 1 3 0 2 4 3 12 12 30 48 56 66 77 78 71 82 52 31 32 19 20 16 8 2 1 3 0 0 2    1 0 1 0 1 0 0 0 1 3 1 0 1 0 1 1 1 0 0 0 0 0 2 0 2 0 0 0 0 0 1 0 0 0 0 1 1 0 0    0 0 0 1 0 0 0 0 0 2 0 3 1 0 0 1 0 0 0 0 0 0 1 0 1 1 0 0 0 1 0 0 0 0 1 0 0 0 0    0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0   0.068000 1.300 1.300 4.200       138042           3           0  0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 1 1 0 2 0 0 1 0 1 0 0 0 0 0    0 0 0 1 0 0 2 0 0 0 0 0 1 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0    0 1 0 0 0 0 0 0 0 1 0 0 1 0 0 0 1 0 0 0 0 3 0 0 1 0 0 1 2 0 0 0 3 0 1 0 0 3 0    1 0 1 1 3 1 4 7 11 14 27 36 44 68 72 70 71 45 44 46 29 13 16 11 5 2 0 3 0 0 0    0 1 1 2 0 0 1 1 2 1 1 0 1 0 0 0 0 0 0 0 0 0 0 1 0 1 1 0 1 2 0 0 1 1 0 1 1 1 0    0 1 0 0 1 0 1 1 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0    0 0 0 1 0 0 1 0 0 0 0 2 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0   0.070000 1.350 1.350 4.300       152335           3           0  0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 1 0 0 0 0    0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 2 0 0 0 1 0 0 0 0 0 0 0 0 1 0 1 0    1 0 0 0 2 0 0 0 0 0 0 1 1 0 0 0 0 0 0 0 2 0 0 0 0 1 1 1 0 1 1 0 1 1 1 1 0 2 0    0 0 0 0 2 0 1 7 14 19 34 35 54 72 68 72 68 58 48 36 37 27 25 17 1 4 1 0 0 0 1    2 2 0 0 1 1 1 2 1 0 3 1 0 1 0 2 1 0 0 0 1 1 1 2 0 0 0 0 1 1 0 1 1 0 2 1 1 1 1    0 0 0 1 1 0 0 2 0 0 1 0 0 0 1 1 0 2 1 1 0 0 0 0 2 0 0 0 0 0 0 0 1 1 0 0 0 0 1    0 0 1 0 0 0 0 0 0 0 0 2 0 0 0 0 1 0 0 0 0 1 0 0 0 0 0 0 0 0   0.072000 1.400 1.400 4.400       166280           4           0  0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0    0 1 0 0 0 1 0 0 0 1 0 0 0 0 0 0 0 0 1 0 1 1 0 1 0 0 0 0 1 0 0 0 0 1 0 0 0 0 0    2 0 0 0 0 0 0 0 1 0 1 0 1 1 1 0 0 1 0 1 0 0 3 4 2 2 0 0 0 0 0 1 1 3 1 0 3 2 2    1 2 2 0 2 2 1 8 14 26 24 29 47 47 68 65 63 55 42 41 26 29 17 8 4 4 1 0 1 2 0 0   0 1 1 2 0 1 2 1 0 0 1 1 1 0 0 1 0 0 0 1 0 0 1 2 1 2 1 0 0 0 0 0 1 1 2 0 2 2 0    0 0 0 1 1 1 0 0 0 1 0 0 0 1 0 0 0 1 0 0 0 0 0 0 0 0 0 1 0 0 0 1 0 0 0 0 1 0 0    0 1 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 1 0 0 0 0 0 0 0 0 0   0.074000 1.450 1.450 4.500       179484           3           0  0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 1 0 0 1 0 0 1 0 0 0    1 0 0 1 0 0 0 0 0 0 0 0 0 0 0 2 1 0 0 1 0 1 0 0 1 0 1 2 0 0 0 0 0 0 0 0 0 1 0    0 0 1 0 1 0 1 0 1 1 0 0 0 0 0 0 0 0 1 1 0 0 0 1 0 1 1 0 1 1 1 2 0 0 1 1 2 1 0    1 1 2 2 0 1 5 6 10 20 43 50 57 62 53 62 66 45 42 33 27 26 23 14 3 0 2 0 1 0 0    1 1 0 0 2 1 1 0 0 3 0 1 1 1 0 1 1 0 1 0 1 2 1 0 0 1 2 0 2 0 0 0 0 1 1 3 1 0 0    2 1 1 1 0 0 0 0 0 0 1 2 0 1 0 0 0 0 0 1 1 0 2 0 0 0 0 0 1 0 2 1 0 0 0 0 0 0 1    0 0 0 0 0 0 0 0 1 1 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0   0.076000 1.500 1.500 4.600       197657           3           0  0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 2 0 0 0 1 1 0 0 0 0 0 0 1 0 1 0    0 0 0 0 0 0 0 0 0 0 0 2 0 0 0 0 0 1 0 0 0 0 1 0 0 0 0 0 0 1 2 0 0 0 1 0 0 0 0    0 0 1 0 1 0 0 0 0 0 0 0 0 1 2 0 0 0 2 1 1 0 1 1 0 1 1 3 2 1 1 2 1 0 1 0 0 0 0    0 1 1 1 0 5 3 7 12 24 38 32 41 48 54 66 71 49 46 31 38 25 15 8 6 6 5 0 1 3 0 1   1 1 1 1 0 1 2 0 1 0 0 0 1 0 2 1 2 0 0 0 0 1 3 1 0 0 0 0 1 1 0 1 0 1 1 1 1 1 0    4 1 1 1 0 3 0 0 0 2 1 0 0 0 0 0 0 0 1 0 0 0 0 0 0 1 0 1 1 0 0 0 0 0 0 0 0 0 0    0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 1 0 0 0 0 0 1 0 0 0 0 0 0 0   0.078000 1.550 1.550 4.700       212054           3           0  0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 1 0 0 1 0 0 1 0 0 0 0    0 1 0 1 1 0 0 1 0 0 1 0 0 0 0 0 0 0 1 1 1 0 0 1 0 0 0 0 0 0 0 0 0 1 0 0 0 0 1    0 0 2 0 0 0 1 0 0 1 0 1 1 0 1 3 1 0 0 1 2 0 0 0 1 0 0 0 0 0 2 1 2 1 1 1 0 0 1    5 1 1 2 3 5 7 9 11 22 31 37 48 50 52 54 57 37 38 38 33 24 11 19 11 3 1 2 0 3 3   2 1 0 1 3 0 1 1 1 1 1 2 0 0 0 1 1 2 0 1 1 3 0 1 1 0 0 1 0 2 0 1 0 0 1 3 0 2 0    1 0 1 2 0 1 1 1 1 1 0 3 0 1 0 0 0 1 0 0 0 1 0 1 0 0 0 0 0 0 1 1 0 0 0 0 0 1 0    0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 1 0 0 1 0 1 0 0 0 0 0 0 0 0   0.080000 1.600 1.600 4.800       231971           3           0  0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 1 0 0 2 0 0 0 1 1 1 0 1 0 0 0 0 1 0 1 1    0 0 0 0 2 0 0 0 1 0 0 0 0 0 1 0 0 0 0 1 2 1 0 1 1 1 0 1 0 0 1 0 1 3 0 0 0 1 0    0 0 1 1 1 0 0 4 1 1 0 2 0 1 1 1 2 0 0 0 1 0 1 2 1 2 3 2 0 1 0 4 3 1 1 1 1 3 1    0 0 0 2 1 0 2 7 17 13 29 47 58 59 52 38 51 51 38 34 35 21 14 13 4 1 0 1 1 1 0    2 2 4 1 0 1 1 4 0 0 0 2 0 2 2 2 0 0 1 3 2 1 1 2 2 2 2 1 0 3 0 2 1 2 1 2 2 0 0    1 1 0 2 0 2 2 0 1 0 2 2 3 1 2 3 1 1 0 1 0 2 0 1 2 1 2 0 2 1 0 0 3 0 0 1 1 1 1    0 0 1 0 0 1 0 0 0 0 0 0 1 0 0 0 1 0 0 0 1 0 0 0 0 0 0 0 0 0   0.082000 1.650 1.650 4.900       252503           3           0  0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1 0 0 0 0 0 2 0 0    0 0 0 0 0 1 0 0 0 1 1 0 0 1 0 0 0 0 0 1 0 1 0 0 0 0 0 0 0 0 0 0 1 1 0 0 0 0 0    0 0 0 0 2 0 0 1 0 1 2 2 2 1 0 2 0 1 0 1 1 2 2 0 3 0 0 4 1 0 0 3 0 0 1 2 0 1 1    1 3 0 1 0 2 9 11 25 27 34 53 41 49 43 47 36 31 38 22 30 22 18 9 5 9 2 2 1 2 2    3 1 4 1 1 0 0 1 2 0 2 1 0 0 1 3 2 2 1 0 0 0 1 2 1 0 0 0 2 1 1 0 2 0 0 1 0 0 2    1 3 1 1 1 0 2 1 1 0 2 1 0 1 3 0 0 0 0 2 0 0 1 0 0 0 0 0 1 2 1 1 1 0 2 1 0 0 0    2 0 1 0 0 0 0 1 0 0 0 0 1 0 0 2 0 1 0 1 0 0 0 0 0 0 0 0 0 0   0.084000 1.700 1.700 5.000       267889           3           0  0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 1 1 0 1 1 0 0 0 0 0 0 0 1 0 1    0 1 0 0 0 0 0 0 0 0 0 1 0 0 1 0 0 1 0 0 0 1 1 0 0 0 0 1 0 0 0 0 0 0 0 0 0 1 0    0 1 0 1 1 0 3 0 1 1 1 0 1 2 1 0 2 0 2 4 0 1 0 0 0 1 1 0 1 3 2 0 2 0 4 0 0 2 0    1 4 2 4 3 3 6 10 14 28 37 54 36 40 52 40 50 46 40 32 26 29 12 18 5 2 0 2 4 1 2   1 0 2 1 2 2 1 0 1 0 2 1 2 4 1 1 5 1 0 2 0 1 2 3 2 2 1 2 1 0 2 1 2 1 1 4 1 2 1    4 0 2 2 0 0 3 1 0 2 0 0 1 1 1 0 0 2 1 0 0 0 0 0 0 0 1 1 1 1 0 0 0 1 0 0 0 1 0    0 0 0 0 0 0 0 0 0 0 1 1 0 0 0 1 0 0 0 1 0 0 0 0 0 0 0 0 0 0   0.086000 1.750 1.750 5.100       290294           3           0  0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 2 0 2 0 0 0 1 0 0 0 0 1 0 1 0 0 1 0 0 0 0 0 0    0 0 0 0 1 0 0 0 0 1 0 0 0 1 1 3 1 1 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 1 1 1 0 0 2    1 0 1 0 1 0 0 2 2 0 1 2 2 0 2 0 2 0 1 0 0 1 1 1 3 1 1 1 1 3 4 1 1 2 2 2 1 0 3    0 0 0 2 4 5 6 16 18 20 31 40 54 55 46 41 52 35 27 21 28 27 20 15 8 6 7 1 0 0 3   0 0 2 2 0 3 1 3 1 1 2 0 0 1 2 1 3 2 0 1 2 1 3 1 1 1 1 1 2 0 2 1 0 1 1 1 3 1 1    2 0 1 0 1 0 2 1 1 0 0 1 2 0 3 1 1 0 0 0 1 3 1 1 1 0 0 1 2 1 0 0 1 1 1 0 0 1 0    0 0 0 0 0 2 0 1 0 0 0 2 1 0 2 0 0 0 0 1 1 0 1 0 0 0 0 0 0 0   0.088000 1.800 1.800 5.200       312476           6           0  0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1 0 0 0 0 1 1 0 0 0 1 0 1 0 1 1 0 0 0 0    0 0 2 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 1 0 1 2 0 0 0 1 0 1 0 0 0 0 0 0 2    1 0 0 1 0 0 1 1 1 1 4 2 0 1 0 0 3 0 0 0 0 0 1 1 4 0 0 0 0 1 1 2 1 0 3 0 0 2 2    4 0 3 1 6 9 10 13 21 24 32 43 33 41 43 49 50 32 26 31 27 12 16 17 3 3 3 5 0 3    0 2 1 3 3 2 1 2 3 1 2 1 1 1 2 0 1 1 0 2 0 3 0 0 2 0 0 0 0 1 0 1 1 3 3 0 1 1 1    1 1 1 2 2 2 0 3 1 0 2 2 2 0 0 0 0 3 1 2 5 1 1 2 0 0 3 3 0 2 2 0 0 0 0 1 2 0 0    1 0 0 1 1 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0   0.090000 1.850 1.850 5.300       337348           3           0  0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 1 1 2 0 1 0 1 0 0 0 1 0 0 0    0 0 0 1 0 0 0 0 2 0 1 1 0 0 0 1 0 1 0 0 0 0 1 0 1 0 0 0 0 0 0 0 0 1 1 0 0 0 0    2 0 0 0 1 3 2 0 0 2 2 3 3 2 2 2 0 0 1 1 3 1 3 0 0 0 0 0 0 1 2 1 2 1 2 2 2 0 1    1 0 4 2 2 7 6 15 22 21 39 37 50 31 51 30 33 34 34 26 21 14 13 10 9 4 3 3 4 2 2   0 1 2 3 3 0 1 3 2 5 3 2 2 4 0 2 3 0 4 2 1 2 2 2 4 2 1 3 1 3 2 1 3 1 2 4 1 1 1    1 2 4 1 3 3 3 1 0 4 1 0 1 1 1 1 2 3 0 3 0 0 4 1 1 1 0 2 2 2 1 2 2 0 1 1 0 0 0    2 0 1 0 1 0 0 1 0 0 0 1 3 0 0 1 0 0 1 1 1 0 0 1 0 0 0 0 0 0   0.092000 1.900 1.900 5.400       357303           3           0  0 0 0 0 0 0 0 0 0 0 0 2 0 0 0 0 0 0 0 0 1 0 1 0 0 0 0 0 1 0 0 1 1 0 1 0 0 1 0    0 0 0 0 0 0 1 1 0 0 1 0 0 0 0 0 0 1 3 1 0 1 0 0 0 0 1 0 0 1 0 0 1 1 2 2 0 0 2    2 1 1 1 1 1 1 0 1 0 0 1 1 1 3 1 1 1 1 1 0 1 4 0 1 1 1 3 0 1 1 2 2 2 0 2 3 2 2    2 2 1 2 1 3 8 22 14 32 36 46 39 42 39 29 36 38 26 24 26 18 16 19 10 9 3 6 5 0    3 2 1 1 1 2 0 2 1 1 0 1 1 3 1 0 2 4 2 2 1 4 1 2 2 1 1 0 1 2 0 2 2 2 4 2 1 1 0    2 1 3 1 2 3 4 2 3 2 3 0 1 2 1 0 0 0 4 1 1 1 2 1 3 1 0 5 1 0 0 0 0 0 0 1 0 2 0    1 2 1 0 1 0 0 0 0 0 1 1 0 1 0 1 4 0 0 0 1 0 1 0 0 0 0 0 0 0 0   0.094000 1.950 1.950 5.500       383138           3           0  0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1 0 0 1 1 1 1 1 0 1 0 0 0 1 0 0 0 0 0 1 0    0 0 1 0 0 2 1 0 1 1 1 0 0 0 0 0 0 1 1 0 1 0 0 1 1 0 1 0 0 0 0 0 0 0 2 1 1 1 1    2 1 0 2 0 1 0 3 2 1 3 0 1 3 1 1 0 5 0 1 0 1 2 0 0 1 1 2 0 0 6 1 0 3 2 2 3 4 5    0 4 2 1 5 4 11 15 22 27 28 57 38 38 40 38 39 38 27 26 30 18 14 10 10 4 4 4 3 3   2 2 2 2 1 1 1 1 2 2 3 4 1 2 3 1 2 1 2 2 2 1 3 2 1 5 0 1 1 1 3 2 2 2 1 3 1 1 0    3 2 2 0 0 2 2 2 0 0 0 2 0 1 3 1 2 3 2 1 1 0 1 1 1 0 3 2 2 1 0 0 1 3 1 1 0 1 0    0 0 0 0 1 0 0 0 0 1 0 0 3 1 0 0 0 0 1 0 1 1 0 0 0 1 0 0 0 0 0   0.096000 2.000 2.000 5.600       409868           3           0  0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 1 0 1 0 0 0 1 0 0 0 0 0 0 1 0 1 0 1 0 2 0 0    1 0 0 0 1 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 1 0 2 0 1 0 0 2 0 2 0 0 0 0 1 0 0 2 1    2 2 2 1 2 1 1 1 1 1 2 0 0 1 1 0 1 0 2 1 2 0 2 0 3 1 2 1 3 1 5 0 2 2 1 2 4 1 2    0 3 1 4 7 5 9 13 22 19 31 27 28 41 34 39 37 22 23 21 22 17 23 15 8 9 3 8 0 3 1   2 2 2 3 1 0 4 2 4 2 2 2 2 4 2 1 1 0 2 0 3 0 3 2 2 1 2 2 1 4 1 2 2 1 1 5 2 1 2    1 2 2 1 0 2 4 3 2 1 2 2 3 2 3 1 2 1 1 1 1 2 1 1 2 2 1 2 3 2 1 1 0 2 2 4 0 1 1    1 1 1 0 0 1 1 3 0 0 0 0 0 1 0 0 2 0 1 2 0 1 1 1 0 1 0 1 0 0   0.098000 2.050 2.050 5.700       439102           3           0  0 0 0 0 0 0 0 0 0 0 0 0 0 0 2 0 0 1 1 0 0 1 0 1 0 1 0 0 0 0 1 1 0 1 0 0 1 1 0    0 1 1 0 0 1 1 0 1 0 0 0 0 0 0 0 1 2 0 0 1 1 1 1 2 0 1 1 0 0 0 0 1 1 1 0 4 0 0    0 2 1 1 0 3 4 0 1 2 2 1 0 3 0 3 2 0 0 2 0 1 0 0 1 0 1 3 1 3 5 0 2 2 3 5 2 2 2    0 3 2 3 6 5 16 21 19 23 28 29 35 42 42 44 39 33 23 30 18 25 24 15 13 5 4 2 2 0   3 3 0 0 1 3 0 1 1 3 2 4 3 4 2 1 1 1 3 1 0 0 2 2 4 2 2 1 4 2 4 2 2 2 1 2 2 1 2    0 4 2 2 3 1 2 1 1 2 2 1 2 4 2 1 4 1 2 2 2 2 0 2 0 3 0 1 0 2 1 0 4 2 1 3 2 1 0    2 1 1 1 1 0 1 1 2 1 1 1 2 0 1 0 2 1 1 0 0 1 0 0 1 0 0 0 0 0 0   0.100000 2.100 2.100 5.800       467340           3           0  0 0 0 0 0 0 0 0 0 0 0 0 0 2 1 0 0 1 0 0 1 2 0 0 0 0 0 1 0 2 0 0 2 0 0 1 1 0 0    0 1 0 0 1 1 0 0 0 0 1 1 0 0 1 0 0 1 0 0 0 1 1 0 0 0 0 0 1 0 1 0 0 0 0 1 2 0 2    2 4 1 0 1 1 2 3 4 1 4 1 5 1 2 1 0 2 2 2 1 5 4 1 5 4 0 1 2 4 2 2 0 2 1 2 5 4 1    1 1 2 5 7 9 16 23 31 15 22 36 36 44 42 29 31 28 28 18 35 12 10 13 8 4 3 2 2 5    1 2 3 3 1 3 3 5 2 0 3 4 1 2 2 3 0 0 5 2 3 6 2 1 2 5 3 4 3 1 1 1 1 2 2 4 0 2 3    1 2 1 2 4 5 4 3 5 2 1 2 0 5 0 2 2 4 1 0 4 1 0 2 1 2 0 0 1 3 2 4 3 0 2 3 3 3 4    2 2 0 0 0 0 1 1 0 3 2 0 1 2 0 4 2 1 1 1 2 0 0 0 0 0 0 0 0 0 0   0.102000 2.150 2.150 5.900       497495           5           0  0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1 1 1 0 1 0 2 1 0 0 0 0 1 0 1 0 0 0 0 1 2    0 0 0 0 0 2 0 0 1 0 1 0 0 0 0 1 1 0 0 0 1 1 1 1 2 0 0 1 0 0 0 1 0 2 2 1 0 0 0    2 0 2 1 1 1 6 3 2 0 3 2 2 2 1 1 3 4 1 0 1 2 4 2 3 3 1 1 1 1 3 3 1 4 1 3 4 3 2    3 1 2 2 5 11 11 14 26 27 28 28 28 36 39 42 29 33 24 20 29 18 13 17 13 6 10 4 3   3 6 1 0 1 0 2 1 3 2 3 1 2 3 1 2 1 2 0 2 2 3 1 3 1 1 2 4 4 1 4 3 2 2 3 5 5 3 0    2 5 3 5 1 4 1 1 3 4 2 2 2 2 1 3 0 1 1 2 2 4 2 1 3 2 0 1 2 1 0 2 3 1 2 0 0 0 2    0 0 1 3 0 0 1 2 0 3 1 0 3 1 2 2 1 1 2 0 0 0 0 2 0 0 1 0 0 0 0 0   0.104000 2.200 2.200 6.000       529288           3           0  0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 2 0 0    0 0 1 0 0 0 0 0 0 0 0 0 0 0 2 0 0 0 0 0 0 0 0 0 0 0 0 2 1 0 0 1 3 0 2 0 2 0 0    3 2 2 0 4 0 3 2 2 1 3 1 7 3 1 1 0 4 3 2 1 0 0 3 2 3 5 2 1 4 1 5 1 0 3 2 3 0 1    2 4 7 3 7 8 12 15 20 24 34 39 34 35 27 36 34 23 22 26 15 24 12 12 14 5 3 0 7 1   1 3 5 1 2 2 2 4 3 1 2 5 2 2 3 1 1 4 2 1 3 0 4 5 4 6 4 5 3 3 3 3 1 1 5 0 6 1 2    4 2 3 2 1 3 2 0 0 0 1 3 3 0 1 4 0 3 2 3 0 3 3 0 2 3 4 3 1 1 1 2 5 3 1 2 1 1 2    4 1 0 2 4 1 3 0 0 3 0 1 3 0 1 0 0 1 1 1 0 1 1 1 0 0 0 0 0 0 0   0.106000 2.250 2.250 6.100       560628           3           0  0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1 1 2 0 1 0 1 0 1 0 1 0 0 1 0 0 0 0 0 0 1 1 0 1    1 0 0 1 1 1 0 1 1 0 0 0 1 1 1 1 0 0 1 1 2 0 0 0 0 2 0 3 1 1 0 0 2 2 2 0 5 2 1    1 1 1 3 1 2 3 0 1 0 0 0 0 1 0 2 2 1 2 1 0 4 3 2 1 2 1 0 4 2 2 0 2 1 1 2 3 1 2    1 2 4 4 11 12 17 19 19 29 30 24 30 35 51 32 36 34 31 19 22 17 11 19 11 7 6 6 3   4 0 3 3 2 0 2 2 2 3 1 5 3 2 3 5 1 0 2 2 5 4 2 3 2 0 1 6 1 2 2 2 2 1 1 2 2 1 4    3 2 2 1 2 5 2 0 2 0 2 5 4 5 2 1 3 6 1 3 4 4 0 0 6 0 2 6 1 2 2 2 0 1 3 1 3 4 2    1 4 2 1 2 3 3 0 3 1 0 2 0 2 1 0 2 1 2 0 0 1 1 0 2 0 0 0 0 0 0 0   0.108000 2.300 2.300 6.200       593293           3           0  0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 1 2 0 2 2 1 0 0 2 0 1 0 1 0 0 1 2 2 1 0    0 1 0 2 0 0 0 0 0 1 1 1 1 1 0 0 1 1 0 0 1 1 1 2 2 1 0 1 1 0 1 5 0 2 4 1 0 1 4    2 1 3 2 2 3 2 3 2 0 0 3 4 3 1 3 2 2 0 3 0 2 4 0 3 2 5 1 2 1 4 6 1 2 4 0 3 6 1    7 6 4 5 4 10 16 24 22 20 40 37 44 34 29 21 28 36 36 27 23 24 14 10 4 5 2 5 3 6   2 3 3 1 4 2 1 5 1 3 5 3 2 1 2 2 6 2 3 1 1 0 5 3 3 3 4 5 2 2 3 3 5 5 1 6 2 3 2    6 0 5 2 4 3 5 1 2 2 5 1 2 3 1 2 2 2 4 2 5 5 2 2 2 5 0 1 2 5 2 3 2 3 1 1 2 4 0    2 1 4 2 1 1 1 0 1 2 0 0 1 3 1 0 2 1 1 3 3 2 0 0 0 1 2 0 0 0 0   0.110000 2.350 2.350 6.300       636559           3           0  0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 2 1 1 0 0 0 1 1 2 0 0 1 0 0 0 0 0 0 0    1 2 0 0 1 1 1 0 0 0 0 1 0 1 1 0 0 1 0 0 2 0 1 0 1 0 1 0 0 1 1 3 0 1 2 2 0 2 1    1 1 1 0 1 0 1 3 0 3 2 3 4 3 3 4 3 3 2 6 3 1 1 1 2 4 2 3 1 5 1 3 1 4 5 3 3 2 1    3 7 4 3 10 19 17 19 23 27 28 33 39 36 23 23 32 32 16 19 35 23 12 11 12 8 4 5 7   1 2 2 1 2 3 5 4 2 3 2 6 4 4 2 4 1 2 2 1 2 3 0 4 2 1 2 6 2 2 1 3 3 1 6 4 8 5 2    3 5 2 3 0 3 2 3 1 2 2 3 4 3 8 6 2 1 4 6 3 1 2 0 2 0 2 5 0 3 3 3 3 1 3 3 2 5 4    2 1 4 2 2 4 4 1 3 2 5 2 3 1 2 0 4 0 1 0 6 3 1 2 0 2 0 1 0 0 0 0   0.112000 2.400 2.400 6.400       670484           3           0  0 0 0 0 0 0 0 0 0 0 1 0 1 0 0 0 0 0 0 1 1 1 0 1 0 0 0 1 1 0 0 0 0 0 0 0 0 0 2    0 1 1 1 3 0 0 0 2 1 3 0 1 1 1 0 1 1 1 0 0 1 2 0 1 3 1 5 2 3 0 4 0 2 0 0 1 2 1    0 1 0 0 1 0 2 2 3 2 3 2 2 2 3 4 4 2 3 5 3 3 2 3 3 4 2 4 0 3 2 4 4 1 3 1 3 4 2    2 5 2 8 6 12 17 14 22 27 26 29 39 30 24 36 22 22 20 9 19 15 5 12 16 4 7 5 7 5    5 1 4 5 5 4 4 1 4 4 3 3 3 4 2 2 4 2 4 4 4 4 0 2 3 2 1 4 3 6 1 3 3 3 4 5 4 2 2    2 5 3 0 2 5 4 2 5 3 5 1 1 3 1 1 3 6 6 2 3 2 0 3 2 4 3 4 1 2 2 6 2 0 3 2 2 5 3    3 5 2 1 0 3 1 1 2 2 0 1 1 3 2 3 2 1 1 1 1 3 2 1 0 0 0 0 0 0 0   0.114000 2.450 2.450 6.500       711783           4           0  0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 2 1 0 0 1 0 2 1 2 0 1 0 0 1 0 0 1 1 1 1 0 0 0 1    1 2 0 1 1 0 0 0 2 1 1 1 1 1 2 1 2 3 3 1 1 1 2 3 1 3 2 2 1 0 1 1 4 4 4 1 0 4 0    0 1 1 2 1 3 2 0 3 4 1 1 1 1 3 2 0 1 3 2 1 2 1 0 3 3 2 5 4 2 5 3 4 2 2 5 3 3 3    3 5 5 8 7 14 12 28 22 24 23 36 33 26 32 27 26 18 30 24 15 13 19 15 17 6 5 7 5    4 3 5 3 1 4 4 9 5 3 1 4 0 0 6 2 5 3 3 3 1 2 3 2 4 1 5 5 3 8 2 1 1 4 1 7 5 6 6    4 4 3 2 6 3 3 3 3 1 3 4 5 4 3 4 3 1 2 3 1 2 1 2 2 6 5 2 2 2 4 2 2 0 2 3 3 2 7    4 4 1 4 2 0 3 1 1 2 1 2 3 1 3 2 2 4 3 1 4 0 0 4 2 2 2 1 0 0 0 0   0.116000 2.500 2.500 6.600       745364           5           0  0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 2 0 0 0 0 1 2 1 1 2 1 1 1 0 1 0 2 0 1 1    0 1 0 1 0 0 0 0 0 0 1 0 1 0 0 0 0 0 1 1 2 3 0 1 4 4 0 4 0 1 0 1 3 3 0 2 1 2 3    2 1 1 1 2 0 4 0 0 4 5 2 5 4 1 3 5 5 4 0 4 4 2 3 2 3 5 2 2 4 2 3 4 2 3 3 3 3 3    2 4 12 10 13 14 19 22 23 24 36 19 32 25 25 36 24 18 20 21 14 18 13 8 6 9 2 9 5   2 5 3 4 4 3 3 0 4 3 2 5 3 4 2 2 6 3 4 0 2 4 1 3 4 7 4 5 3 2 4 5 5 3 4 4 4 2 3    2 4 4 2 1 5 7 1 5 2 4 1 5 5 3 4 4 3 2 4 2 4 0 6 2 3 4 1 2 2 2 4 1 4 2 2 2 5 6    5 1 4 4 2 3 3 3 1 4 3 4 2 6 2 5 3 2 2 1 3 2 2 5 1 1 0 0 1 0 0 0   0.118000 2.550 2.550 6.700       791846           4           0  0 0 0 0 0 0 0 0 0 0 0 1 0 1 0 2 1 1 0 0 0 0 0 1 0 0 0 1 1 0 1 0 1 0 1 1 0 1 0    1 4 1 2 3 0 3 1 0 1 1 1 0 3 1 2 1 1 1 0 0 1 1 1 3 1 3 2 3 1 2 2 1 3 2 4 1 4 0    2 4 1 4 3 2 1 1 2 1 3 2 3 3 2 1 1 5 3 3 3 3 2 3 4 3 5 3 1 1 2 2 3 5 1 2 1 1 4    4 6 9 6 6 13 17 21 20 24 22 25 20 29 23 28 30 26 27 18 20 17 16 17 12 10 8 5 6   6 6 4 3 1 2 4 6 9 2 2 3 5 7 6 2 3 8 5 4 5 6 4 6 5 3 5 3 2 5 3 2 8 3 5 4 5 3 5    4 3 4 8 4 3 8 3 3 3 1 1 2 2 5 4 7 3 2 3 3 2 2 3 6 3 2 2 1 1 5 2 5 6 3 5 3 4 1    3 1 2 1 0 4 1 4 2 2 2 3 1 1 1 1 3 2 0 1 6 1 1 0 2 1 0 1 0 0 0 0   0.120000 2.600 2.600 6.800       833394           3           0  0 0 0 0 0 0 0 0 0 0 0 1 0 0 2 2 1 1 1 2 1 0 0 0 1 0 1 0 0 0 1 0 0 1 1 2 1 0 0    0 0 0 2 2 0 3 1 0 0 2 1 1 1 1 0 1 2 1 5 0 1 0 2 2 1 2 0 4 2 1 4 3 4 2 2 1 2 1    5 2 3 1 3 0 2 2 2 2 3 4 0 4 2 3 3 4 5 2 2 6 3 4 5 5 5 3 4 6 5 1 3 0 5 4 5 1 3    2 2 6 18 13 17 27 27 21 28 28 24 26 27 29 23 21 16 17 19 22 14 11 9 5 14 7 7 6   4 4 12 3 6 4 5 4 6 4 2 0 1 8 1 6 8 5 2 3 4 5 6 4 2 5 8 3 1 1 6 3 7 8 4 1 6 5 2   8 11 5 6 5 6 2 4 5 1 2 7 2 2 5 5 6 3 3 2 3 8 5 1 9 3 3 2 3 6 3 5 3 2 4 6 3 1 3   5 4 4 4 6 3 3 5 0 2 2 5 1 3 2 2 1 4 2 0 2 2 2 2 4 1 2 1 2 1 1 0   0.122000 2.650 2.650 6.900       876007           3           0  0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 2 1 1 1 1 2 2 1 0 0 1 0 0 0 1 1 0 0 0 2 0 0    4 1 0 2 1 2 0 1 2 0 1 3 2 1 0 1 1 0 1 2 1 0 2 3 3 5 3 3 3 0 1 4 0 1 5 3 4 3 1    2 2 2 4 1 3 3 3 2 3 2 3 2 1 4 4 2 2 5 5 3 4 1 2 1 2 4 2 4 7 2 4 4 2 7 3 5 7 5    3 6 8 10 10 18 21 22 24 14 25 27 29 31 22 25 24 21 27 20 19 22 19 14 13 14 10    5 7 3 4 5 5 3 1 4 3 8 4 5 4 0 3 4 3 4 1 7 6 1 1 3 4 4 3 4 3 6 4 3 4 2 4 4 3 5    6 5 1 1 6 2 6 6 3 5 5 3 2 6 5 4 3 4 6 4 3 5 5 6 5 6 2 4 2 1 2 2 4 2 7 6 2 1 3    1 5 2 1 2 4 3 3 3 2 5 2 4 1 4 3 2 2 5 5 1 1 3 3 2 2 2 2 1 0 0 0 0 0   0.124000 2.700 2.700 7.000       925764           3           0  0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 1 2 1 3 0 1 1 0 0 0 0 0 1 1 1 1 0 0 0 1 1 0    1 2 0 0 3 2 0 1 2 1 1 2 0 2 1 2 2 0 0 2 3 2 3 2 2 3 2 2 4 0 2 0 5 1 3 2 3 1 2    3 2 0 6 4 3 6 2 5 0 5 2 1 4 4 5 7 4 2 3 5 2 0 2 5 2 4 7 4 4 4 8 5 3 1 7 2 2 1    5 5 5 14 19 16 22 18 30 29 25 36 23 23 22 25 25 27 26 23 14 20 16 16 10 6 6 6    4 2 6 6 6 6 6 4 6 1 0 3 4 4 5 2 4 3 2 4 4 5 5 5 6 10 6 3 6 8 5 5 8 7 4 6 4 3 4   8 5 5 7 4 6 3 5 8 4 3 4 4 3 4 3 1 3 3 7 2 4 8 3 6 4 3 3 2 5 4 4 3 7 4 5 4 4 3    4 7 2 3 3 4 3 0 2 2 4 3 4 2 4 2 2 6 4 4 6 6 1 5 1 1 2 1 0 0 0 0 0   0.126000 2.750 2.750 7.100       969560           3           0  0 0 0 0 0 0 0 0 0 0 0 0 0 2 1 1 1 0 1 2 0 2 0 2 2 0 1 1 1 0 0 1 0 1 1 1 1 2 0    1 2 2 1 2 0 0 1 0 1 0 2 1 0 1 0 1 1 2 0 3 0 3 4 3 1 3 2 0 4 0 1 2 0 3 1 1 2 3    2 2 2 5 1 7 1 5 1 5 4 2 0 0 1 2 1 3 2 3 3 5 4 10 10 2 5 11 4 1 2 1 7 3 5 4 4 1   5 10 8 7 9 9 20 20 21 33 21 28 20 27 32 21 29 22 20 24 15 13 27 14 13 15 10 9    3 11 6 7 5 3 6 8 5 4 4 1 3 3 5 2 7 3 6 6 1 6 4 6 5 3 4 2 4 3 3 9 4 5 4 4 5 2 3   10 4 3 2 6 10 6 3 6 5 5 5 4 8 8 5 4 3 6 4 4 2 4 4 4 5 7 4 4 4 4 5 2 2 3 4 5 2    1 3 2 6 2 7 7 1 6 4 4 6 5 5 4 0 2 2 3 2 7 5 0 4 1 1 4 6 1 0 3 2 0 0 1   0.128000 2.800 2.800 7.200      1022713           5           0  0 0 0 0 0 0 0 0 0 0 0 1 0 2 0 0 0 1 0 1 1 0 0 1 1 1 0 0 0 2 1 0 0 4 0 0 1 2 3    1 1 0 1 0 1 0 3 1 1 1 2 2 1 1 1 3 1 0 2 4 2 1 2 1 2 0 3 1 3 2 1 5 2 1 3 1 2 1    5 3 2 1 2 5 3 8 2 3 2 5 5 4 3 6 4 4 4 3 2 3 8 4 3 4 5 4 5 4 7 6 5 3 3 3 5 2 9    10 7 9 12 11 13 17 15 22 19 33 24 28 30 26 21 24 22 27 20 26 16 10 10 9 20 10    7 4 5 7 7 2 7 5 3 5 1 6 1 5 7 5 6 3 1 5 1 1 3 4 8 6 3 9 5 5 3 6 7 4 6 7 6 4 2    4 6 2 3 6 5 6 7 6 4 4 9 6 8 6 9 7 1 2 6 2 7 5 4 4 4 4 5 5 4 4 3 6 3 5 3 6 4 3    6 6 2 5 2 8 4 5 3 6 5 4 5 8 4 3 5 6 5 5 2 8 1 2 2 5 4 1 3 0 0 0 0 0   0.130000 2.850 2.850 7.300      1081669           3           0  0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 1 5 0 0 2 2 0 0 1 0 0 0 1 1 0 2 0 2 2 2 1 0    1 0 2 2 3 1 1 0 2 0 1 0 2 1 1 2 2 0 1 4 3 0 2 1 1 0 2 5 2 1 0 1 3 2 5 2 1 2 5    2 3 4 3 6 6 6 4 6 6 3 1 3 2 3 4 7 5 2 9 7 4 1 4 4 3 2 2 2 7 4 8 4 7 4 6 8 5 1    8 6 10 18 21 18 15 21 24 21 26 22 30 28 27 23 22 21 17 25 20 17 13 17 9 12 7 8   5 4 4 5 5 2 4 1 1 2 5 7 6 4 9 7 7 5 5 5 5 5 2 4 5 3 6 8 2 4 9 4 10 5 1 4 5 5 5   10 3 2 8 6 5 7 3 13 3 3 6 5 1 4 5 9 5 2 7 4 5 6 3 5 6 5 4 5 9 6 4 3 4 4 4 5 8    5 5 0 3 6 3 4 3 7 5 6 4 3 3 6 8 4 1 3 1 2 7 3 4 6 6 1 3 4 1 0 1 0 0   0.132000 2.900 2.900 7.400      1131887           3           0  0 0 0 0 0 0 0 0 1 0 0 1 2 1 1 0 0 0 1 2 2 1 1 0 2 1 1 0 1 1 1 0 2 2 3 1 0 1 0    1 0 2 0 2 0 1 4 0 1 2 2 0 0 0 2 3 0 1 2 3 0 1 2 3 5 6 2 2 3 1 4 4 8 4 3 3 3 7    2 2 5 7 4 1 2 4 8 1 5 2 7 3 4 2 9 6 5 5 6 2 2 3 6 2 5 6 7 7 2 8 3 3 3 3 6 6 5    3 10 15 15 17 19 13 29 20 23 22 34 28 28 33 20 20 22 17 22 18 15 19 14 11 9 13   6 6 13 4 2 9 8 8 7 6 5 6 4 4 9 6 2 8 9 7 2 6 3 7 3 6 3 7 4 4 5 4 5 6 4 7 5 4     10 2 6 6 8 3 6 6 9 5 8 8 7 6 4 8 5 7 5 5 7 3 5 5 5 10 7 3 8 7 5 7 2 4 4 6 4 10   7 6 4 4 4 4 3 2 4 2 6 5 9 7 3 2 6 2 5 1 5 6 2 2 1 9 2 5 2 5 1 0 0 0 1 1   0.134000 2.950 2.950 7.500      1185706           3           0  0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 3 2 1 0 1 1 0 0 0 0 0 1 0 1 1 2 0 1 0 1 2 0 0 0    1 1 0 1 1 1 0 2 2 0 1 3 3 2 3 0 0 2 2 3 2 1 1 3 0 0 1 1 3 4 3 1 1 9 1 4 0 1 3    4 1 3 2 6 4 7 7 3 2 8 5 2 5 2 4 6 7 3 7 7 8 4 7 2 4 7 7 9 9 2 5 5 8 3 5 7 3 6    10 6 10 15 10 13 14 29 21 23 37 26 20 28 20 16 24 25 16 19 21 20 20 17 11 10     12 8 7 7 5 5 5 4 5 6 7 3 6 5 7 5 11 9 6 8 11 6 4 6 8 8 7 7 7 4 5 4 8 5 4 3 4 8   10 7 9 4 7 6 8 9 7 3 5 7 7 6 2 6 4 7 3 9 8 12 7 6 6 6 4 5 7 2 4 7 3 2 4 4 7 1    4 5 0 4 6 3 10 8 5 4 3 4 5 7 5 7 5 7 3 5 2 5 6 4 5 2 4 1 6 6 2 4 2 0 0 1 0   0.136000 3.000 3.000 7.600      1238426           3           0  0 0 0 0 0 0 0 0 0 0 0 1 0 1 0 2 4 0 2 0 2 2 0 1 1 1 0 2 1 1 2 1 0 1 1 0 3 1 0    0 1 0 1 0 0 2 1 1 0 4 0 2 6 3 3 4 0 3 1 2 4 0 4 4 0 1 5 2 2 5 1 3 4 3 3 5 2 4    4 6 2 5 3 4 5 4 5 6 7 5 6 2 8 3 4 7 2 4 4 3 7 6 5 1 4 8 3 7 10 3 3 6 1 5 3 8     11 5 7 15 11 15 17 21 23 21 24 28 16 21 29 15 22 27 28 20 13 19 13 7 15 10 11    9 6 8 8 4 7 5 4 6 5 10 6 7 8 9 3 5 5 9 5 9 4 4 4 3 5 7 4 10 6 8 4 9 8 4 6 7 9    11 6 8 3 5 8 12 3 6 9 7 11 9 6 7 4 7 7 7 2 5 4 5 0 2 9 5 5 5 10 7 5 6 3 9 4 4    13 2 7 5 7 4 7 2 0 4 5 4 4 6 8 1 2 5 6 4 7 3 11 4 3 3 5 5 4 4 3 1 4 2 2 1 1 0   0.138000 3.050 3.050 7.700      1299809           6           0  0 0 0 0 0 0 0 0 0 0 0 0 1 1 1 1 1 0 1 2 1 1 0 0 1 0 0 2 0 1 2 0 0 3 0 0 1 3 1    2 0 2 0 1 1 2 1 2 3 2 1 2 5 2 2 2 4 3 2 5 3 0 3 2 4 5 4 3 0 5 4 1 4 3 8 6 4 4    7 4 5 4 3 6 5 6 10 3 6 6 2 6 3 4 4 3 6 7 6 8 3 4 7 5 4 9 2 4 8 5 9 8 3 7 5 7 7   13 7 11 15 17 16 18 18 18 20 17 26 25 19 20 26 31 22 18 20 18 14 11 16 4 7 11    10 8 9 9 6 3 8 8 7 5 6 10 3 5 6 6 3 12 7 8 8 2 10 4 13 9 9 12 4 5 9 7 9 5 7 4    8 9 6 7 8 10 8 7 5 7 11 6 4 4 4 6 4 9 4 5 9 10 7 4 12 7 4 9 5 10 10 6 8 4 7 2    4 7 2 6 8 4 11 3 3 9 7 6 7 3 8 7 4 8 5 3 7 4 5 5 7 4 6 7 5 5 3 5 2 5 4 1 2 0 0   1   0.140000 3.100 3.100 7.800      1361810           3           0  0 0 0 0 0 0 0 0 0 1 0 0 0 0 3 2 1 0 0 0 1 1 1 2 0 0 0 0 1 0 2 2 2 1 0 0 3 3 0    2 0 6 2 3 1 0 3 3 1 2 2 5 3 5 3 3 2 2 7 3 2 2 3 4 2 3 4 4 1 3 7 4 5 4 2 3 5 4    2 1 3 6 3 4 3 8 7 6 5 3 5 11 5 5 3 3 7 3 6 4 4 2 4 4 4 1 5 5 9 6 6 9 3 10 8 6    8 3 10 8 16 16 13 18 23 29 25 19 19 20 27 19 22 27 24 21 15 18 11 20 21 17 12    5 18 6 12 7 9 11 7 12 11 4 8 8 4 8 7 7 2 6 4 4 9 6 9 3 4 7 7 7 4 10 4 11 5 8 8   8 5 4 4 8 6 4 9 8 12 12 8 5 8 3 10 8 7 5 3 5 6 8 5 6 10 7 2 11 2 5 5 6 8 10 2    7 5 5 14 2 7 3 9 3 5 2 8 2 3 4 4 7 9 5 4 7 6 7 5 6 3 5 4 7 6 7 7 9 3 0 2 1 1 1   0 0   0.142000 3.150 3.150 7.900      1429499           3           0  0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 2 3 1 2 1 1 0 0 0 3 0 2 2 1 0 3 0 2 1 3 0 0 1    1 3 1 2 4 1 5 3 5 1 0 7 1 3 2 3 2 2 2 3 0 0 1 3 6 3 2 2 4 4 4 6 4 3 6 4 10 3 7   2 5 4 7 4 5 8 4 7 4 1 7 11 5 2 10 2 11 3 7 8 10 9 6 3 5 3 6 3 10 11 5 5 9 7 10   8 9 5 15 11 9 18 18 15 24 17 23 17 19 25 17 24 18 37 16 17 21 17 14 20 17 15     15 9 4 11 7 3 8 10 8 8 6 8 3 4 5 8 4 6 3 9 9 6 2 10 4 4 3 8 4 9 1 7 5 9 7 10 9   10 4 6 5 8 6 6 10 10 6 5 7 6 6 10 5 7 8 8 8 7 7 11 12 8 3 10 6 9 13 11 4 6 7 6   3 10 5 8 4 7 7 7 5 8 4 9 5 5 7 6 6 7 11 11 7 8 5 3 5 7 7 10 3 3 6 5 7 9 2 3 7    1 0 0 0 0 1   0.144000 3.200 3.200 8.000      1493946           3           0  0 0 0 0 0 0 0 0 0 0 0 1 0 0 1 0 2 3 0 0 1 2 1 1 1 4 1 0 1 0 1 2 1 3 1 1 1 1 2    1 1 3 2 6 0 4 0 1 4 2 4 5 2 1 3 0 2 2 4 2 3 2 4 3 5 4 4 4 1 5 1 3 4 5 6 4 7 2    8 8 8 5 3 6 0 7 3 2 2 5 7 5 7 5 8 9 6 4 3 6 8 6 10 2 5 6 3 3 6 6 6 6 17 5 10 6   6 11 11 13 12 21 26 18 24 21 24 23 30 18 22 20 24 19 13 17 25 22 17 15 8 13 7    10 8 9 6 7 9 8 7 8 9 7 7 6 12 5 9 9 12 9 12 6 9 7 10 7 7 4 9 7 4 2 7 4 5 8 8 9   7 6 7 5 9 4 8 13 6 5 4 7 9 6 7 7 9 4 4 5 8 10 9 10 6 6 7 9 12 11 8 8 9 11 5 8    7 5 5 8 5 9 10 5 5 11 11 6 8 8 4 8 5 5 5 4 7 4 5 6 5 6 6 7 7 4 2 6 3 2 1 0 0 0   0 0   0.146000 3.250 3.250 8.100      1562352           5           0  0 0 0 0 0 0 0 0 0 0 0 0 0 2 2 0 2 0 1 2 1 1 0 0 1 0 1 2 0 0 0 3 1 2 0 4 4 2 0    0 2 3 2 0 1 3 3 4 0 1 4 3 3 4 5 5 4 2 1 4 2 5 3 2 7 6 3 5 6 5 5 5 1 5 2 7 4 8    7 4 6 5 7 5 3 5 8 1 6 4 6 8 7 6 7 6 3 4 6 3 5 8 4 10 3 3 11 6 5 3 9 6 4 3 17 9   11 11 24 13 15 14 25 26 26 21 17 32 32 22 18 25 29 29 27 24 21 12 23 14 12 11    9 17 7 9 11 3 7 6 5 5 12 3 6 8 7 4 7 11 10 8 9 5 8 2 10 9 8 10 10 7 7 4 7 5 7    7 9 10 8 7 7 16 6 8 10 5 6 6 12 12 7 11 11 8 9 7 8 12 10 7 8 7 11 8 9 7 7 4 9    4 7 14 9 8 8 13 9 8 7 13 5 9 5 7 4 9 5 7 8 7 8 7 3 10 9 3 4 4 4 5 2 6 6 3 5 10   4 4 2 3 0 1 0 0   0.148000 3.300 3.300 8.200      1630559           3           0  0 0 0 0 0 0 0 0 1 0 0 1 0 0 0 0 4 2 1 1 1 2 1 2 0 2 1 5 0 1 1 4 0 2 1 4 5 3 0    1 1 1 2 1 3 3 3 1 1 1 1 1 3 4 6 6 8 8 4 3 2 7 2 2 1 7 4 4 5 1 10 6 4 4 4 3 3 3   6 11 6 4 5 4 8 5 5 9 4 5 5 7 6 4 13 12 3 6 7 5 2 7 9 7 8 8 4 7 6 4 10 6 8 9 9    9 13 15 17 23 25 13 16 24 22 26 21 27 24 24 21 21 21 15 17 22 25 21 22 17 14     11 8 12 5 9 7 8 5 11 10 6 6 5 9 13 10 9 8 8 8 6 4 9 10 9 9 7 8 7 5 7 8 14 13 5   14 5 12 11 8 9 6 5 4 9 13 7 10 13 11 11 8 5 9 10 8 7 6 7 13 3 13 8 7 13 17 5 8   5 10 7 12 7 6 6 9 7 8 8 11 8 11 9 11 11 8 5 6 10 4 9 3 10 8 7 10 8 7 8 10 10 7   4 11 5 7 8 2 4 3 0 0 1 0 1   0.150000 3.350 3.350 8.300      1707576           3           0  0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 2 1 2 1 0 2 0 2 3 1 3 2 2 2 2 0 2 1 4 3 2 2 3    1 2 1 0 2 2 4 2 5 3 3 5 2 8 4 5 4 2 3 6 7 6 1 0 7 4 7 7 6 5 4 3 4 6 6 7 6 2 7    4 4 2 5 5 6 9 3 3 3 6 6 5 3 5 7 8 8 6 8 8 6 8 3 9 6 6 8 8 6 4 8 6 6 10 4 11 6    11 15 23 16 8 17 20 21 19 24 15 14 19 21 30 25 21 15 19 16 18 21 21 15 14 12     16 8 10 12 7 10 9 8 10 10 7 9 8 10 12 6 6 9 11 6 5 9 12 6 7 12 7 5 6 8 5 9 4     11 9 8 8 10 7 6 10 7 11 13 7 4 13 11 8 11 9 16 6 12 11 10 10 19 2 9 11 8 7 8 8   6 13 6 10 12 12 9 12 9 9 8 7 7 9 6 12 8 4 9 9 8 5 7 8 9 5 12 5 7 5 9 10 9 10 3   6 6 8 7 11 3 5 5 4 2 0 0 0 0   0.152000 3.400 3.400 8.400      1777231           3           0  0 0 0 0 0 0 0 0 1 0 0 0 0 1 1 1 0 0 1 1 3 1 0 3 4 2 3 3 3 3 3 2 1 1 1 1 3 3 0    1 8 0 0 5 3 7 4 4 4 4 4 3 5 2 2 5 3 6 1 7 6 1 2 2 5 2 1 6 6 8 7 7 5 10 4 1 6 9   3 4 5 3 5 8 4 9 8 11 8 3 2 7 7 9 10 9 10 8 6 8 6 8 7 10 8 7 3 8 4 10 7 6 8 9 6   5 16 9 19 24 23 17 23 24 22 30 21 15 23 27 20 20 20 18 20 23 18 17 15 19 17 18   13 9 4 4 7 12 7 10 4 8 6 10 5 6 13 2 3 8 7 8 7 3 11 8 7 9 7 19 7 8 9 6 14 8 8    11 10 11 13 14 10 16 8 9 13 8 9 9 12 7 12 11 6 9 15 5 9 9 9 11 11 13 6 10 6 4    12 9 9 12 11 8 6 9 16 10 10 10 8 10 10 6 7 4 1 15 6 8 4 9 13 11 8 10 11 9 8 3    3 6 6 7 9 4 6 8 7 4 2 1 2 2 1 0   0.154000 3.450 3.450 8.500      1849489           6           0  0 0 0 0 0 0 0 0 0 0 1 1 3 0 1 2 2 0 1 4 1 1 0 1 0 2 1 0 0 1 1 1 1 6 3 6 1 3 1    3 3 0 6 0 4 2 7 4 6 4 4 3 7 4 5 7 5 5 2 3 9 9 2 5 5 3 9 4 2 7 6 2 8 2 5 7 12 6   5 4 5 10 4 12 10 6 4 14 7 9 10 11 7 7 7 7 3 9 7 4 3 8 7 5 7 9 6 8 9 6 8 8 12 6   5 11 12 13 11 13 21 26 19 23 25 18 23 22 23 23 18 27 20 15 20 25 24 19 18 12     14 13 15 8 15 10 11 7 9 13 11 12 13 11 11 7 11 13 6 5 10 6 6 10 8 14 5 14 11 8   5 9 7 10 10 8 7 15 13 3 13 12 18 15 7 10 9 10 8 15 9 6 8 9 10 10 9 5 7 7 5 10    11 13 12 12 12 10 6 17 10 11 9 4 8 7 6 6 9 12 8 16 18 7 5 10 8 12 10 15 6 13     11 6 10 16 10 11 16 8 9 5 11 10 14 11 5 2 5 7 3 1 1 0 1 0   0.156000 3.500 3.500 8.600      1920727           4           0  0 0 0 0 0 0 0 0 0 0 0 1 1 0 1 0 2 1 2 0 3 0 1 1 0 1 0 3 0 4 4 1 3 1 2 3 3 4 3    1 2 3 9 5 2 3 7 3 3 6 5 2 6 1 4 3 2 3 6 5 1 8 3 8 5 3 7 6 13 11 9 5 8 7 7 5 8    7 4 8 6 4 10 4 6 5 6 9 9 12 6 7 10 9 9 8 8 3 8 9 8 8 2 12 11 13 8 13 7 8 6 6 9   6 8 16 13 14 16 16 22 20 21 21 17 20 18 19 22 20 11 20 22 21 14 19 15 23 17 15   12 14 19 16 10 11 14 11 9 11 9 12 8 16 14 9 6 18 10 11 7 10 11 17 10 13 8 10     12 9 12 7 7 10 10 11 11 9 8 8 14 10 10 9 14 9 14 13 9 19 16 17 4 11 8 12 11 10   21 6 10 8 9 12 9 7 7 12 7 16 14 10 13 6 13 8 9 10 6 10 8 7 10 4 6 11 19 12 6 7   5 8 11 10 12 13 9 6 10 5 11 11 4 14 10 7 2 6 5 1 2 5 1 1 0 0   0.158000 3.550 3.550 8.700      1999833           3           0  0 0 0 0 0 0 0 0 0 0 0 0 0 1 1 2 2 3 2 2 2 1 2 3 0 1 0 1 3 2 0 0 3 2 3 2 5 7 0    3 4 1 10 7 7 4 5 2 3 4 3 8 3 6 4 4 4 8 2 3 4 5 5 7 1 6 7 8 1 6 8 1 4 4 11 9 4    7 11 9 10 5 6 8 4 3 9 7 9 11 5 5 8 8 4 8 7 8 11 9 12 6 4 13 4 12 10 6 9 11 10    11 10 11 11 11 14 15 14 23 18 17 29 16 26 23 15 19 14 18 19 22 31 13 21 20 12    16 15 14 18 17 15 8 12 14 13 10 10 10 10 10 13 11 6 8 11 8 14 8 10 11 11 8 10    13 5 14 7 12 9 10 10 12 15 18 8 6 9 9 12 8 9 20 14 16 10 11 14 5 5 13 6 11 9     11 15 6 9 13 11 7 8 7 10 8 16 12 11 8 10 14 11 17 11 8 16 13 9 10 5 10 17 13     14 16 8 10 9 11 5 10 9 10 12 8 11 12 11 8 6 7 12 15 13 12 7 13 5 0 3 2 0 0 0 0   0.160000 3.600 3.600 8.800      2073149           3           0  0 0 0 0 0 0 0 0 0 1 0 0 0 0 2 1 2 1 2 2 1 0 2 2 1 0 3 6 4 5 5 2 2 2 5 5 3 6 4    6 4 5 2 4 4 3 2 4 6 3 3 6 5 7 4 5 7 5 3 5 6 13 5 3 10 5 9 7 4 5 6 5 10 6 5 5 6   6 4 14 7 6 11 6 9 10 9 8 5 3 8 10 10 6 6 8 9 5 6 14 7 11 10 9 9 11 13 8 4 5 10   12 6 16 8 8 7 19 20 23 10 16 27 25 23 19 26 21 16 20 21 24 18 25 8 11 13 16 18   13 22 18 9 16 4 16 10 12 13 9 7 9 8 17 11 10 13 10 14 4 9 12 16 8 9 16 17 13     11 14 8 8 13 9 11 15 10 11 14 8 6 4 9 11 18 9 9 8 9 15 11 11 11 9 6 13 13 10 7   8 10 15 14 9 7 4 10 12 17 10 14 13 10 10 12 20 9 7 6 11 15 11 10 8 9 6 10 13     17 6 8 9 6 13 13 16 10 15 5 11 14 11 12 6 5 12 9 4 9 2 4 1 1 0 0 0   0.162000 3.650 3.650 8.900      2156456           5           0  0 0 0 0 0 0 0 0 0 1 0 0 0 1 0 0 2 0 1 1 3 2 3 4 3 3 2 1 3 6 5 2 3 4 4 3 6 2 3    4 4 5 5 3 4 1 4 5 9 3 3 4 3 3 8 5 6 12 2 10 3 4 6 8 9 8 8 2 2 7 5 8 2 8 9 7 2    6 8 6 5 8 2 7 5 6 13 5 6 8 11 6 10 5 6 3 8 10 11 10 10 14 10 11 8 11 8 12 6 12   5 15 12 13 10 13 13 18 23 12 21 18 21 23 20 30 20 23 26 24 24 21 21 29 19 21     16 23 20 13 19 13 16 11 15 13 13 11 8 11 14 14 13 4 16 15 18 13 9 19 8 11 6 9    14 8 13 12 13 10 13 10 14 11 13 11 8 10 13 11 11 14 11 8 14 11 10 9 14 12 14     18 8 12 7 13 12 10 14 14 8 12 17 11 13 9 12 12 15 7 9 13 17 11 11 11 12 17 12    11 16 15 8 9 12 7 13 15 11 16 7 10 7 14 5 18 10 10 8 8 6 6 13 14 6 9 11 9 9 3    5 1 1 3 0 0   0.164000 3.700 3.700 9.000      2234753           3           0  0 0 0 0 0 0 0 0 0 0 0 0 1 0 1 4 1 4 2 1 3 1 1 3 2 3 3 1 3 6 2 4 4 3 3 3 6 5 2    6 4 1 3 3 7 1 4 4 6 12 4 5 2 6 4 9 3 1 8 11 5 2 7 6 3 8 4 7 3 8 3 9 6 7 8 9 2    7 6 9 6 15 6 9 5 9 4 9 17 15 10 2 10 6 8 12 12 11 12 10 9 7 11 8 7 5 11 10 14    16 7 7 7 13 15 10 16 17 21 19 14 18 24 19 27 27 24 20 22 24 21 20 14 24 17 17    18 32 15 12 13 15 12 8 14 11 11 19 11 14 15 18 10 5 12 11 11 9 15 9 7 9 16 12    9 12 10 15 9 18 7 11 12 14 7 20 8 10 13 14 11 6 6 9 11 8 10 16 8 17 13 17 9 16   11 10 9 13 20 17 14 12 10 13 11 9 9 17 20 10 16 8 14 13 14 18 15 15 8 10 12 11   22 12 13 9 12 9 11 14 19 12 12 8 8 12 11 19 11 11 12 15 11 15 13 9 9 10 9 4 9    4 2 1 0 0   0.166000 3.750 3.750 9.100      2327990           3           0  0 0 0 0 0 0 0 0 0 0 0 0 3 2 2 0 1 2 2 1 1 0 0 3 1 4 2 6 4 2 4 3 2 5 5 2 3 1 3    1 2 10 2 7 4 3 4 3 3 4 3 10 6 9 6 3 8 5 5 3 4 4 6 8 4 4 7 5 5 11 14 5 3 6 8 8    7 10 11 7 17 7 11 10 8 7 8 12 13 11 12 6 13 9 7 7 6 5 8 13 10 10 14 11 11 8 12   15 14 9 13 10 9 18 13 18 12 23 14 17 24 15 23 25 31 19 17 29 19 19 19 26 25 19   17 22 19 19 19 11 11 12 22 21 8 10 18 10 14 19 17 13 14 10 6 9 10 15 11 5 13     13 11 11 17 16 9 7 14 7 19 6 10 13 7 12 18 14 7 12 15 13 13 9 13 13 13 12 12     14 12 19 10 16 18 18 12 8 10 10 9 7 14 9 11 13 12 8 15 12 11 10 12 11 17 15 19   14 14 12 7 7 12 11 15 16 12 11 12 10 19 19 12 14 12 15 11 20 13 7 18 9 15 19     16 11 5 9 8 6 2 4 0 2 0 1   0.168000 3.800 3.800 9.200      2406866           3           0  0 0 0 0 0 0 0 0 0 1 0 2 0 1 0 2 3 2 3 1 2 1 2 2 5 2 1 2 3 2 2 2 5 3 5 3 3 1 3    6 8 6 1 3 9 6 3 6 10 5 5 7 4 5 7 12 9 5 7 5 6 6 8 3 5 4 7 8 5 6 5 8 13 4 10 2    10 9 7 7 16 9 10 9 13 8 12 9 13 15 9 15 9 10 11 6 6 6 7 7 6 8 15 9 8 9 6 12 12   11 14 12 11 13 8 17 18 18 11 14 19 14 25 21 15 10 15 19 27 23 22 24 17 19 18     12 16 22 21 25 9 25 15 19 15 21 15 8 11 13 12 10 12 7 13 11 17 11 13 10 16 19    14 23 11 8 12 13 10 9 17 4 14 10 7 10 17 14 11 11 20 18 13 8 12 6 8 13 12 23     15 14 15 16 9 14 9 13 14 17 11 17 11 10 15 17 11 6 12 12 14 15 17 12 16 16 8     17 15 15 10 15 11 10 15 12 13 9 12 9 12 15 12 6 18 7 15 14 12 21 18 11 10 18     11 19 11 7 11 3 2 5 4 0 1 1   0.170000 3.850 3.850 9.300      2508471           7           0  0 0 0 0 0 0 0 0 0 0 0 0 1 3 1 2 1 4 3 3 1 2 7 0 3 2 2 2 2 5 2 3 2 3 3 4 3 7 3    5 3 4 4 6 2 3 10 4 11 3 13 7 7 5 6 3 8 10 6 6 4 10 11 4 12 7 8 9 7 7 8 4 6 7 9   9 5 9 11 5 14 9 10 7 9 8 8 5 6 11 13 14 10 10 10 10 8 9 9 9 9 14 14 13 11 8 18   9 10 9 16 12 13 15 13 10 17 16 20 14 22 20 26 29 29 27 24 20 37 21 24 13 18 13   28 24 22 25 21 13 14 15 9 11 18 8 16 17 16 13 12 16 11 11 17 15 11 15 10 11 12   13 12 12 20 15 14 15 16 12 17 15 15 12 10 14 14 17 15 19 15 13 13 11 12 16 14    17 16 8 16 12 8 14 13 13 10 10 9 12 11 19 20 13 11 4 15 11 14 11 20 18 18 13     20 12 20 21 15 15 12 13 18 18 11 16 9 14 9 18 11 10 11 20 11 13 17 13 13 12 14   16 10 12 12 23 12 11 12 8 8 1 0 1 2 0   0.172000 3.900 3.900 9.400      2591210           3           0  0 0 0 0 0 0 0 0 0 0 0 0 1 1 0 4 4 3 2 1 3 3 2 3 0 3 6 1 3 1 5 5 4 3 9 9 0 4 7    5 3 5 5 8 7 3 3 5 5 8 5 11 10 8 10 3 6 6 6 7 7 8 8 12 9 6 10 8 7 10 8 8 10 4 6   12 20 4 6 11 7 9 10 7 5 10 6 12 11 7 13 13 16 12 6 8 14 13 9 7 5 14 17 17 10     12 11 6 13 11 17 3 23 13 21 12 21 28 11 23 30 28 23 24 26 26 17 21 15 27 23 33   16 22 25 11 20 22 23 21 20 7 21 13 16 12 16 16 13 18 18 9 13 16 15 9 20 13 19    15 8 9 11 14 13 10 9 10 16 15 14 17 15 19 16 12 14 12 14 14 16 19 19 4 24 8 12   15 16 11 15 14 20 14 13 13 14 16 19 14 13 19 14 18 23 15 15 4 14 17 14 8 10 15   20 11 15 19 12 9 13 12 11 16 12 16 13 14 16 13 16 16 19 19 12 11 10 19 15 15     14 12 5 11 18 17 10 13 12 9 6 2 0 0 1 0   0.174000 3.950 3.950 9.500      2675515           3           0  0 0 0 0 0 0 0 0 0 0 2 0 1 1 0 2 1 2 3 3 1 3 1 3 7 5 3 6 4 3 9 4 5 2 5 3 3 3 6    9 5 5 2 6 8 5 8 4 8 5 6 5 6 4 6 3 7 11 6 9 9 3 6 6 7 6 8 7 9 12 18 6 9 8 11 11   8 14 15 15 11 15 13 9 19 10 15 14 9 4 18 5 8 10 8 10 13 9 12 11 8 8 12 6 15 8    9 9 18 7 17 21 9 13 18 14 21 24 18 22 17 26 15 21 23 25 19 26 23 20 27 17 27     20 26 15 22 15 19 15 16 24 12 15 24 13 13 17 11 7 10 21 15 15 16 13 20 22 12     16 12 16 15 14 18 11 12 14 14 24 10 13 16 19 8 11 18 19 15 15 23 16 16 11 12     18 11 13 14 16 10 14 13 18 12 15 15 14 8 11 17 12 22 13 12 14 15 10 11 15 19     15 12 17 8 21 23 13 19 11 8 12 15 11 14 15 19 15 10 17 9 16 14 18 14 16 14 14    23 14 14 13 16 12 14 15 14 9 14 7 5 2 3 1 1 1   0.176000 4.000 4.000 9.600      2779386           5           0  0 0 0 0 0 0 0 0 0 0 0 2 2 3 0 1 3 0 6 2 6 3 1 5 0 4 1 6 5 1 6 3 6 5 6 2 5 4 5    3 9 8 5 7 5 8 4 12 8 12 6 8 5 7 5 7 10 5 5 6 7 9 7 10 7 10 10 8 12 10 6 13 10    11 12 11 10 10 16 9 6 12 9 11 17 10 11 10 14 11 16 7 11 13 12 10 17 14 11 13     12 10 13 16 16 17 17 15 14 11 8 15 13 27 22 14 19 17 22 22 27 18 28 19 27 32     24 33 21 17 23 12 27 25 20 20 17 22 14 15 22 21 14 9 16 12 19 16 17 16 16 20     14 18 15 14 18 10 12 9 16 12 12 10 13 19 12 12 15 14 15 22 12 11 15 18 19 18     10 6 11 14 10 23 17 14 16 19 10 10 16 19 17 23 16 18 19 18 16 12 14 14 14 13     11 10 24 21 22 26 18 18 18 14 17 5 13 17 11 13 16 14 18 16 9 15 15 18 16 14 21   13 22 17 9 8 16 17 16 16 19 7 20 19 18 16 10 6 10 6 3 5 1 0 0 2   0.178000 4.050 4.050 9.700      2869617           3           0  0 0 0 0 0 0 0 0 0 0 2 2 2 0 1 4 1 3 2 2 1 2 3 2 2 4 4 7 5 6 5 3 6 6 5 7 8 1 5    2 3 5 5 8 10 7 6 10 9 6 8 9 7 8 10 15 4 10 5 8 8 6 11 8 8 11 7 5 8 14 5 11 7     13 10 9 7 8 9 14 12 10 9 11 6 14 15 14 13 11 9 18 18 10 14 14 10 12 16 12 9 8    14 15 6 11 11 12 10 14 12 11 18 13 13 27 16 23 23 20 21 32 20 18 25 22 24 32     25 34 19 23 21 25 22 25 19 23 19 21 16 19 16 18 9 18 6 13 12 13 18 12 8 19 14    14 11 16 13 15 14 21 11 14 14 13 11 20 14 14 26 10 22 16 18 15 20 24 18 19 19    16 14 14 14 21 13 19 18 20 13 17 11 17 14 22 17 15 15 20 8 21 15 16 16 23 17     13 19 21 20 12 15 18 15 19 15 18 17 20 15 13 14 24 18 15 15 14 18 20 19 17 19    20 21 21 15 19 19 17 11 16 16 11 23 10 20 13 10 5 10 2 3 1 1 0   0.180000 4.100 4.100 9.800      2975040           3           0  0 0 0 0 0 0 0 0 1 0 0 1 2 2 4 4 2 4 4 1 2 5 0 3 3 5 2 5 5 4 9 2 7 8 4 8 3 11 6   10 4 7 8 6 6 5 8 8 7 11 4 4 11 12 7 11 7 10 11 7 11 11 10 9 7 13 12 18 8 14 12   14 12 8 8 16 10 10 14 16 10 6 8 15 15 15 22 13 19 18 12 6 11 10 7 12 12 24 15    17 9 17 21 10 17 18 14 14 14 9 22 11 23 17 15 23 32 20 11 12 20 15 23 30 20 25   19 26 29 19 27 23 15 19 11 30 16 21 24 18 18 14 8 6 25 13 21 13 13 19 13 21 25   23 18 14 14 13 20 12 14 8 10 25 14 15 20 15 10 15 16 21 8 15 20 21 20 13 16 15   20 11 18 17 17 9 12 24 19 13 18 17 20 14 15 20 10 23 19 25 8 7 13 14 11 15 18    13 10 12 10 17 11 24 16 17 11 12 13 16 20 14 26 12 17 13 14 16 16 6 20 16 23     22 11 17 16 14 25 19 17 21 22 19 13 19 16 18 10 11 7 4 6 0 0 2   0.182000 4.150 4.150 9.900      3083416           6           0  0 0 0 0 0 0 0 0 0 0 2 1 1 4 1 3 4 3 5 6 2 1 4 2 3 5 6 6 7 2 4 1 11 7 5 2 6 6 8   9 8 12 7 11 9 6 12 7 8 9 6 6 8 11 6 6 8 11 8 11 12 11 13 9 10 7 9 6 11 9 13 12   12 8 14 15 8 9 8 8 11 22 16 6 11 16 15 9 13 12 12 13 11 15 9 9 16 14 14 12 21    12 12 12 16 19 10 15 18 8 16 14 16 16 21 30 22 9 25 19 19 26 23 33 25 22 21 19   21 20 20 21 20 26 20 29 27 25 25 21 20 25 21 21 18 14 19 15 6 20 18 16 20 16     13 13 15 15 15 15 22 16 15 15 11 21 19 11 19 13 14 15 17 21 12 18 12 22 18 21    18 13 23 15 18 9 21 11 14 23 18 21 25 18 22 15 21 23 15 15 16 19 21 18 19 21     17 13 24 23 22 19 14 20 22 15 14 14 20 20 23 13 18 15 18 20 20 24 9 12 17 21     21 12 16 17 16 16 21 26 19 15 21 22 24 15 11 13 13 6 8 1 4 0 1 0   0.184000 4.200 4.200 10.00      3174897           3           0  0 0 0 0 0 0 0 0 0 0 1 1 2 3 0 5 4 3 3 0 7 3 2 4 2 8 6 4 5 9 3 8 6 4 2 7 6 8 7    9 3 5 8 5 9 7 7 6 11 14 7 12 9 9 5 15 12 14 15 12 9 11 5 8 13 11 12 10 9 17 12   11 8 17 11 19 11 15 9 11 7 15 14 16 16 16 7 12 10 14 13 13 16 16 11 15 13 14     12 16 11 12 13 17 10 13 19 11 17 11 13 14 13 10 19 19 23 24 22 24 24 31 19 23    22 28 21 25 29 17 23 17 21 30 22 19 25 27 27 22 23 23 17 25 17 20 17 12 23 21    9 17 20 16 19 16 17 20 9 16 11 22 16 15 12 15 17 23 24 16 16 18 26 11 16 20 18   10 14 17 26 19 17 15 17 19 12 21 20 24 17 27 13 16 18 19 23 14 19 14 10 11 18    19 6 15 21 23 25 17 17 18 21 27 20 17 18 20 25 22 20 18 22 18 17 15 24 16 15     22 18 22 14 20 20 22 18 22 25 19 26 12 19 19 13 12 16 19 14 9 7 5 4 2 0 2   0.186000 4.250 4.250 10.10      3283256           3           0  0 0 0 0 0 0 0 1 0 0 1 1 4 1 5 2 5 5 3 4 6 3 2 4 7 8 2 6 6 4 10 7 8 7 5 4 4 9 8   18 10 7 6 6 13 12 10 13 10 7 15 4 7 10 13 12 8 8 13 5 14 6 9 14 9 10 16 12 13    11 8 12 11 10 13 9 11 15 17 23 18 13 10 12 11 12 14 14 14 10 12 12 16 13 15 13   13 14 18 10 13 17 14 14 14 12 12 8 18 14 23 20 16 19 16 16 16 27 18 21 19 20     19 37 22 21 22 28 24 26 18 21 28 21 22 21 21 22 16 15 13 22 22 27 22 11 13 20    10 17 16 19 20 30 18 25 8 7 22 18 17 14 23 16 17 11 16 24 19 18 22 15 15 23 16   13 15 22 14 8 12 18 13 15 22 17 15 15 17 27 21 19 21 24 17 10 12 14 19 17 22     18 19 17 28 19 15 14 16 28 17 20 15 11 22 18 19 16 21 17 24 19 22 22 20 10 20    18 18 18 21 18 23 18 32 26 21 21 22 20 22 16 17 20 22 21 17 13 13 11 9 5 0 1 1   1   0.188000 4.300 4.300 10.20      3396610           5           0  0 0 0 0 0 0 0 0 0 0 1 2 3 0 2 5 5 4 3 3 5 1 2 3 6 9 3 3 3 8 7 2 9 5 7 5 11 8 9   7 6 9 6 4 5 8 6 10 9 14 10 15 6 7 13 15 10 13 7 15 10 10 11 14 14 6 7 17 13 19   3 13 9 6 13 13 14 10 11 12 16 17 13 10 15 15 19 19 11 11 15 11 13 9 13 20 8 18   14 18 23 23 23 15 19 20 14 11 7 18 16 15 22 28 20 24 22 25 17 20 39 24 26 25     25 33 25 25 25 33 15 29 18 29 18 12 18 23 17 24 28 22 16 20 33 23 18 23 26 23    15 24 16 16 16 16 17 15 15 16 14 11 9 23 17 13 13 18 12 19 20 30 20 20 15 21     19 16 18 20 23 19 15 10 11 15 19 13 22 22 18 19 16 19 23 16 10 25 23 20 21 20    31 19 19 18 15 22 18 14 13 21 18 19 22 19 16 17 21 14 20 26 18 26 22 19 26 19    20 22 15 13 24 23 15 21 21 21 27 18 22 19 24 17 22 16 18 23 10 12 3 5 3 3 0 0   0.190000 4.350 4.350 10.30      3502025           3           0  0 0 0 0 0 0 0 0 0 0 0 3 0 3 2 3 4 4 3 4 5 10 7 6 6 4 5 12 10 6 6 13 10 6 7 14    9 6 13 10 12 16 3 9 9 7 5 6 13 11 10 8 11 19 12 14 13 16 13 14 9 12 14 13 14     16 10 14 7 16 18 16 9 15 11 20 15 10 14 14 11 14 17 10 6 16 10 15 12 17 17 20    15 7 12 23 15 8 13 12 8 16 15 20 16 16 20 14 11 20 24 23 20 16 18 27 25 31 27    27 25 21 31 27 20 23 24 32 17 21 34 27 17 19 19 25 30 27 21 24 28 30 19 26 21    14 16 21 23 27 8 17 21 17 11 23 15 22 15 18 10 17 20 23 18 18 17 19 22 15 22     21 19 23 18 18 26 17 18 26 18 24 15 22 23 23 19 23 25 23 24 26 10 21 16 32 23    18 19 24 21 28 26 22 19 19 14 30 21 24 23 22 21 13 27 20 27 24 15 20 22 22 13    25 14 19 32 21 18 18 23 22 22 14 18 20 24 14 19 20 18 17 24 29 27 20 12 18 17    11 9 2 3 2 1 0   0.192000 4.400 4.400 10.40      3593938           3           0  0 0 0 0 0 0 0 0 0 0 1 0 1 1 2 3 4 7 8 1 5 6 8 3 7 5 4 9 8 8 7 7 9 7 9 9 15 5 7   8 15 14 9 9 13 8 8 15 10 7 10 9 10 14 7 8 18 16 17 11 14 15 13 8 15 8 15 18 16   16 22 12 8 16 13 10 13 13 10 21 11 10 16 16 13 13 17 16 20 23 13 22 16 14 15     22 19 22 15 22 24 16 16 16 19 12 15 16 17 20 18 19 26 17 23 18 32 20 28 36 22    25 30 29 31 36 24 24 21 29 24 32 29 30 23 34 19 33 34 25 20 31 27 24 16 14 21    20 13 24 17 28 13 24 16 26 15 26 21 11 15 20 13 20 18 25 23 18 24 26 22 16 22    14 13 16 20 24 25 19 29 20 15 20 16 25 26 21 22 17 24 22 21 17 23 23 15 19 30    23 17 21 19 18 21 26 14 29 24 20 33 19 15 20 23 28 19 23 25 15 19 17 31 23 18    29 26 25 14 24 25 18 19 19 24 35 31 23 23 14 15 19 11 20 19 24 17 16 9 10 12 3   2 2 0 1   0.194000 4.450 4.450 10.50      3712573           7           0  0 0 0 0 0 0 0 0 0 0 0 1 1 1 5 3 5 4 3 11 3 10 4 6 7 8 5 5 5 8 9 12 7 7 11 8 6    7 9 10 13 10 6 13 9 9 9 11 14 14 12 13 10 6 13 13 15 12 13 19 8 14 13 16 11 13   14 15 9 15 16 13 16 17 17 17 23 18 16 19 10 13 18 16 10 9 21 11 22 14 20 14 18   13 15 12 13 14 16 14 15 20 29 17 14 18 8 15 21 15 19 15 22 20 17 15 23 26 16     26 24 23 23 23 23 30 24 29 28 26 35 33 31 22 23 22 20 37 22 27 33 26 27 26 17    16 18 27 22 21 24 18 18 18 17 15 18 14 19 24 22 15 20 21 15 19 25 15 16 26 19    22 29 20 16 13 15 16 32 24 23 13 33 17 22 18 18 23 24 22 21 20 26 21 16 22 18    18 16 15 26 26 17 22 21 13 25 24 13 23 18 18 25 32 20 24 21 17 19 24 24 23 33    19 19 21 32 18 22 23 19 23 32 18 31 22 25 23 23 31 29 21 16 20 20 15 22 14 12    5 10 9 2 1 0 1   0.196000 4.500 4.500 10.60      3829518           3           0  0 0 0 0 0 0 0 0 0 1 2 2 1 6 2 6 5 9 3 5 6 8 6 3 8 10 7 11 9 4 8 9 5 11 10 13 9   16 13 10 9 5 12 9 15 10 13 9 12 18 14 19 9 13 14 12 13 21 17 17 18 16 13 12 16   14 18 10 15 15 16 11 15 22 17 19 17 11 12 26 12 17 19 18 21 20 27 17 18 19 21    14 19 16 12 16 21 20 18 8 17 17 13 13 18 15 19 15 19 20 28 21 29 27 27 34 24     26 31 25 24 16 17 23 23 30 28 18 28 32 28 37 18 26 18 16 33 21 31 21 20 22 19    20 25 18 18 20 11 17 20 22 23 14 14 17 18 20 25 20 19 20 22 19 16 33 25 21 21    24 18 16 22 29 22 16 27 26 28 21 20 22 17 25 23 20 23 18 16 19 26 22 21 22 23    15 20 19 17 23 19 20 15 22 18 22 26 23 23 31 17 29 18 13 15 19 18 24 22 28 22    17 23 24 26 21 23 25 24 29 26 18 41 24 29 22 27 23 28 16 30 24 18 23 19 17 18    21 17 14 8 2 5 2 0 0   0.198000 4.550 4.550 10.70      3950740           3           0  0 0 0 0 0 0 0 0 1 1 1 2 1 3 7 5 6 7 7 7 4 5 6 4 1 8 9 10 9 8 10 8 12 6 10 8 10   8 11 9 10 15 7 11 8 13 11 13 15 15 17 12 10 8 17 12 9 14 12 14 11 14 21 14 15    20 18 16 8 15 22 24 14 10 18 14 15 16 12 10 16 21 16 25 17 20 17 17 20 15 24     15 17 22 25 17 13 22 18 20 19 11 21 22 21 16 21 24 16 22 17 21 17 24 22 24 35    27 24 28 24 32 37 34 25 24 29 37 37 25 28 21 23 24 22 21 20 25 22 32 19 21 22    24 20 21 20 22 18 27 17 14 20 22 22 22 14 19 20 20 21 23 22 14 20 21 23 20 18    23 20 25 31 24 18 22 14 23 22 21 23 27 27 20 21 18 22 23 24 23 21 18 22 17 22    21 35 15 24 24 12 27 30 27 28 22 31 24 24 19 27 24 28 23 25 26 35 27 22 29 21    24 18 19 26 33 29 31 23 25 19 24 26 21 10 23 24 26 28 20 27 26 17 29 22 18 14    22 8 10 11 4 4 1 2 0   0.200000 4.600 4.600 10.80      4068161           5           0  0 0 0 0 0 0 0 0 0 1 1 0 1 5 5 2 9 3 11 6 9 8 7 7 8 3 3 13 10 8 7 5 8 13 8 7 14   12 10 7 15 13 13 11 12 12 14 12 13 12 10 15 11 14 7 16 15 8 15 13 15 13 18 13    17 21 15 12 13 13 17 18 18 18 16 19 20 17 14 17 24 13 12 18 19 19 13 21 18 26    21 23 16 14 18 19 13 33 13 19 20 14 20 23 14 26 19 22 21 21 16 27 30 25 28 22    32 21 30 27 31 21 30 22 27 27 31 27 21 17 38 41 17 21 20 19 30 24 27 20 20 21    30 20 19 19 31 25 24 13 21 23 19 24 33 24 17 20 17 12 25 23 18 24 11 24 25 22    33 20 11 22 31 21 20 26 27 21 26 24 14 23 23 20 20 26 28 10 20 27 24 22 17 27    28 20 23 23 33 20 24 26 32 33 29 21 25 24 17 18 19 27 26 20 24 26 24 24 26 21    19 24 21 36 32 18 33 33 20 23 25 33 19 27 25 27 24 27 21 21 23 28 18 27 25 19    24 15 17 12 15 7 2 1 0 0 ", "%f ", Inf);
%! assert (rows (x) == n);

## Test input validation
%!error <Invalid call to sscanf> sscanf ()
%!error <STRING must be a string> sscanf (1, "2")
%!error <TEMPLATE must be a string> sscanf ("1", 2)
%!error <Invalid call to sscanf> sscanf ("foo", "bar", 1, 2)

%% Note use fprintf so output not sent to stdout
%!test
%! nm = tempname ();
%! fid1 = fopen (nm, "w");
%! x = fprintf (fid1, "%s: %d\n", "test", 1);
%! fclose (fid1);
%! fid2 = fopen (nm, "r");
%! str = fscanf (fid2, "%s");
%! fclose (fid2);
%! unlink (nm);
%! assert (x, 8);
%! assert (str, "test:1");

%!error printf (1)
%!error <Invalid call to printf> printf ()

%!test
%! [s, msg, status] = sprintf ("%s: %d\n", "test", 1);
%! assert (s == "test: 1\n" && ischar (msg) && status == 8);

%!assert (sprintf ("%-+6.2f", Inf), "+Inf  ")
%!assert (sprintf ("%-6.2f", Inf), "Inf   ")
%!assert (sprintf ("%-+6.2f", nan), "+NaN  ")  # lowercase nan is part of test
%!assert (sprintf ("%-6.2f", nan), "NaN   ")
%!assert (sprintf ("%-+6.2f", NA), "+NA   ")
%!assert (sprintf ("%-6.2f", NA), "NA    ")

%!error <Invalid call to sprintf> sprintf ()
%!error <format TEMPLATE must be a string> sprintf (1)

%!test
%! arch_list = {"native"; "ieee-le"; "ieee-be"};
%! warning ("off", "Octave:fopen-mode");
%! status = 1;
%!
%! for i = 1:3
%!   arch = arch_list{i};
%!   for j = 1:4
%!     if (j == 1)
%!       mode_list = {"w"; "r"; "a"};
%!     elseif (j == 2)
%!       mode_list = {"w+"; "r+"; "a+"};
%!     elseif (j == 3)
%!       mode_list = {"W"; "R"; "A"};
%!     elseif (j == 4)
%!       mode_list = {"W+"; "R+"; "A+"};
%!     endif
%!     nm = tempname ();
%!     for k = 1:3
%!       mode = mode_list{k};
%!       [id, err] = fopen (nm, mode, arch);
%!       if (id < 0)
%!         __printf_assert__ ("open failed: %s (%s, %s): %s\n", nm, mode, arch, err);
%!         status = 0;
%!         break;
%!       else
%!         fclose (id);
%!       endif
%!       tmp_mode = [mode, "b"];
%!       [id, err] = fopen (nm, tmp_mode, arch);
%!       if (id < 0)
%!         __printf_assert__ ("open failed: %s (%s, %s): %s\n", nm, tmp_mode, arch, err);
%!         status = 0;
%!         break;
%!       else
%!         fclose (id);
%!       endif
%!       tmp_mode = [mode, "t"];
%!       [id, err] = fopen (nm, tmp_mode, arch);
%!       if (id < 0)
%!         __printf_assert__ ("open failed: %s (%s, %s): %s\n", nm, tmp_mode, arch, err);
%!         status = 0;
%!         break;
%!       else
%!         fclose (id);
%!       endif
%!     endfor
%!     unlink (nm);
%!     if (status == 0)
%!       break;
%!     endif
%!   endfor
%!   if (status == 0)
%!     break;
%!   endif
%! endfor
%!
%! assert (status == 1);

%!test
%! s.a = 1;
%! fail ("fopen (s)");

%!error fopen ("foo", "x")

%! fopen ("foo", "wb", "noodle");
%! assert (__prog_output_assert__ ("error:"));

%!error <Invalid call to fopen> fopen ()
%!error <Invalid call to fopen> fopen ("foo", "wb", "native", "utf-8", 1)

%!error fclose (0)
%!error <Invalid call to fclose> fclose (1, 2)

%!assert (ischar (tempname ()))

%!error <DIR must be a string> tempname (1)
%!error <PREFIX must be a string> tempname ("foo", 1)

%!error <Invalid call to tempname> tempname (1, 2, 3)

%!test
%! type_list = {"char"; "char*1"; "integer*1"; "int8";
%! "schar"; "signed char"; "uchar"; "unsigned char";
%! "short"; "ushort"; "unsigned short"; "int";
%! "uint"; "unsigned int"; "long"; "ulong"; "unsigned long";
%! "float"; "float32"; "real*4"; "double"; "float64";
%! "real*8"; "int16"; "integer*2"; "int32"; "integer*4"};
%!
%! n = rows (type_list);
%! nm = tempname ();
%! id = fopen (nm, "wb");
%! if (id > 0)
%!   for i = 1:n
%!     fwrite (id, i, type_list{i});
%!   endfor
%!
%!   fclose (id);
%!
%!   id = fopen (nm, "rb");
%!   if (id > 0)
%!     x = zeros (1, n);
%!     for i = 1:n
%!       x(i) = fread (id, [1, 1], type_list{i});
%!     endfor
%!
%!     fclose (id);
%!
%!     if (x == 1:n)
%!       __printf_assert__ ("ok\n");
%!     endif
%!   endif
%! endif
%!
%! unlink (nm);
%! assert (__prog_output_assert__ ("ok"));

%!test
%! classes = {"int8", "int16", "int32", "int64", ...
%!            "uint8", "uint16", "uint32", "uint64", ...
%!            "single", "double"};
%! n = numel (classes);
%! nm = tempname ();
%! mode = "wb+";
%! [id, err] = fopen (nm, mode);
%! if (id < 0)
%!   __printf_assert__ ("open failed: %s (%s): %s\n", nm, mode, err);
%! else
%!   unwind_protect
%!     for i = 1:n
%!       cls = classes{i};
%!       s_in = ones (1, 1, cls);
%!       m_in = ones (2, 2, cls);
%!       m_shape = size (m_in);
%!       frewind (id);
%!       fwrite (id, s_in, cls);
%!       fwrite (id, m_in, cls);
%!       frewind (id);
%!       s_out = fread (id, numel (s_in), sprintf ("%s=>%s", cls, cls));
%!       m_out = fread (id, numel (m_in), sprintf ("%s=>%s", cls, cls));
%!       m_out = reshape (m_out, m_shape);
%!       assert (s_in, s_out);
%!       assert (m_in, m_out);
%!     endfor
%!   unwind_protect_cleanup
%!     fclose (id);
%!   end_unwind_protect
%!   unlink (nm);
%! endif

%!test <54386>
%! x = char (128:255)';
%! nm = tempname ();
%! mode = "wb";
%! [id, err] = fopen (nm, mode);
%! if (id < 0)
%!   __printf_assert__ ("open failed: %s (%s): %s\n", nm, mode, err);
%! else
%!   fwrite (id, x);
%!   fclose (id);
%!   mode = "rb";
%!   [id, err] = fopen (nm, mode);
%!   if (id < 0)
%!     __printf_assert__ ("open failed: %s (%s): %s\n", nm, mode, err);
%!   else
%!     y = fread (id, Inf, "uchar=>char");
%!     fclose (id);
%!     assert (y, x);
%!     unlink (nm);
%!   endif
%! endif

%!test
%! nm = tempname ();
%! id = fopen (nm, "wb");
%! if (id > 0)
%!   fprintf (id, "%d\n", 1:100);
%!   fclose (id);
%!   mode = "rb";
%!   id = fopen (nm, mode);
%!   if (id < 0)
%!     __printf_assert__ ("open failed: %s (%s): %s\n", nm, mode, err);
%!   else
%!     for i = 1:101
%!       fgets (id);
%!     endfor
%!     if (feof (id))
%!       fclose (id);
%!       mode = "rb";
%!       [id, err] = fopen (nm, mode);
%!       if (id < 0)
%!         __printf_assert__ ("open failed: %s (%s): %s\n", nm, mode, err);
%!       else
%!         unwind_protect
%!           pos_one = ftell (id);
%!           s_one = fgets (id);
%!           for i = 1:48
%!             s = fgets (id);
%!           endfor
%!           pos_fifty = ftell (id);
%!           s_fifty = fgets (id);
%!           fseek (id, pos_one, SEEK_SET);
%!           s_one_x = fgets (id);
%!           fseek (id, pos_fifty, SEEK_SET);
%!           s_fifty_x = fgets (id);
%!           if (s_one == s_one_x && s_fifty == s_fifty_x)
%!             frewind (id);
%!             s_one_x = fgets (id);
%!             if (s_one != s_one_x)
%!               error ("bombed!!");
%!             endif
%!           endif
%!         unwind_protect_cleanup
%!           fclose (id);
%!         end_unwind_protect
%!       endif
%!     else
%!       fclose (id);
%!       __printf_assert__ ("EOF not reached when expected to: %s (%s)\n", nm, mode);
%!     endif
%!   endif
%!   unlink (nm);
%! endif

%!test   # write to and read from file with encoding
%! temp_file = [tempname(), ".txt"];
%! fid = fopen (temp_file, "wt", "n", "iso-8859-1");
%! unwind_protect
%!   [name, mode, arch, codepage] = fopen (fid);
%!   assert (name, temp_file);
%!   assert (mode, "w");
%!   assert (codepage, "iso-8859-1");
%!   fprintf (fid, "aäu %s", "AÄU");
%!   fclose (fid);
%!   # open in binary mode
%!   fid2 = fopen (temp_file, "rb");
%!   [name, mode, arch, codepage] = fopen (fid2);
%!   assert (name, temp_file);
%!   assert (mode, "rb");
%!   assert (codepage, "utf-8");
%!   read_binary = fread (fid2);
%!   fclose (fid2);
%!   assert (read_binary, [97 228 117 32 65 196 85].');
%!   # open in text mode with correct encoding
%!   fid3 = fopen (temp_file, "rt", "n", "iso-8859-1");
%!   read_text = fscanf (fid3, "%s");
%!   fclose (fid3);
%!   assert (read_text, "aäuAÄU");
%! unwind_protect_cleanup
%!   unlink (temp_file);
%! end_unwind_protect

%!assert (fputs (1, 1),-1)

%!error <Invalid call to fputs> fputs ()
%!error <Invalid call to fputs> fputs (1, "foo", 1)

%!error fgetl ("foo", 1)

%!error <Invalid call to fgetl> fgetl ()
%!error <Invalid call to fgetl> fgetl (1, 2, 3)

%!error fgets ("foo", 1)

%!error <Invalid call to fgets> fgets ()
%!error <Invalid call to fgets> fgets (1, 2, 3)

%!test
%! s.a = 1;
%! fail ("fprintf (s)", "Invalid call to fprintf");

%!error <Invalid call to fprintf> fprintf ()
%!error <Invalid call to fprintf> fprintf (1)
%!error fprintf (1, 1)
%!error fprintf (-1, "foo")

%!error fscanf ("foo", "bar")

%!error <Invalid call to fscanf> fscanf ()
%!error <Invalid call to fscanf> fscanf (1)

%!error <Invalid call to fread> fread ()
%!error <Invalid call to fread> fread (1, 2, "char", 1, "native", 2)
%!error fread ("foo")

%!error <Invalid call to fwrite> fwrite ()
%!error <Invalid call to fwrite> fwrite (1, rand (10), "char", 1, "native", 2)
%!error fwrite ("foo", 1)

%!error <Invalid call to feof> feof ()
%!error <Invalid call to feof> feof (1, 2)
%!error feof ("foo")

%!error <Invalid call to ferror> ferror ()
%!error <Invalid call to ferror> ferror (1, 'clear', 2)
%!error ferror ("foo")

%!error <Invalid call to ftell> ftell ()
%!error <Invalid call to ftell> ftell (1, 2)
%!error ftell ("foo")

%!error <Invalid call to fseek> fseek ()
%!error <Invalid call to fseek> fseek (1, 0, SEEK_SET, 1)
%!error fseek ("foo", 0, SEEK_SET)

%!error <Invalid call to frewind> frewind ()
%!error <Invalid call to frewind> frewind (1, 2)
%!error frewind ("foo")

%!test
%! [id, msg] = tmpfile ();
%! if (id < 0)
%!   __printf_assert__ ("tmpfile failed: %s\n", msg);
%! else
%!   unwind_protect
%!     ## FIXME: better test for endianness?
%!     big_endian = (bitunpack (uint16 (1))(1) == 0);
%!     fwrite (id, "abcdefg");
%!     frewind (id);
%!     [data, count] = fread (id);
%!     assert (data, [97; 98; 99; 100; 101; 102; 103]);
%!     assert (count, 7);
%!     frewind (id);
%!     [data, count] = fread (id, 'int16');
%!     expected = [25185; 25699; 26213];
%!     if (big_endian)
%!       expected = double (swapbytes (int16 (expected)));
%!     endif
%!     assert (data, expected);
%!     assert (count, 3);
%!     frewind (id);
%!     [data, count] = fread (id, [10, 2], 'int16');
%!     assert (data, expected);
%!     assert (count, 3);
%!     frewind (id);
%!     [data, count] = fread (id, [2, 10], 'int16');
%!     expected = [25185, 26213; 25699, 0];
%!     if (big_endian)
%!       expected = double (swapbytes (int16 (expected)));
%!     endif
%!     assert (data, expected);
%!     assert (count, 3);
%!   unwind_protect_cleanup
%!     fclose (id);
%!   end_unwind_protect
%! endif

%!test
%! [id, msg] = tmpfile ();
%! if (id < 0)
%!   __printf_assert__ ("tmpfile failed: %s\n", msg);
%! else
%!   unwind_protect
%!     fwrite (id, char (0:15));
%!     frewind (id);
%!     [data, count] = fread (id, inf, "2*uint8", 2);
%!     assert (data, [0; 1; 4; 5; 8; 9; 12; 13]);
%!     assert (count, 8);
%!   unwind_protect_cleanup
%!     fclose (id);
%!   end_unwind_protect
%! endif

%!test
%! [id, msg] = tmpfile ();
%! if (id < 0)
%!   __printf_assert__ ("tmpfile failed: %s\n", msg);
%! else
%!   unwind_protect
%!     fwrite (id, char (0:15));
%!     frewind (id);
%!     [data, count] = fread (id, 3, "2*uint8", 3);
%!     assert (data, [0; 1; 5]);
%!     assert (count, 3);
%!     [data, count] = fread (id, 3, "2*uint8", 3);
%!     assert (data, [6; 7; 11]);
%!     assert (count, 3);
%!     [data, count] = fread (id, 3, "2*uint8", 3);
%!     assert (data, [12; 13]);
%!     assert (count, 2);
%!     [data, count] = fread (id, 3, "2*uint8", 3);
%!     assert (data, []);
%!     assert (count, 0);
%!   unwind_protect_cleanup
%!     fclose (id);
%!   end_unwind_protect
%! endif

%!test
%! [id, msg] = tmpfile ();
%! if (id < 0)
%!   __printf_assert__ ("tmpfile failed: %s\n", msg);
%! else
%!   unwind_protect
%!     ## FIXME: better test for endianness?
%!     big_endian = (bitunpack (uint16 (1))(1) == 0);
%!     fwrite (id, char (0:15));
%!     frewind (id);
%!     [data, count] = fread (id, [1, Inf], "4*uint16", 3);
%!     expected = [256, 770, 1284, 1798, 3083, 3597];
%!     if (big_endian)
%!       expected = double (swapbytes (uint16 (expected)));
%!     endif
%!     assert (data, expected);
%!     assert (count, 6);
%!   unwind_protect_cleanup
%!     fclose (id);
%!   end_unwind_protect
%! endif

%!test
%! [id, msg] = tmpfile ();
%! if (id < 0)
%!   __printf_assert__ ("tmpfile failed: %s\n", msg);
%! else
%!   unwind_protect
%!     ## FIXME: better test for endianness?
%!     big_endian = (bitunpack (uint16 (1))(1) == 0);
%!     fwrite (id, char (0:15));
%!     frewind (id);
%!     [data, count] = fread (id, [3, Inf], "4*uint16", 3);
%!     expected = [256, 1798; 770, 3083; 1284, 3597];
%!     if (big_endian)
%!       expected = double (swapbytes (uint16 (expected)));
%!     endif
%!     assert (data, expected);
%!     assert (count, 6);
%!   unwind_protect_cleanup
%!     fclose (id);
%!   end_unwind_protect
%! endif

%!test
%! [id, msg] = tmpfile ();
%! if (id < 0)
%!   __printf_assert__ ("tmpfile failed: %s\n", msg);
%! else
%!   unwind_protect
%!     fwrite (id, "abcd");
%!     frewind (id);
%!     [data, count] = fread (id, [2, 3], "char");
%!     assert (data, [97, 99; 98, 100]);
%!     assert (count, 4);
%!   unwind_protect_cleanup
%!     fclose (id);
%!   end_unwind_protect
%! endif

%!assert (sprintf ("%1s", "foo"), "foo")
%!assert (sprintf ("%.s", "foo"), char (zeros (1, 0)))
%!assert (sprintf ("%1.s", "foo"), " ")
%!assert (sprintf ("%.1s", "foo"), "f")
%!assert (sprintf ("%1.1s", "foo"), "f")
%!assert (sprintf ("|%4s|", "foo"), "| foo|")
%!assert (sprintf ("|%-4s|", "foo"), "|foo |")
%!assert (sprintf ("|%4.1s|", "foo"), "|   f|")
%!assert (sprintf ("|%-4.1s|", "foo"), "|f   |")

%!assert (sprintf ("%c ", "foo"), "f o o ")
%!assert (sprintf ("%s ", "foo"), "foo ")

%!assert (sprintf ("|%d|", "foo"), "|102||111||111|")
%!assert (sprintf ("|%s|", [102, 111, 111]), "|foo|")

%!assert (sprintf ("%s %d ", [102, 1e5, 111, 1e5, 111]), "f 100000 o 100000 o ")

%!assert (sprintf ("%c,%c,%c,%c", "abcd"), "a,b,c,d")
%!assert (sprintf ("%s,%s,%s,%s", "abcd"), "abcd,")

%!assert (sprintf ("|%x|", "Octave"), "|4f||63||74||61||76||65|")
%!assert (sprintf ("|%X|", "Octave"), "|4F||63||74||61||76||65|")
%!assert (sprintf ("|%o|", "Octave"), "|117||143||164||141||166||145|")

## bug #47192
%!assert (sprintf ("%s", repmat ("blah", 2, 1)), "bbllaahh")
%!assert (sprintf ("%c", repmat ("blah", 2, 1)), "bbllaahh")
%!assert (sprintf ("%c %c %s", repmat ("blah", 2, 1)), "b b llaahh")

## bug #39735
%!assert (sprintf ("a %d b", []), "a  b")
%!assert (sprintf ("a %d b", ''), "a  b")
%!assert (sprintf ("a %d b", ' '), "a 32 b")
%!assert (sprintf ("a %s b", []), "a  b")
%!assert (sprintf ("a %s b", ''), "a  b")
%!assert (sprintf ("a %s b", ' '), "a   b")

%!assert <*53148> (double (sprintf ("B\0B")), [66, 0, 66])
%!assert <*53148> (sscanf ("B\0B 13", "B\0B %d"), 13)

%!test <*58055>
%!  w_modes = {"wb", "wt"};
%!  r_modes = {"rb", "rt"};
%!  f_texts = {"foo\nbar\nbaz\n", "foo\rbar\rbaz\r", "foo\r\nbar\r\nbaz\r\n"};
%!  for i = 1:numel (w_modes)
%!    w_mode = w_modes{i};
%!    for j = 1:numel (r_modes)
%!      r_mode = r_modes{j};
%!      for k = 1:numel (f_texts)
%!        f_text = f_texts{k};
%!        fname = tempname ();
%!        fid = fopen (fname, w_mode);
%!        unwind_protect
%!          fprintf (fid, "%s", f_text);
%!          fclose (fid);
%!          fid = fopen (fname, r_mode);
%!          fgetl (fid);
%!          pos = ftell (fid);
%!          buf1 = fgetl (fid);
%!          fgetl (fid);
%!          fseek (fid, pos, SEEK_SET);
%!          buf2 = fgetl (fid);
%!          assert (buf1, buf2);
%!        unwind_protect_cleanup
%!          fclose (fid);
%!          unlink (fname);
%!        end_unwind_protect
%!      endfor
%!    endfor
%!  endfor
