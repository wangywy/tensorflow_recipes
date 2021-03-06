#!/bin/bash

set -x

error_exit()
{
    kill $1
    if [ "$?" != "0" ]; then
        exit 1
    fi
}

export PYTHON_BIN_PATH="$PYTHON"
export PYTHON_LIB_PATH="$SP_DIR"

export TF_NEED_CUDA=1
export TF_ENABLE_XLA=0
export TF_NEED_MKL=0
export TF_NEED_VERBS=0
export TF_NEED_GCP=1
export TF_NEED_KAFKA=0
export TF_NEED_HDFS=0
export TF_NEED_OPENCL_SYCL=0

export USE_MSVC_WRAPPER=1
export TF_CUDA_VERSION=${cudatoolkit}
export CUDA_TOOLKIT_PATH="C:/Program Files/NVIDIA GPU Computing Toolkit/CUDA/v${cudatoolkit}"
export CUDNN_INSTALL_PATH=$(cygpath -m "$LIBRARY_PREFIX")
export TF_CUDNN_VERSION=${cudnn}

export PATH="/c/Program Files/NVIDIA GPU Computing Toolkit/CUDA/v${cudatoolkit}/bin:$PATH"
export PATH="/c/Program Files/NVIDIA GPU Computing Toolkit/CUDA/v${cudatoolkit}/extras/CUPTI/libx64:$PATH"

export TF_CUDA_COMPUTE_CAPABILITIES="3.0,3.5,5.2"
if [ ${cudatoolkit} == "8.0" ]; then
    export TF_CUDA_COMPUTE_CAPABILITIES="3.0,3.5,5.2,6.0,6.1"
fi
if [ ${cudatoolkit} == "9.0" ]; then
    export TF_CUDA_COMPUTE_CAPABILITIES="3.0,3.5,5.2,6.0,6.1,7.0"
fi
if [[ ${cudatoolkit} == 10.* ]]; then
    export TF_CUDA_COMPUTE_CAPABILITIES="3.0,3.5,5.2,6.0,6.1,7.0,7.5"
fi

unset OLD_PATH
unset ORIGINAL_PATH
unset __VSCMD_PREINIT_PATH
unset ACLOCAL_PATH
unset WindowsSDK_ExecutablePath_x64
unset SSH_AUTH_SOCK
unset SSH_ASKPASS
unset PSMODULEPATH
unset PROMPT
unset PRINTER
unset PKG_CONFIG_PATH
unset VS140COMNTOOLS
unset __VSCMD_PREINIT_INCLUDE
unset VSINSTALLDIR
unset VCIDEInstallDir
unset VS150COMNTOOLS
unset pin_run_as_build
unset HTMLHelpDir
unset FrameworkDir
unset FrameworkDIR64


unset PATH_OVERRIDE

echo "" | ./configure

cp $RECIPE_DIR/vile_hack.sh ./
bash vile_hack.sh &
pid=$!

BUILD_OPTS="--logging=6 --subcommands --define=override_eigen_strong_inline=true --experimental_shortened_obj_file_path=true --define=no_tensorflow_py_deps=true"
${LIBRARY_BIN}/bazel --output_base $SRC_DIR/../bazel --batch build -c opt $BUILD_OPTS tensorflow/tools/pip_package:build_pip_package || exit $?
error_exit $pid

PY_TEST_DIR="py_test_dir"
rm -fr ${PY_TEST_DIR}
mkdir -p ${PY_TEST_DIR}
cmd /c "mklink /J ${PY_TEST_DIR}\\tensorflow .\\tensorflow"

./bazel-bin/tensorflow/tools/pip_package/build_pip_package "$PWD/${PY_TEST_DIR}"

PIP_NAME=$(ls ${PY_TEST_DIR}/tensorflow-*.whl)
# python -m pip install ${PIP_NAME} --no-deps -vv --ignore-installed
unzip ${PIP_NAME} -d $SP_DIR

# The tensorboard package has the proper entrypoint
rm -f ${PREFIX}/Scripts/tensorboard.exe
