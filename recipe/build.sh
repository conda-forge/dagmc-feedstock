#!/usr/bin/env bash

set -ex

# Install DAGMC
# default options from
# https://github.com/svalinn/DAGMC/blob/develop/cmake/DAGMC_macros.cmake

if [[ "$mpi" != "nompi" ]]; then
  export CONFIGURE_ARGS="-DCMAKE_CXX_COMPILER=mpicxx -DCMAKE_C_COMPILER=mpicc"
fi

export CXXFLAGS="-D_LIBCPP_DISABLE_AVAILABILITY ${CXXFLAGS}"

cmake ${CMAKE_ARGS} \
      -DBUILD_MCNP5=OFF \
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
      ${CONFIGURE_ARGS} \
      -S . \
      -B build
cmake build -LH
cmake --build build --parallel "${CPU_COUNT}"
ctest --verbose --test-dir build --tests-regex  dagmc_unit_tests --output-on-failure
cmake --install build
