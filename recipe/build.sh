#!/usr/bin/env bash

# Install DAGMC
# default options from
# https://github.com/svalinn/DAGMC/blob/develop/cmake/DAGMC_macros.cmake

export CONFIGURE_ARGS=""

if [[ "$mpi" != "nompi" ]]; then
  export CONFIGURE_ARGS="-DCMAKE_CXX_COMPILER=mpicxx -DCMAKE_C_COMPILER=mpicc ${CONFIGURE_ARGS}"
fi
if [[ "$dd" != "nodoubledown" ]]; then
  export CONFIGURE_ARGS="-DDOUBLE_DOWN=ON ${CONFIGURE_ARGS}"
  # install embree
  curl -L https://github.com/embree/embree/releases/download/v4.3.3/embree-4.3.3.x86_64.linux.tar.gz > embree-4.3.3.x86_64.linux.tar.gz 
  tar xzf embree-4.3.3.x86_64.linux.tar.gz
  source embree-4.3.3.x86_64.linux/embree-vars.sh
  # clone double down repo
  git clone https://github.com/pshriwise/double-down
  cd double-down
  # configure the build
  mkdir bld
  cd bld
  cmake .. -DCMAKE_INSTALL_PREFIX=/my/install/location -DCMAKE_PREFIX_PATH="/moab/install/location;/embree/install/location"
  # build and test double-down
  make all test
  # install
  make install
  cd ../..
else
  export CONFIGURE_ARGS="-DDOUBLE_DOWN=OFF ${CONFIGURE_ARGS}"
fi

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
      ${CONFIGURE_ARGS}
make -j "${CPU_COUNT}"
make install
make test
