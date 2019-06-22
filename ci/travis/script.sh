#!/bin/bash
set -e

# Add MKL shared libraries to the path
# This unfortunately does not work in travis OSX if I put the export command
# in the install.sh (it works on linux though)
export MKL_SHARED_LIB_DIR=`ls -rd ${CONDA_ROOT}/pkgs/*/ | grep mkl-2 | head -n 1`lib:`ls -rd ${CONDA_ROOT}/pkgs/*/ | grep intel-openmp- | head -n 1`lib

echo "MKL shared library path: ${MKL_SHARED_LIB_DIR}"

if [[ "${TRAVIS_OS_NAME}" == "linux" ]]; then
    export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${MKL_SHARED_LIB_DIR}
else if [[ "$TRAVIS_OS_NAME" == "osx" ]]; then
    export DYLD_LIBRARY_PATH=${DYLD_LIBRARY_PATH}:${MKL_SHARED_LIB_DIR}
fi
fi


# Test C interface
# ---------------------------------------------------

# Compile and test OSQP
echo "Change directory to Travis build ${TRAVIS_BUILD_DIR}"
echo "Testing OSQP with standard configuration"
cd ${TRAVIS_BUILD_DIR}
mkdir build
cd build
cmake -G "Unix Makefiles" -DCOVERAGE=ON -DUNITTESTS=ON ..
make
${TRAVIS_BUILD_DIR}/build/out/osqp_tester

if [[ $TRAVIS_OS_NAME == "linux" ]]; then
    # Check memory with valgrind
    valgrind --suppressions=${TRAVIS_BUILD_DIR}/.valgrind-suppress.supp --leak-check=full --gen-suppressions=all --track-origins=yes --error-exitcode=42 ${TRAVIS_BUILD_DIR}/build/out/osqp_tester
    # Perform code coverage
    cd ${TRAVIS_BUILD_DIR}/build
    lcov --directory . --capture -o coverage.info # capture coverage info
    lcov --remove coverage.info "${TRAVIS_BUILD_DIR}/tests/*" \
        "${TRAVIS_BUILD_DIR}/lin_sys/direct/qdldl/amd/*" \
        "${TRAVIS_BUILD_DIR}/lin_sys/direct/qdldl/qdldl_sources/*" \
        "/usr/include/x86_64-linux-gnu/**/*" \
        -o coverage.info # filter out tests and unnecessary files
    lcov --list coverage.info # debug before upload
    coveralls-lcov coverage.info # uploads to coveralls
fi


echo "Testing OSQP with floats"
cd ${TRAVIS_BUILD_DIR}
rm -rf build
mkdir build
cd build
cmake -G "Unix Makefiles" -DDFLOAT=ON -DUNITTESTS=ON ..
make
${TRAVIS_BUILD_DIR}/build/out/osqp_tester

echo "Testing OSQP without long integers"
cd ${TRAVIS_BUILD_DIR}
rm -rf build
mkdir build
cd build
cmake -G "Unix Makefiles" -DDLONG=OFF -DUNITTESTS=ON ..
make
${TRAVIS_BUILD_DIR}/build/out/osqp_tester



echo "Testing OSQP without printing"
cd ${TRAVIS_BUILD_DIR}
rm -rf build
mkdir build
cd build
cmake -G "Unix Makefiles" -DPRINTING=OFF -DUNITTESTS=ON ..
make
${TRAVIS_BUILD_DIR}/build/out/osqp_tester


# Test custom memory management
# ---------------------------------------------------

echo "Test OSQP custom allocators"
cd ${TRAVIS_BUILD_DIR}
rm -rf build
mkdir build
cd build
cmake -DUNITTESTS=ON \
    -DOSQP_CUSTOM_MEMORY=${TRAVIS_BUILD_DIR}/tests/custom_memory/custom_memory.h \
    ..
make osqp_tester_custom_memory
${TRAVIS_BUILD_DIR}/build/out/osqp_tester_custom_memory

set +e
