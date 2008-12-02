// This file is part of Eigen, a lightweight C++ template library
// for linear algebra. Eigen itself is part of the KDE project.
//
// Copyright (C) 2008 Daniel Gomez Ferro <dgomezferro@gmail.com>
//
// Eigen is free software; you can redistribute it and/or
// modify it under the terms of the GNU Lesser General Public
// License as published by the Free Software Foundation; either
// version 3 of the License, or (at your option) any later version.
//
// Alternatively, you can redistribute it and/or
// modify it under the terms of the GNU General Public License as
// published by the Free Software Foundation; either version 2 of
// the License, or (at your option) any later version.
//
// Eigen is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
// FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License or the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU Lesser General Public
// License and a copy of the GNU General Public License along with
// Eigen. If not, see <http://www.gnu.org/licenses/>.

#ifndef EIGEN_TESTSPARSE_H

#ifdef __GNUC__
#include <ext/hash_map>
#endif

#ifdef EIGEN_GOOGLEHASH_SUPPORT
  #include <google/sparse_hash_map>
#endif

#include "main.h"
#include <Eigen/Cholesky>
#include <Eigen/LU>
#include <Eigen/Sparse>

enum {
  ForceNonZeroDiag = 1,
  MakeLowerTriangular = 2,
  MakeUpperTriangular = 4
};

/* Initializes both a sparse and dense matrix with same random values,
 * and a ratio of \a density non zero entries.
 * \param flags is a union of ForceNonZeroDiag, MakeLowerTriangular and MakeUpperTriangular
 *        allowing to control the shape of the matrix.
 * \param zeroCoords and nonzeroCoords allows to get the coordinate lists of the non zero,
 *        and zero coefficients respectively.
 */
template<typename Scalar> void
initSparse(double density,
           Matrix<Scalar,Dynamic,Dynamic>& refMat,
           SparseMatrix<Scalar>& sparseMat,
           int flags = 0,
           std::vector<Vector2i>* zeroCoords = 0,
           std::vector<Vector2i>* nonzeroCoords = 0)
{
  sparseMat.startFill(refMat.rows()*refMat.cols()*density);
  for(int j=0; j<refMat.cols(); j++)
  {
    for(int i=0; i<refMat.rows(); i++)
    {
      Scalar v = (ei_random<double>(0,1) < density) ? ei_random<Scalar>() : Scalar(0);
      if ((flags&ForceNonZeroDiag) && (i==j))
      {
        v = ei_random<Scalar>()*Scalar(3.);
        v = v*v + Scalar(5.);
      }
      if ((flags & MakeLowerTriangular) && j>i)
        v = Scalar(0);
      else if ((flags & MakeUpperTriangular) && j<i)
        v = Scalar(0);
      if (v!=Scalar(0))
      {
        sparseMat.fill(i,j) = v;
        if (nonzeroCoords)
          nonzeroCoords->push_back(Vector2i(i,j));
      }
      else if (zeroCoords)
      {
        zeroCoords->push_back(Vector2i(i,j));
      }
      refMat(i,j) = v;
    }
  }
  sparseMat.endFill();
}

#endif // EIGEN_TESTSPARSE_H