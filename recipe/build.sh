#!/usr/bin/env bash

set -ex

# Install DAGMC
# default options from
# https://github.com/svalinn/DAGMC/blob/develop/cmake/DAGMC_macros.cmake

export CONFIGURE_ARGS="-DCMAKE_POLICY_VERSION_MINIMUM=3.5"

if [[ "$mpi" != "nompi" ]]; then
  # mpich's wrappers need pointing at the cross compilers, and in cross
  # builds the bare name resolves to the build-env (x86_64) wrapper whose
  # embedded libmpicxx is the wrong arch — use the host-env wrapper script
  # by absolute path instead. (openmpi's wrappers honor OMPI_CC/OMPI_CXX
  # from activation and its cross builds link correctly as-is.)
  export MPICH_CC="${CC}" MPICH_CXX="${CXX}"
  if [[ "$mpi" == "mpich" && "${CONDA_BUILD_CROSS_COMPILATION:-}" == "1" ]]; then
    export CONFIGURE_ARGS="-DCMAKE_CXX_COMPILER=${PREFIX}/bin/mpicxx -DCMAKE_C_COMPILER=${PREFIX}/bin/mpicc ${CONFIGURE_ARGS}"
  else
    export CONFIGURE_ARGS="-DCMAKE_CXX_COMPILER=mpicxx -DCMAKE_C_COMPILER=mpicc ${CONFIGURE_ARGS}"
  fi
fi
if [[ "$dd" != "nodoubledown" ]]; then
  export CONFIGURE_ARGS="-DDOUBLE_DOWN=ON -Ddd_ROOT=${PREFIX}  ${CONFIGURE_ARGS}"
  # clone double down repo; v1.1.0 plus the fix for wrong point_in_volume
  # results on non-AVX2 builds (double-down#53) — no tagged release has it yet
  git clone https://github.com/pshriwise/double-down.git
  cd double-down
  git checkout 4a927468
  # arm64 targets only: clang rejects -march=native for arm64-apple-darwin
  # (cross or native) and -mavx2 is x86-only. x86_64 keeps both flags, as
  # this feedstock always has. The resulting non-AVX2 arm64 code path is
  # correct because the checkout above includes the double-down#53 fix.
  if [[ "${target_platform}" == "osx-arm64" || "${target_platform}" == "linux-aarch64" ]]; then
    sed -i.bak 's/ -march=native//g; s/ -mavx2//g' CMakeLists.txt
  fi
  # configure the build
  mkdir bld
  cd bld
  cmake ${CMAKE_ARGS} \
     -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
     -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
     -DMOAB_DIR="${PREFIX}" \
     -DEMBREE_DIR="${PREFIX}" \
     ..
  # build double-down; run its tests only where they can execute
  make all
  if [[ "${CONDA_BUILD_CROSS_COMPILATION:-}" != "1" || "${CROSSCOMPILING_EMULATOR}" != "" ]]; then
    make test
  fi
  # install
  make install
  cd ../..
  rm -rf double-down
else
  export CONFIGURE_ARGS="-DDOUBLE_DOWN=OFF ${CONFIGURE_ARGS}"
fi

export CXXFLAGS="-D_LIBCPP_DISABLE_AVAILABILITY ${CXXFLAGS}"

cmake ${CMAKE_ARGS} \
      -DCMAKE_IGNORE_PREFIX_PATH="/opt/homebrew;/usr/local" \
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
      ${CONFIGURE_ARGS} .
make -j "${CPU_COUNT}"
make install
if [[ "${CONDA_BUILD_CROSS_COMPILATION:-}" != "1" || "${CROSSCOMPILING_EMULATOR}" != "" ]]; then
make test
ctest -V -R dagmc_unit_tests
fi
