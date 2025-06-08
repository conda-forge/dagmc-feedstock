#!/usr/bin/env bash

set -ex

# Install DAGMC
# default options from
# https://github.com/svalinn/DAGMC/blob/develop/cmake/DAGMC_macros.cmake

export CONFIGURE_ARGS="-DCMAKE_POLICY_VERSION_MINIMUM=3.5"

if [[ "$mpi" != "nompi" ]]; then
  export CONFIGURE_ARGS="-DCMAKE_CXX_COMPILER=mpicxx -DCMAKE_C_COMPILER=mpicc ${CONFIGURE_ARGS}"
fi
if [[ "$dd" != "nodoubledown" ]]; then
  export CONFIGURE_ARGS="-DDOUBLE_DOWN=ON -Ddd_ROOT=${PREFIX}  ${CONFIGURE_ARGS}"
  # clone double down repo
  git clone -b v1.1.0 --depth 1 https://github.com/pshriwise/double-down.git
  cd double-down
  # configure the build
  mkdir bld
  cd bld
  cmake ${CMAKE_ARGS} \
     -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
     -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
     -DMOAB_DIR="${PREFIX}" \
     -DEMBREE_DIR="${PREFIX}" \
     ..
  # build and test double-down
  make all test
  # install
  make install
  cd ../..
  rm -rf double-down
else
  export CONFIGURE_ARGS="-DDOUBLE_DOWN=OFF ${CONFIGURE_ARGS}"
fi

export CXXFLAGS="-D_LIBCPP_DISABLE_AVAILABILITY ${CXXFLAGS}"

cmake -DBUILD_MCNP5=OFF \
      -DBUILD_MCNP6=OFF \
      -DBUILD_MCNP_PLOT=OFF \
      -DBUILD_MCNP_OPENMP=OFF \
      -DBUILD_MCNP_MPI=OFF \
      -DBUILD_MCNP_PYNE_SOURCE=OFF \
      -DBUILD_GEANT4=OFF \
      -DBUILD_FLUKA=OFF \
      -DBUILD_UWUW=ON \
      -DBUILD_TALLY=ON \
      -DBUILD_BUILD_OBB=ON \
      -DBUILD_MAKE_WATERTIGHT=ON \
      -DBUILD_OVERLAP_CHECK=ON \
      -DBUILD_TESTS=ON \
      -DBUILD_CI_TESTS=ON \
      -DBUILD_SHARED_LIBS=ON \
      -DBUILD_STATIC_LIBS=OFF \
      -DBUILD_EXE=ON \
      -DBUILD_STATIC_EXE=OFF \
      -DBUILD_PIC=OFF \
      -DBUILD_RPATH=ON \
      -DMOAB_DIR="${PREFIX}" \
      -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
      ${CONFIGURE_ARGS} .
make -j "${CPU_COUNT}"
make install
make test
ctest -V -R dagmc_unit_tests
