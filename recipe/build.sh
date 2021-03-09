#!/usr/bin/env bash

# Install DAGMC
# default options from
# https://github.com/svalinn/DAGMC/blob/develop/cmake/DAGMC_macros.cmake

cmake -DBUILD_MCNP5=OFF
      -DBUILD_MCNP6=OFF
      -DBUILD_MCNP_PLOT=OFF
      -DBUILD_MCNP_OPENMP=OFF
      -DBUILD_MCNP_MPI=OFF
      -DBUILD_MCNP_PYNE_SOURCE=OFF
      -DBUILD_GEANT4=OFF
      -DBUILD_FLUKA=OFF
      -DBUILD_UWUW=ON
      -DBUILD_TALLY=ON
      -DBUILD_BUILD_OBB=ON
      -DBUILD_MAKE_WATERTIGHT=ON
      -DBUILD_OVERLAP_CHECK=ON
      -DBUILD_TESTS=ON
      -DBUILD_CI_TESTS=ON
      -DBUILD_SHARED_LIBS=ON
      -DBUILD_STATIC_LIBS=ON
      -DBUILD_EXE=ON
      -DBUILD_STATIC_EXE=OFF
      -DBUILD_PIC=OFF
      -DBUILD_RPATH=ON
      -DOUBLE_DOWN=OFF
      -DMOAB_DIR="${PREFIX}" \
      -DCMAKE_INSTALL_PREFIX="${PREFIX}"
make -j "${CPU_COUNT}"
make install
