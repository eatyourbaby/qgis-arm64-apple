#!/bin/bash
#
# QGIS macOS arm64 Build (Experimental)
# 2022-12-05
# DingoBits
# https://github.com/DingoBits/qgis-arm64-apple
#
# Requires Xcode CLI & homebrew
# xcode-select --install
# /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
#
# It's best to build in a clean system, e.g., a VM.
# To avoid swap usage, allocate ≥ 12 GB of RAM.
#
# I've tried to include all build switches for linking,
# but errors and omissions excepted.
#

set -e

# VERSION
PYTHON_VERSION=3.11.0
PYTHON_VERSION_SHORT=3.11
GDAL_VERSION=3.5.3
PDAL_VERSION=2.4.3
SAGA_VERSION=8.4.1
GRASS_VERSION=8.2.0
QGIS_VERSION=3.28.1

# BUILD ENV
export ARCHS=arm64
export MACOSX_DEPLOYMENT_TARGET=12.0
export SDKROOT="/Library/Developer/CommandLineTools/SDKs/MacOSX12.3.sdk"
export CC="clang"
export CXX="clang++"

# WORKING DIR
WORKSPACE="$(pwd)/workspace"
export CPPFLAGS="-I$WORKSPACE/include"
export LDFLAGS="-L$WORKSPACE/lib"

echo "DO NOT directly run this script."
echo "Build WILL fail at some point."
echo ""
echo "Building QGIS on macOS arm64 is experimental."
echo "Follow the script in terminal instead."
echo ""
echo "Script will run in 10s if you were so inclined."
echo ""
sleep 10

# BOOTSTRAP
# Build Tools
brew install --formula astyle autoconf automake bash-completion ccache cmake help2man libtool meson ninja pandoc pkg-config wget
# Dependencies
# We use pip to install Python modules
brew install --formula bison boost brotli bzip2 curl exiv2 expat fcgi ffmpeg fftw flex fontconfig freetype freexl gdal geos gettext gmp gsl hdf5 icu4c jpeg-xl json-c lapack laszip libdeflate libffi libgeotiff libheif libkml libmpc libomp libpng librasterlite2 librttopo libspatialite libtiff libtool libunistring libxml2 libzip little-cms2 lz4 minizip mpfr mysql netcdf openblas openjpeg openssl@1.1 pcre2 pdal poppler postgresql@14 proj protobuf python3 qca qt@5 qwt-qt5 sfcgdal spatialindex sqlite swig unixodbc uriparser xerces-c webp wxwidgets xz zlib zstd
# Link Qt5
brew link qt@5
export PATH="/opt/homebrew/opt/qt@5/bin:$PATH"
# Same as the official brew recipe, linked with qt5 instead of qt6
brew install dingobits/dingobits/qtkeychain-qt5
# Init workspace
mkdir -p "$WORKSPACE"

# PYENV (OPTIONAL)
# You can skip this step if you don't mind modules being installed to your Python base.
# Build systems don't play well with venv, thus pyenv.
brew install pyenv
export PYENV_ROOT="$HOME/.pyenv"
command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"
PYTHON_CONFIGURE_OPTS="--enable-framework --enable-loadable-sqlite-extensions --enable-ipv6 --enable-optimizations --with-lto=full" pyenv install $PYTHON_VERSION
pyenv local $PYTHON_VERSION

# GDAL
curl -fsSLO http://download.osgeo.org/gdal/$GDAL_VERSION/gdal-$GDAL_VERSION.tar.xz
tar xf gdal-$GDAL_VERSION.tar.xz
mkdir -p gdal-$GDAL_VERSION/build
cd gdal-$GDAL_VERSION/build || exit
cmake -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=$WORKSPACE \
    -DCMAKE_OSX_ARCHITECTURES=arm64 \
    -DCMAKE_OSX_DEPLOYMENT_TARGET=12.0 \
    -DCMAKE_OSX_SYSROOT=$SDKROOT \
    -DCMAKE_MACOSX_RPATH=0 \
    -DBUILD_APPS=0 \
    -DBUILD_SHARED_LIBS=1 \
    -DBUILD_TESTING=0 \
    -DBUILD_CSHARP_BINDINGS=0 \
    -DBUILD_JAVA_BINDINGS=0 \
    -DGDAL_USE_OPENCL=1 \
    -DENABLE_IPO=1 \
    -DBISON_EXECUTABLE=$HOMEBREW_PREFIX/opt/bison/bin/bison \
    -DCFITSIO_INCLUDE_DIR=$HOMEBREW_PREFIX/opt/cfitsio/include \
    -DCFITSIO_LIBRARY=$HOMEBREW_PREFIX/opt/cfitsio/lib/libcfitsio.dylib \
    -DDeflate_INCLUDE_DIR=$HOMEBREW_PREFIX/opt/libdeflate/include \
    -DDeflate_LIBRARY_RELEASE=$HOMEBREW_PREFIX/opt/libdeflate/lib/libdeflate.dylib \
    -DEXPAT_INCLUDE_DIR=$HOMEBREW_PREFIX/opt/expat/include \
    -DEXPAT_LIBRARY=$HOMEBREW_PREFIX/opt/expat/lib/libexpat.dylib \
    -DFREEXL_INCLUDE_DIR=$HOMEBREW_PREFIX/opt/freexl/include \
    -DFREEXL_LIBRARY=$HOMEBREW_PREFIX/opt/freexl/lib/libfreexl.dylib \
    -DFLEX_EXECUTABLE=$HOMEBREW_PREFIX/opt/flex/bin/flex \
    -DFLEX_INCLUDE_DIR=$HOMEBREW_PREFIX/opt/flex/include \
    -DFL_LIBRARY=$HOMEBREW_PREFIX/opt/flex/lib/libfl.dylib \
    -DGEOS_DIR=$HOMEBREW_PREFIX/opt/geos/lib/cmake/GEOS \
    -DGEOTIFF_INCLUDE_DIR=$HOMEBREW_PREFIX/opt/libgeotiff/include \
    -DGEOTIFF_LIBRARY_RELEASE=$HOMEBREW_PREFIX/opt/libgeotiff/lib/libgeotiff.dylib \
    -DGIF_INCLUDE_DIR=$HOMEBREW_PREFIX/opt/giflib/include \
    -DGIF_LIBRARY=$HOMEBREW_PREFIX/opt/giflib/lib/libgif.dylib \
    -DHDF5_C_COMPILER_EXECUTABLE=$HOMEBREW_PREFIX/opt/hdf5/bin/h5cc \
    -DHDF5_C_INCLUDE_DIR=$HOMEBREW_PREFIX/opt/hdf5/include \
    -DHDF5_C_LIBRARY_hdf5=$HOMEBREW_PREFIX/opt/hdf5/lib/libhdf5.dylib \
    -DHDF5_C_LIBRARY_sz=$HOMEBREW_PREFIX/opt/libaec/lib/libsz.dylib \
    -DHDF5_CXX_COMPILER_EXECUTABLE=$HOMEBREW_PREFIX/opt/hdf5/bin/h5c++ \
    -DHDF5_CXX_INCLUDE_DIR=$HOMEBREW_PREFIX/opt/hdf5/include \
    -DHDF5_CXX_LIBRARY_hdf5=$HOMEBREW_PREFIX/opt/hdf5/lib/libhdf5.dylib \
    -DHDF5_CXX_LIBRARY_hdf5_cpp=$HOMEBREW_PREFIX/opt/hdf5/lib/libhdf5_cpp.dylib \
    -DHDF5_CXX_LIBRARY_sz=$HOMEBREW_PREFIX/opt/libaec/lib/libsz.dylib \
    -DHDF5_DIFF_EXECUTABLE=$HOMEBREW_PREFIX/opt/hdf5/bin/h5diff \
    -DHDF5_hdf5_LIBRARY_RELEASE=$HOMEBREW_PREFIX/opt/hdf5/lib/libhdf5.dylib \
    -DHDF5_hdf5_cpp_LIBRARY_RELEASE=$HOMEBREW_PREFIX/opt/hdf5/lib/libhdf5_cpp.dylib \
    -DHEIF_INCLUDE_DIR=$HOMEBREW_PREFIX/opt/libheif/include \
    -DHEIF_LIBRARY=$HOMEBREW_PREFIX/opt/libheif/lib/libheif.dylib \
    -DImath_INCLUDE_DIR=$HOMEBREW_PREFIX/opt/imath/include/Imath \
    -DJPEG_INCLUDE_DIR=$HOMEBREW_PREFIX/opt/jpeg-turbo/include \
    -DJPEG_LIBRARY_RELEASE=$HOMEBREW_PREFIX/opt/jpeg-turbo/lib/libjpeg.dylib \
    -DJXL_INCLUDE_DIR=$HOMEBREW_PREFIX/opt/jpeg-xl/include \
    -DJXL_LIBRARY=$HOMEBREW_PREFIX/opt/jpeg-xl/lib/libjxl.dylib \
    -DLIBKML_INCLUDE_DIR=$HOMEBREW_PREFIX/opt/libkml/include \
    -DLIBKML_BASE_LIBRARY=$HOMEBREW_PREFIX/opt/libkml/lib/libkmlbase.dylib \
    -DLIBKML_DOM_LIBRARY=$HOMEBREW_PREFIX/opt/libkml/lib/libkmldom.dylib \
    -DLIBKML_ENGINE_LIBRARY=$HOMEBREW_PREFIX/opt/libkml/lib/libkmlengine.dylib \
    -DLIBLZMA_INCLUDE_DIR=$HOMEBREW_PREFIX/opt/xz/include \
    -DLIBLZMA_LIBRARY_RELEASE=$HOMEBREW_PREFIX/opt/xz/lib/liblzma.dylib \
    -DLZ4_INCLUDE_DIR=$HOMEBREW_PREFIX/opt/lz4/include \
    -DLZ4_LIBRARY_RELEASE=$HOMEBREW_PREFIX/opt/lz4/lib/liblz4.dylib \
    -DMYSQL_INCLUDE_DIR=$HOMEBREW_PREFIX/opt/mysql/include/mysql \
    -DMYSQL_LIBRARY=$HOMEBREW_PREFIX/opt/mysql/lib/libmysqlclient.dylib \
    -D_MYSQL_ZLIB_LIBRARY=$HOMEBREW_PREFIX/opt/zlib/lib/libz.dylib \
    -D_MYSQL_ZSTD_LIBRARY=$HOMEBREW_PREFIX/opt/zstd/lib/libzstd.dylib \
    -DNetCDF_DIR=$HOMEBREW_PREFIX/opt/netcdf/lib/cmake/netCDF \
    -DODBC_CONFIG=$HOMEBREW_PREFIX/opt/unixodbc/bin/odbc_config \
    -DODBC_INCLUDE_DIR=$HOMEBREW_PREFIX/opt/unixodbc/include \
    -DODBC_LIBRARY=$HOMEBREW_PREFIX/opt/unixodbc/lib/libodbc.dylib \
    -DODBC_ODBCINST_LIBRARY=$HOMEBREW_PREFIX/opt/unixodbc/lib/libodbcinst.dylib \
    -DOpenEXR_INCLUDE_DIR=$HOMEBREW_PREFIX/opt/openexr/include/OpenEXR \
    -DOpenEXR_HALF_LIBRARY=$HOMEBREW_PREFIX/opt/imath/lib/libImath.dylib \
    -DOpenEXR_IEX_LIBRARY=$HOMEBREW_PREFIX/opt/openexr/lib/libIex.dylib \
    -DOpenEXR_LIBRARY=$HOMEBREW_PREFIX/opt/openexr/lib/libOpenEXR.dylib \
    -DOpenEXR_UTIL_LIBRARY=$HOMEBREW_PREFIX/opt/openexr/lib/libOpenEXRUtil.dylib \
    -DOPENJPEG_INCLUDE_DIR=$HOMEBREW_PREFIX/opt/openjpeg/include/openjpeg-2.5 \
    -DOPENJPEG_LIBRARY=$HOMEBREW_PREFIX/opt/openjpeg/lib/libopenjp2.dylib \
    -DOPENSSL_INCLUDE_DIR=$HOMEBREW_PREFIX/opt/openssl@1.1/include \
    -DOPENSSL_CRYPTO_LIBRARY=$HOMEBREW_PREFIX/opt/openssl@1.1/lib/libcrypto.dylib \
    -DOPENSSL_SSL_LIBRARY=$HOMEBREW_PREFIX/opt/openssl@1.1/lib/libssl.dylib \
    -DPCRE2_INCLUDE_DIR=$HOMEBREW_PREFIX/opt/pcre2/include \
    -DPCRE2-8_LIBRARY=$HOMEBREW_PREFIX/opt/pcre2/lib/libpcre2-8.dylib \
    -DPNG_PNG_INCLUDE_DIR=$HOMEBREW_PREFIX/opt/libpng/include \
    -DPNG_LIBRARY_RELEASE=$HOMEBREW_PREFIX/opt/libpng/lib/libpng.dylib \
    -DPoppler_INCLUDE_DIR=$HOMEBREW_PREFIX/opt/poppler/include/poppler \
    -DPoppler_LIBRARY=$HOMEBREW_PREFIX/opt/poppler/lib/libpoppler.dylib \
    -DPostgreSQL_INCLUDE_DIR=$HOMEBREW_PREFIX/opt/postgresql@14/include \
    -DPostgreSQL_LIBRARY_RELEASE=$HOMEBREW_PREFIX/opt/postgresql@14/lib/libpq.dylib \
    -DPROJ_DIR=$HOMEBREW_PREFIX/opt/proj/lib/cmake/proj \
    -DRASTERLITE2_INCLUDE_DIR=$HOMEBREW_PREFIX/opt/librasterlite2/include \
    -DRASTERLITE2_LIBRARY=$HOMEBREW_PREFIX/opt/librasterlite2/lib/librasterlite2.dylib \
    -DSPATIALITE_INCLUDE_DIR=$HOMEBREW_PREFIX/opt/libspatialite/include \
    -DSPATIALITE_LIBRARY=$HOMEBREW_PREFIX/opt/libspatialite/lib/libspatialite.dylib \
    -DSQLite3_INCLUDE_DIR=$HOMEBREW_PREFIX/opt/sqlite/include \
    -DSQLITE3EXT_INCLUDE_DIR=$HOMEBREW_PREFIX/opt/sqlite/include \
    -DSQLite3_LIBRARY=$HOMEBREW_PREFIX/opt/sqlite/lib/libsqlite3.dylib \
    -DSWIG_EXECUTABLE=$HOMEBREW_PREFIX/opt/swig/bin/swig \
    -DTIFF_INCLUDE_DIR=$HOMEBREW_PREFIX/opt/libtiff/include \
    -DTIFF_LIBRARY=$HOMEBREW_PREFIX/opt/libtiff/lib/libtiff.dylib \
    -DWEBP_INCLUDE_DIR=$HOMEBREW_PREFIX/opt/webp/include \
    -DWEBP_LIBRARY=$HOMEBREW_PREFIX/opt/webp/lib/libwebp.dylib \
    -DXercesC_INCLUDE_DIR=$HOMEBREW_PREFIX/opt/xerces-c/include \
    -DXercesC_LIBRARY_RELEASE=$HOMEBREW_PREFIX/opt/xerces-c/lib/libxerces-c.dylib \
    -DZLIB_INCLUDE_DIR=$HOMEBREW_PREFIX/opt/zlib/include \
    -DZLIB_LIBRARY_RELEASE=$HOMEBREW_PREFIX/opt/zlib/lib/libz.dylib \
    -DZSTD_DIR=$HOMEBREW_PREFIX/opt/zstd/lib/cmake/zstd \
    ..
ninja
ninja install
# Install absolute path
install_name_tool -id "$WORKSPACE/lib/libgdal.31.dylib" "$WORKSPACE/lib/libgdal.31.dylib"

# PDAL
curl -fsSLO "https://github.com/PDAL/PDAL/releases/download/$PDAL_VERSION/PDAL-$PDAL_VERSION-src.tar.gz"
tar xf PDAL-$PDAL_VERSION-src.tar.gz
mkdir -p PDAL-$PDAL_VERSION-src/build
cd PDAL-$PDAL_VERSION-src/build || exit
cmake -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=$WORKSPACE \
    -DCMAKE_OSX_ARCHITECTURES=arm64 \
    -DCMAKE_OSX_DEPLOYMENT_TARGET=12.0 \
    -DCMAKE_OSX_SYSROOT=$SDKROOT \
    -DBUILD_PLUGIN_E57=1 \
    -DBUILD_PLUGIN_HDF=1 \
    -DBUILD_PLUGIN_I3S=1 \
    -DBUILD_PLUGIN_ICEBRIDGE=1 \
    -DBUILD_PLUGIN_PGPOINTCLOUD=1 \
    -DGDAL_INCLUDE_DIR=$WORKSPACE/include \
    -DGDAL_LIBRARY=$WORKSPACE/lib/libgdal.dylib \
    -DGEOTIFF_INCLUDE_DIR=$HOMEBREW_PREFIX/opt/libgeotiff/include \
    -DGEOTIFF_LIBRARY=$HOMEBREW_PREFIX/opt/libgeotiff/lib/libgeotiff.dylib \
    -DHDF5_CXX_COMPILER_EXECUTABLE=$HOMEBREW_PREFIX/opt/hdf5/bin/h5c++ \
    -DHDF5_CXX_INCLUDE_DIR=$HOMEBREW_PREFIX/opt/hdf5/include \
    -DHDF5_CXX_LIBRARY_hdf5=$HOMEBREW_PREFIX/opt/hdf5/lib/libhdf5.dylib \
    -DHDF5_CXX_LIBRARY_hdf5_cpp=$HOMEBREW_PREFIX/opt/hdf5/lib/libhdf5_cpp.dylib \
    -DHDF5_CXX_LIBRARY_sz=$HOMEBREW_PREFIX/opt/libaec/lib/libsz.dylib \
    -DHDF5_DIFF_EXECUTABLE=$HOMEBREW_PREFIX/opt/hdf5/bin/h5diff \
    -DHDF5_hdf5_LIBRARY_RELEASE=$HOMEBREW_PREFIX/opt/hdf5/lib/libhdf5.dylib \
    -DHDF5_hdf5_cpp_LIBRARY_RELEASE=$HOMEBREW_PREFIX/opt/hdf5/lib/libhdf5_cpp.dylib \
    -DLIBLZMA_INCLUDE_DIR=$HOMEBREW_PREFIX/opt/xz/include \
    -DLIBLZMA_LIBRARY_RELEASE=$HOMEBREW_PREFIX/opt/xz/lib/liblzma.dylib \
    -DOPENSSL_INCLUDE_DIR=$HOMEBREW_PREFIX/opt/openssl@1.1/include \
    -DOPENSSL_CRYPTO_LIBRARY=$HOMEBREW_PREFIX/opt/openssl@1.1/lib/libcrypto.dylib \
    -DOPENSSL_SSL_LIBRARY=$HOMEBREW_PREFIX/opt/openssl@1.1/lib/libssl.dylib \
    -DPostgreSQL_INCLUDE_DIR=$HOMEBREW_PREFIX/opt/postgresql@14/include \
    -DPostgreSQL_LIBRARY_RELEASE=$HOMEBREW_PREFIX/opt/postgresql@14/lib/libpq.dylib \
    -DXercesC_INCLUDE_DIR=$HOMEBREW_PREFIX/opt/xerces-c/include \
    -DXercesC_LIBRARY_RELEASE=$HOMEBREW_PREFIX/opt/xerces-c/lib/libxerces-c.dylib \
    -DZSTD_INCLUDE_DIR=$HOMEBREW_PREFIX/opt/zstd/include \
    -DZSTD_LIBRARY=$HOMEBREW_PREFIX/opt/zstd/lib/libzstd.dylib \
    ..
ninja
ninja install

# SAGA
curl -fsSLO "https://downloads.sourceforge.net/project/saga-gis/SAGA%20-%208/SAGA%20-%20$SAGA_VERSION/saga-$SAGA_VERSION.tar.gz"
tar xf saga-$SAGA_VERSION.tar.gz
mkdir -p "saga-$SAGA_VERSION/saga-gis/build"
cd "saga-$SAGA_VERSION/saga-gis/build" || exit
cmake -G Ninja \
    -DCMAKE_BUILD_TYPE=RELEASE \
    -DCMAKE_INSTALL_PREFIX="$WORKSPACE" \
    -DCMAKE_OSX_ARCHITECTURES=arm64 \
    -DCMAKE_OSX_DEPLOYMENT_TARGET=12.0 \
    -DCMAKE_OSX_SYSROOT=$SDKROOT \
    -DGDAL_CONFIG=$WORKSPACE/bin/gdal-config \
    -DGDAL_INCLUDE_DIR=$WORKSPACE/include \
    -DGDAL_LIBRARY=$WORKSPACE/lib/libgdal.dylib \
    -DODBC_CONFIG=$HOMEBREW_PREFIX/opt/unixodbc/bin/odbc_config \
    -DODBC_INCLUDE_DIR=$HOMEBREW_PREFIX/opt/unixodbc/include \
    -DODBC_LIBRARY=$HOMEBREW_PREFIX/opt/unixodbc/lib/libodbc.dylib \
    -DPDAL_INCLUDE_DIR=$WORKSPACE/include \
    -DPDAL_CPP_LIBRARY=$WORKSPACE/lib/libpdalcpp.dylib \
    -DPDAL_UTIL_LIBRARY=$WORKSPACE/lib/libpdal_util.dylib \
    -DPOSTGRES_CONFIG=$HOMEBREW_PREFIX/opt/postgresql@14/bin/pg_config \
    -DPOSTGRES_INCLUDE_DIR=$HOMEBREW_PREFIX/opt/postgresql@14/include/postgresql@14 \
    -DPOSTGRES_LIBRARY=$HOMEBREW_PREFIX/opt/postgresql@14/lib/postgresql@14/libpq.dylib \
    -DPROJ_INCLUDE_DIR=$HOMEBREW_PREFIX/opt/proj/include \
    -DPROJ_LIBRARY=$HOMEBREW_PREFIX/opt/proj/lib/libproj.dylib \
    ..
ninja
ninja install
cd ../../.. || exit

# GRASSGIS
curl -fsSLo grass-$GRASS_VERSION.tar.gz https://github.com/OSGeo/grass/archive/refs/tags/$GRASS_VERSION.tar.gz
tar xf grass-$GRASS_VERSION.tar.gz
cd grass-$GRASS_VERSION || exit
# Python modules for Grass
python3 -m pip install --upgrade pip
pip3 install matplotlib numpy pillow ply python-dateutil six termcolor wxpython
pyenv rehash
./configure \
    --prefix=$WORKSPACE \
    --exec-prefix=$WORKSPACE \
    --enable-macosx-app \
    --enable-largefile \
    --with-tiff \
    --with-png \
    --with-postgres \
    --with-mysql \
    --with-sqlite \
    --with-opengl=mac \
    --with-odbc \
    --with-fftw \
    --with-blas \
    --with-lapack \
    --with-cairo \
    --with-freetype \
    --with-nls \
    --with-readline \
    --without-opendwg \
    --with-regex \
    --with-pthread \
    --with-openmp \
    --with-opencl \
    --with-bzlib \
    --with-zstd \
    --without-x \
    --with-macosx-sdk=$SDKROOT \
    --with-gdal=$WORKSPACE/bin/gdal-config \
    --with-pdal=$HOMEBREW_PREFIX/opt/pdal/bin/pdal-config \
    --with-wxwidgets=$HOMEBREW_PREFIX/opt/wxwidgets/bin/wx-config \
    --with-netcdf=$HOMEBREW_PREFIX/opt/netcdf/bin/nc-config \
    --with-geos=$HOMEBREW_PREFIX/opt/geos/bin/geos-config \
    --with-zlib-includes=$WORKSPACE/include \
    --with-zlib-libs=$WORKSPACE/lib \
    --with-bzlib-includes=$HOMEBREW_PREFIX/opt/bzip2/include \
    --with-bzlib-libs=$HOMEBREW_PREFIX/opt/bzip2/lib \
    --with-zstd-includes=$HOMEBREW_PREFIX/opt/zstd/include \
    --with-zstd-libs=$HOMEBREW_PREFIX/opt/zstd/lib \
    --with-readline-includes=$HOMEBREW_PREFIX/opt/readline/include \
    --with-readline-libs=$HOMEBREW_PREFIX/opt/readline/lib \
    --with-tiff-includes=$HOMEBREW_PREFIX/opt/libtiff/include \
    --with-tiff-libs=$HOMEBREW_PREFIX/opt/libtiff/lib \
    --with-png-includes=$HOMEBREW_PREFIX/opt/libpng/include \
    --with-png-libs=$HOMEBREW_PREFIX/opt/libpng/lib \
    --with-postgres-includes=$HOMEBREW_PREFIX/opt/postgresql@14/include/postgresql@14 \
    --with-postgres-libs=$HOMEBREW_PREFIX/opt/postgresql@14/lib/postgresql@14 \
    --with-mysql-includes=$HOMEBREW_PREFIX/opt/mysql/include/mysql \
    --with-mysql-libs=$HOMEBREW_PREFIX/opt/mysql/lib \
    --with-sqlite-includes=$HOMEBREW_PREFIX/opt/sqlite/include \
    --with-sqlite-libs=$HOMEBREW_PREFIX/opt/sqlite/lib \
    --with-odbc-includes=$HOMEBREW_PREFIX/opt/unixodbc/include \
    --with-odbc-libs=$HOMEBREW_PREFIX/opt/unixodbc/lib \
    --with-fftw-includes=$HOMEBREW_PREFIX/opt/fftw/include \
    --with-fftw-libs=$HOMEBREW_PREFIX/opt/fftw/lib \
    --with-blas-includes=$HOMEBREW_PREFIX/opt/openblas/include \
    --with-blas-libs=$HOMEBREW_PREFIX/opt/openblas/lib \
    --with-lapack-includes=$HOMEBREW_PREFIX/opt/lapack/include \
    --with-lapack-libs=$HOMEBREW_PREFIX/opt/lapack/lib \
    --with-cairo-includes=$HOMEBREW_PREFIX/opt/cairo/include \
    --with-cairo-libs=$HOMEBREW_PREFIX/opt/cairo/lib \
    --with-freetype-includes=$HOMEBREW_PREFIX/opt/freetype2/include/freetype2 \
    --with-freetype-libs=$HOMEBREW_PREFIX/opt/freetype2/lib \
    --with-proj-includes=$HOMEBREW_PREFIX/opt/proj/include \
    --with-proj-libs=$HOMEBREW_PREFIX/opt/proj/lib \
    --with-proj-share=$HOMEBREW_PREFIX/opt/proj/share/proj \
    --with-openmp-includes=$HOMEBREW_PREFIX/opt/libomp/include \
    --with-openmp-libs=$HOMEBREW_PREFIX/opt/libomp/lib
make -j4
make install
chmod -R 755 $WORKSPACE/grass82
# QTWEBKIT
# This is `HEAD`. 5.212a4 will not compile.
curl https://download.qt.io/snapshots/ci/qtwebkit/5.212/latest/src/submodules/qtwebkit-opensource-src-5.212.tar.xz
tar xf qtwebkit-opensource-src-5.212.tar.xz
mkdir build
cd qtwebkit-opensource-src-5.212/build || exit
cmake \
    -DCMAKE_BUILD_TYPE=RELEASE \
    -DCMAKE_INSTALL_PREFIX=$WORKSPACE \
    -DCMAKE_OSX_ARCHITECTURES=arm64 \
    -DCMAKE_OSX_DEPLOYMENT_TARGET=12.0 \
    -DCMAKE_OSX_SYSROOT=$SDKROOT \
    -DPORT=Qt \
    -DQt5_DIR=$HOMEBREW_PREFIX/opt/qt@5/lib/cmake/Qt5 \
    -DJPEG_INCLUDE_DIR=$HOMEBREW_PREFIX/opt/jpeg-turbo/include \
    -DJPEG_LIBRARY_RELEASE=$HOMEBREW_PREFIX/opt/jpeg-turbo/lib/libjpeg.a \
    -DWEBP_INCLUDE_DIRS=$HOMEBREW_PREFIX/opt/webp/include \
    -DWEBP_LIBRARIES=$HOMEBREW_PREFIX/opt/wep/lib/libwebp.a \
    ..
ninja
ninja install
cd ../.. || exit

# PYQT
autopep8 future httplib2 lxml nose2 plotly
pip3 install jinja2 markupsafe owslib psycopg2 pygments requests sip
pip3 install --config-settings="--confirm-license=" pyqt5 pyqt5-sip pyqt-builder
pip3 install pyqtnetworkauth pyqtpurchasing pyqtchart pyqt3d pyqtdatavisualization qscintilla

# QGIS
curl -fsSLO https://download.qgis.org/downloads/qgis-$QGIS_VERSION.tar.bz2
tar xf qgis-$QGIS_VERSION.tar.bz2
mkdir qgis-$QGIS_VERSION/build
cd qgis-$QGIS_VERSION/build || exit
cmake -G Ninja \
    -DCMAKE_BUILD_TYPE=RELEASE \
    -DCMAKE_INSTALL_PREFIX=$WORKSPACE \
    -DCMAKE_OSX_ARCHITECTURES=arm64 \
    -DCMAKE_OSX_DEPLOYMENT_TARGET=12.0 \
    -DCMAKE_OSX_SYSROOT=$SDKROOT \
    -DCMAKE_CXX_STANDARD=14 \
    -DQGIS_MAC_DEPS_DIR=$HOMEBREW_PREFIX \
    -DQGIS_MACAPP_BUNDLE=1 \
    -DENABLE_TESTS=0 \
    -DWITH_3D=1 \
    -DWITH_ANALYSIS=1 \
    -DWITH_ASTYLE=1 \
    -DWITH_AUTH=1 \
    -DWITH_BINDINGS=1 \
    -DWITH_COPC=1 \
    -DWITH_CRASH_HANDLER=0 \
    -DWITH_CUSTOM_WIDGETS=0 \
    -DWITH_DESKTOP=1 \
    -DWITH_EPT=1 \
    -DWITH_GRASS7=0 \
    -DWITH_GRASS8=1 \
    -DWITH_GSL=1 \
    -DWITH_GUI=1 \
    -DWITH_HANA=0 \
    -DWITH_ORACLE=0 \
    -DWITH_PDAL=1 \
    -DWITH_POSTGRESQL=1 \
    -DWITH_PY_COMPILE=0 \
    -DWITH_QGIS_PROCESS=1 \
    -DWITH_QSPATIALITE=1 \
    -DWITH_QT5SERIALPORT=1 \
    -DWITH_QTWEBKIT=1 \
    -DWITH_QUICK=1 \
    -DWITH_QWTPOLAR=0 \
    -DWITH_QUICK=1 \
    -DWITH_SERVER=1 \
    -DWITH_SPATIALITE=1 \
    -DSERVER_SKIP_ECW=1 \
    -DAPPLE_APPKIT_LIBRARY=$SDKROOT/System/Library/Frameworks/AppKit.framework \
    -DAPPLE_APPLICATIONSERVICES_LIBRARY=$SDKROOT/System/Library/Frameworks/ApplicationServices.framework \
    -DAPPLE_COREFOUNDATION_LIBRARY=$SDKROOT/System/Library/Frameworks/CoreFoundation.framework \
    -DAPPLE_IOKIT_LIBRARY=$SDKROOT/System/Library/Frameworks/IOKit.framework \
    -DBISON_EXECUTABLE=$HOMEBREW_PREFIX/opt/bison/bin/bison \
    -DEXIV2_INCLUDE_DIR=$HOMEBREW_PREFIX/opt/exiv2/include \
    -DEXIV2_LIBRARY=$HOMEBREW_PREFIX/opt/exiv2/lib/libexiv2.dylib \
    -DFCGI_INCLUDE_DIR=$HOMEBREW_PREFIX/opt/fastcgi/include \
    -DEXPAT_INCLUDE_DIR=$HOMEBREW_PREFIX/opt/expat/include \
    -DEXPAT_LIBRARY=$HOMEBREW_PREFIX/opt/expat/lib/libexpat.dylib \
    -DFCGI_LIBRARY=$HOMEBREW_PREFIX/opt/fastcgi/lib/libfcgi.dylib \
    -DFLEX_EXECUTABLE=$HOMEBREW_PREFIX/opt/flex/bin/flex \
    -DFLEX_INCLUDE_DIR=$HOMEBREW_PREFIX/opt/flex/include \
    -DFL_LIBRARY=$HOMEBREW_PREFIX/opt/flex/lib/libfl.dylib \
    -DGDAL_INCLUDE_DIR=$WORKSPACE/include \
    -DGDAL_LIBRARY=$WORKSPACE/lib/libgdal.dylib \
    -DGEOS_INCLUDE_DIR=$HOMEBREW_PREFIX/opt/geos/include \
    -DGEOS_LIBRARY=$HOMEBREW_PREFIX/opt/geos/lib/libgeos_c.dylib \
    -DGRASS_INCLUDE_DIR8=$WORKSPACE/grass82/include \
    -DGRASS_PREFIX8=$WORKSPACE/grass82 \
    -DGSL_INCLUDE_DIR=$HOMEBREW_PREFIX/opt/gsl/include \
    -DGSL_LIBRARIES=$HOMEBREW_PREFIX/opt/gsl/lib/libgsl.dylib \
    -DLIBZIP_CONF_INCLUDE_DIR=$HOMEBREW_PREFIX/opt/libzip/include \
    -DLIBZIP_INCLUDE_DIR=$HOMEBREW_PREFIX/opt/libzip/include \
    -DLIBZIP_LIBRARY=$HOMEBREW_PREFIX/opt/libzip/lib/libzip.dylib \
    -DNETCDF_INCLUDE_DIR=$HOMEBREW_PREFIX/opt/netcdf/include \
    -DNETCDF_LIBRARY=$HOMEBREW_PREFIX/opt/netcdf/lib/libnetcdf.dylib \
    -DPDAL_BIN=$HOMEBREW_PREFIX/opt/pdal/bin/pdal \
    -DPDAL_CPP_LIBRARY=$HOMEBREW_PREFIX/opt/pdal/lib/libpdalcpp.dylib \
    -DPDAL_INCLUDE_DIR=$HOMEBREW_PREFIX/opt/pdal/include \
    -DPDAL_UTIL_LIBRARY=$HOMEBREW_PREFIX/opt/pdal/lib/libpdal_util.dylib \
    -DPOSTGRESQL_PREFIX=$HOMEBREW_PREFIX/opt/postgresql@14 \
    -DPostgreSQL_INCLUDE_DIR=$HOMEBREW_PREFIX/opt/postgresql@14/include/postgresql@14 \
    -DPostgreSQL_INCLUDE_DIR=$HOMEBREW_PREFIX/opt/postgresql@14/include/postgresql@14 \
    -DPostgreSQL_LIBRARY_RELEASE=$HOMEBREW_PREFIX/opt/postgresql@14/lib/postgresql@14/libpq.dylib \
    -DPROJ_INCLUDE_DIR=$HOMEBREW_PREFIX/opt/proj/include \
    -DPROJ_LIBRARY=$HOMEBREW_PREFIX/opt/proj/lib/libproj.dylib \
    -DProtobuf_INCLUDE_DIR=$HOMEBREW_PREFIX/opt/protobuf/include \
    -DProtobuf_LIBRARY_RELEASE=$HOMEBREW_PREFIX/opt/protobuf/lib/libprotobuf.dylib \
    -DProtobuf_LITE_LIBRARY_RELEASE=$HOMEBREW_PREFIX/opt/protobuf/lib/libprotobuf-lite.dylib \
    -DProtobuf_PROTOC_EXECUTABLE=$HOMEBREW_PREFIX/opt/protobuf/bin/protoc \
    -DProtobuf_PROTOC_LIBRARY_RELEASE=$HOMEBREW_PREFIX/opt/protobuf/lib/libprotoc.dylib \
    -DQCA_INCLUDE_DIR=$HOMEBREW_PREFIX/opt/qca/lib/qca-qt5.framework/Headers \
    -DQCA_LIBRARY=$HOMEBREW_PREFIX/opt/qca/lib/qca-qt5.framework \
    -DQTKEYCHAIN_INCLUDE_DIR=$HOMEBREW_PREFIX/opt/qtkeychain/include/qt5keychain \
    -DQTKEYCHAIN_LIBRARY=$HOMEBREW_PREFIX/opt/qtkeychain/lib/libqt5keychain.dylib \
    -DQWT_INCLUDE_DIR=$HOMEBREW_PREFIX/opt/qwt-qt5/lib/qwt.framework/Versions/Current/Headers \
    -DQWT_LIBRARY=$HOMEBREW_PREFIX/opt/qwt-qt5/lib/qwt.framework \
    -DQt5_DIR=$HOMEBREW_PREFIX/opt/qt@5/lib/cmake/Qt5 \
    -DQt5Core_DIR=$HOMEBREW_PREFIX/opt/qt@5/lib/cmake/Qt5Core \
    -DQt5SerialPort_DIR=$HOMEBREW_PREFIX/opt/qt@5/lib/cmake/Qt5SerialPort \
    -DQt5Gui_DIR=$HOMEBREW_PREFIX/opt/qt@5/lib/cmake/Qt5Gui \
    -DQt5Widgets_DIR=$HOMEBREW_PREFIX/opt/qt@5/lib/cmake/Qt5Widgets \
    -DQt5Network_DIR=$HOMEBREW_PREFIX/opt/qt@5/lib/cmake/Qt5Network \
    -DQt5Xml_DIR=$HOMEBREW_PREFIX/opt/qt@5/lib/cmake/Qt5Xml \
    -DQt5Svg_DIR=$HOMEBREW_PREFIX/opt/qt@5/lib/cmake/Qt5Svg \
    -DQt5Concurrent_DIR=$HOMEBREW_PREFIX/opt/qt@5/lib/cmake/Qt5Concurrent \
    -DQt5Test_DIR=$HOMEBREW_PREFIX/opt/qt@5/lib/cmake/Qt5Test \
    -DQt5UiTools_DIR=$HOMEBREW_PREFIX/opt/qt@5/lib/cmake/Qt5UiTools \
    -DQt5Sql_DIR=$HOMEBREW_PREFIX/opt/qt@5/lib/cmake/Qt5Sql \
    -DQt5PrintSupport_DIR=$HOMEBREW_PREFIX/opt/qt@5/lib/cmake/Qt5PrintSupport \
    -DQt5Positioning_DIR=$HOMEBREW_PREFIX/opt/qt@5/lib/cmake/Qt5Positioning \
    -DQt53DCore_DIR=$HOMEBREW_PREFIX/opt/qt@5/lib/cmake/Qt53DCore \
    -DQt53DRender_DIR=$HOMEBREW_PREFIX/opt/qt@5/lib/cmake/Qt53DRender \
    -DQt53DInput_DIR=$HOMEBREW_PREFIX/opt/qt@5/lib/cmake/Qt53DInput \
    -DQt5Gamepad_DIR=$HOMEBREW_PREFIX/opt/qt@5/lib/cmake/Qt5Gamepad \
    -DQt53DLogic_DIR=$HOMEBREW_PREFIX/opt/qt@5/lib/cmake/Qt53DLogic \
    -DQt53DExtras_DIR=$HOMEBREW_PREFIX/opt/qt@5/lib/cmake/Qt53DExtras \
    -DQt5Qml_DIR=$HOMEBREW_PREFIX/opt/qt@5/lib/cmake/Qt5Qml \
    -DQt5QuickWidgets_DIR=$HOMEBREW_PREFIX/opt/qt@5/lib/cmake/Qt5QuickWidgets \
    -DQt5Quick_DIR=$HOMEBREW_PREFIX/opt/qt@5/lib/cmake/Qt5Quick \
    -DQt5QmlModels_DIR=$HOMEBREW_PREFIX/opt/qt@5/lib/cmake/Qt5QmlModels \
    -DQt5LinguistTools_DIR=$HOMEBREW_PREFIX/opt/qt@5/lib/cmake/Qt5LinguistTools \
    -DQt5WebKit_DIR=$HOMEBREW_PREFIX/opt/qtwebkit/lib/cmake/Qt5WebKit \
    -DQt5WebKitWidgets_DIR=$HOMEBREW_PREFIX/opt/qtwebkit/lib/cmake/Qt5WebKitWidgets \
    -DSPATIALINDEX_INCLUDE_DIR=$HOMEBREW_PREFIX/opt/spatialindex/include \
    -DSPATIALINDEX_LIBRARY=$HOMEBREW_PREFIX/opt/spatialindex/lib/libspatialindex.dylib \
    -DSPATIALITE_INCLUDE_DIR=$HOMEBREW_PREFIX/opt/libspatialite/include \
    -DSPATIALITE_LIBRARY=$HOMEBREW_PREFIX/opt/libspatialite/lib/libspatialite.dylib \
    -DSQLITE3_INCLUDE_DIR=$HOMEBREW_PREFIX/opt/sqlite/include \
    -DSQLITE3_LIBRARY=$HOMEBREW_PREFIX/opt/sqlite/lib/libsqlite3.dylib \
    -DZSTD_INCLUDE_DIR=$HOMEBREW_PREFIX/opt/zstd/include \
    -DZSTD_LIBRARY=$HOMEBREW_PREFIX/opt/zstd/lib/libzstd.dylib \
    ..
ninja -j4
ninja install

# Congratuations. You've successfully compiled QGIS.
# 
# A dylib-linked app bundle is available at
# $WORKSPACE/qgis-$QGIS_VERSION/build/output/bin/QGIS.app
# 
# A badly packaged app bundle is availble at
# $WORKSPACE/QGIS.app
# 
# If you don't intend to distribute, the former will suffice.
# The latter will not run. See README.md to fix packaging.
