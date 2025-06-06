////////////////////////////////////////////////////////////////////////
//
// Copyright (C) 1993-2023 The Octave Project Developers
//
// See the file COPYRIGHT.md in the top-level directory of this
// distribution or <https://octave.org/copyright/>.
//
// This file is part of Octave.
//
// Octave is free software: you can redistribute it and/or modify it
// under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Octave is distributed in the hope that it will be useful, but
// WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Octave; see the file COPYING.  If not, see
// <https://www.gnu.org/licenses/>.
//
////////////////////////////////////////////////////////////////////////

// This file should not include config.h.  It is only included in other
// C++ source files that should have included config.h before including
// this file.

#include "MArray.h"
#include "Array-util.h"
#include "lo-error.h"

template <typename T>
class _idxadds_helper
{
public:
  _idxadds_helper (T *a, T v) : m_array (a), m_val (v) { }

  void operator () (octave_idx_type i)
  { m_array[i] += m_val; }

private:
  T *m_array;
  T m_val;
};

template <typename T>
class _idxadda_helper
{
public:
  _idxadda_helper (T *a, const T *v) : m_array (a), m_vals (v) { }

  void operator () (octave_idx_type i)
  { m_array[i] += *m_vals++; }

private:
  T *m_array;
  const T *m_vals;
};

template <typename T>
void
MArray<T>::idx_add (const octave::idx_vector& idx, T val)
{
  octave_idx_type n = this->numel ();
  octave_idx_type ext = idx.extent (n);
  if (ext > n)
    {
      this->resize1 (ext);
      n = ext;
    }

  octave_quit ();

  octave_idx_type len = idx.length (n);
  idx.loop (len, _idxadds_helper<T> (this->fortran_vec (), val));
}

template <typename T>
void
MArray<T>::idx_add (const octave::idx_vector& idx, const MArray<T>& vals)
{
  octave_idx_type n = this->numel ();
  octave_idx_type ext = idx.extent (n);
  if (ext > n)
    {
      this->resize1 (ext);
      n = ext;
    }

  octave_quit ();

  octave_idx_type len = std::min (idx.length (n), vals.numel ());
  idx.loop (len, _idxadda_helper<T> (this->fortran_vec (), vals.data ()));
}

template <typename T, T op (typename ref_param<T>::type,
                            typename ref_param<T>::type)>
struct _idxbinop_helper
{
public:
  _idxbinop_helper (T *a, const T *v) : m_array (a), m_vals (v) { }

  void operator () (octave_idx_type i)
  { m_array[i] = op (m_array[i], *m_vals++); }

private:
  T *m_array;
  const T *m_vals;
};

template <typename T>
void
MArray<T>::idx_min (const octave::idx_vector& idx, const MArray<T>& vals)
{
  octave_idx_type n = this->numel ();
  octave_idx_type ext = idx.extent (n);
  if (ext > n)
    {
      this->resize1 (ext);
      n = ext;
    }

  octave_quit ();

  octave_idx_type len = std::min (idx.length (n), vals.numel ());
  idx.loop (len, _idxbinop_helper<T, octave::math::min> (this->fortran_vec (),
                                                         vals.data ()));
}

template <typename T>
void
MArray<T>::idx_max (const octave::idx_vector& idx, const MArray<T>& vals)
{
  octave_idx_type n = this->numel ();
  octave_idx_type ext = idx.extent (n);
  if (ext > n)
    {
      this->resize1 (ext);
      n = ext;
    }

  octave_quit ();

  octave_idx_type len = std::min (idx.length (n), vals.numel ());
  idx.loop (len, _idxbinop_helper<T, octave::math::max> (this->fortran_vec (),
                                                         vals.data ()));
}

template <typename T>
void MArray<T>::idx_add_nd (const octave::idx_vector& idx,
                            const MArray<T>& vals, int dim)
{
  int nd = std::max (this->ndims (), vals.ndims ());
  if (dim < 0)
    dim = vals.dims ().first_non_singleton ();
  else if (dim > nd)
    nd = dim;

  // Check dimensions.
  dim_vector ddv = Array<T>::dims ().redim (nd);
  dim_vector sdv = vals.dims ().redim (nd);

  octave_idx_type ext = idx.extent (ddv(dim));

  if (ext > ddv(dim))
    {
      ddv(dim) = ext;
      Array<T>::resize (ddv);
      ext = ddv(dim);
    }

  octave_idx_type l, n, u, ns;
  get_extent_triplet (ddv, dim, l, n, u);
  ns = sdv(dim);

  sdv(dim) = ddv(dim) = 0;
  if (ddv != sdv)
    (*current_liboctave_error_handler) ("accumdim: dimension mismatch");

  T *dst = Array<T>::fortran_vec ();
  const T *src = vals.data ();
  octave_idx_type len = idx.length (ns);

  if (l == 1)
    {
      for (octave_idx_type j = 0; j < u; j++)
        {
          octave_quit ();

          idx.loop (len, _idxadda_helper<T> (dst + j*n, src + j*ns));
        }
    }
  else
    {
      for (octave_idx_type j = 0; j < u; j++)
        {
          octave_quit ();
          for (octave_idx_type i = 0; i < len; i++)
            {
              octave_idx_type k = idx(i);

              mx_inline_add2 (l, dst + l*k, src + l*i);
            }

          dst += l*n;
          src += l*ns;
        }
    }
}

// N-dimensional array with math ops.
template <typename T>
void
MArray<T>::changesign ()
{
  if (Array<T>::is_shared ())
    *this = - *this;
  else
    do_mx_inplace_op<T> (*this, mx_inline_uminus2);
}

// Element by element MArray by scalar ops.

template <typename T>
MArray<T>&
operator += (MArray<T>& a, const T& s)
{
  if (a.is_shared ())
    a = a + s;
  else
    do_ms_inplace_op<T, T> (a, s, mx_inline_add2);
  return a;
}

template <typename T>
MArray<T>&
operator -= (MArray<T>& a, const T& s)
{
  if (a.is_shared ())
    a = a - s;
  else
    do_ms_inplace_op<T, T> (a, s, mx_inline_sub2);
  return a;
}

template <typename T>
MArray<T>&
operator *= (MArray<T>& a, const T& s)
{
  if (a.is_shared ())
    a = a * s;
  else
    do_ms_inplace_op<T, T> (a, s, mx_inline_mul2);
  return a;
}

template <typename T>
MArray<T>&
operator /= (MArray<T>& a, const T& s)
{
  if (a.is_shared ())
    a = a / s;
  else
    do_ms_inplace_op<T, T> (a, s, mx_inline_div2);
  return a;
}

// Element by element MArray by MArray ops.

template <typename T>
MArray<T>&
operator += (MArray<T>& a, const MArray<T>& b)
{
  if (a.is_shared ())
    a = a + b;
  else
    do_mm_inplace_op<T, T> (a, b, mx_inline_add2, mx_inline_add2, "+=");
  return a;
}

template <typename T>
MArray<T>&
operator -= (MArray<T>& a, const MArray<T>& b)
{
  if (a.is_shared ())
    a = a - b;
  else
    do_mm_inplace_op<T, T> (a, b, mx_inline_sub2, mx_inline_sub2, "-=");
  return a;
}

template <typename T>
MArray<T>&
product_eq (MArray<T>& a, const MArray<T>& b)
{
  if (a.is_shared ())
    return a = product (a, b);
  else
    do_mm_inplace_op<T, T> (a, b, mx_inline_mul2, mx_inline_mul2, ".*=");
  return a;
}

template <typename T>
MArray<T>&
quotient_eq (MArray<T>& a, const MArray<T>& b)
{
  if (a.is_shared ())
    return a = quotient (a, b);
  else
    do_mm_inplace_op<T, T> (a, b, mx_inline_div2, mx_inline_div2, "./=");
  return a;
}

// Element by element MArray by scalar ops.

#define MARRAY_NDS_OP(OP, FN)                   \
  template <typename T>                         \
  MArray<T>                                     \
  operator OP (const MArray<T>& a, const T& s)  \
  {                                             \
    return do_ms_binary_op<T, T, T> (a, s, FN); \
  }

MARRAY_NDS_OP (+, mx_inline_add)
MARRAY_NDS_OP (-, mx_inline_sub)
MARRAY_NDS_OP (*, mx_inline_mul)
MARRAY_NDS_OP (/, mx_inline_div)

// Element by element scalar by MArray ops.

#define MARRAY_SND_OP(OP, FN)                   \
  template <typename T>                         \
  MArray<T>                                     \
  operator OP (const T& s, const MArray<T>& a)  \
  {                                             \
    return do_sm_binary_op<T, T, T> (s, a, FN); \
  }

MARRAY_SND_OP (+, mx_inline_add)
MARRAY_SND_OP (-, mx_inline_sub)
MARRAY_SND_OP (*, mx_inline_mul)
MARRAY_SND_OP (/, mx_inline_div)

// Element by element MArray by MArray ops.

#define MARRAY_NDND_OP(FCN, OP, FN) \
  template <typename T> \
  MArray<T> \
  FCN (const MArray<T>& a, const MArray<T>& b) \
  { \
    return do_mm_binary_op<T, T, T> (a, b, FN, FN, FN, #FCN); \
  }

MARRAY_NDND_OP (operator +, +, mx_inline_add)
MARRAY_NDND_OP (operator -, -, mx_inline_sub)
MARRAY_NDND_OP (product,    *, mx_inline_mul)
MARRAY_NDND_OP (quotient,   /, mx_inline_div)

template <typename T>
MArray<T>
operator + (const MArray<T>& a)
{
  return a;
}

template <typename T>
MArray<T>
operator - (const MArray<T>& a)
{
  return do_mx_unary_op<T, T> (a, mx_inline_uminus);
}

template <typename T>
void MArray<T>::instantiation_guard ()
{
  // This guards against accidental implicit instantiations.
  // Array<T, Alloc> instances should always be explicit and use INSTANTIATE_ARRAY.
  T::__xXxXx__ ();
}

#define INSTANTIATE_MARRAY(T, API)            \
  template <> API void                          \
  MArray<T>::instantiation_guard () { }         \
                                                \
  template class API MArray<T>
