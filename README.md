# QGIS on Apple Silicon

This project aims to build and package [QGIS](https://www.qgis.org) on macOS ARM64. We use [homebrew](https://brew.sh) to bootstrap build environment with [additional formulae](https://github.com/DingoBits/homebrew-dingobits) to fulfill all dependencies.

This is a work in progress. Builds are experimental and bugs are to be expected. Due to complex dependencies and numerous workarounds, a fully functional build script will not be available soon. 

## Requirements
- ARM-based Mac
   - At least 16 GB of RAM is recommended as compile can use up to 8 GB
- Xcode CLI: ``xcode-select --install``
- Homebrew: ``/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"``

## Build Instructions
These are only general steps. Make sure to configure build options. 
1. Install Build Tools
```
brew install --formula astyle autoconf automake bash-completion ccache cmake help2man libtool meson ninja pandoc pkg-config wget
```
2. Install Dependencies
```
brew install --formula bison boost brotli bzip2 exiv2 expat fcgi ffmpeg fftw flex fontconfig freetds freetype freexl gdal geos gettext gmp gsl hdf5 jpeg-xl json-c lapack laszip libdeflate libffi libgeotiff libheif libkml libmpc libomp libpng librasterlite2 librttopo libspatialite libssh2 libtiff libtool libunistring libxml2 libzip little-cms2 lz4 minizip mpfr mysql netcdf openblas openjpeg openssl@1.1 openssl@3 pcre pdal poppler postgresql@14 proj protobuf python3 qca qt@5 dingobits/dingobits/qtwebkit qwt-qt5 spatialindex sqlite swig unixodbc uriparser xerces-c webp wxwidgets xz zlib zstd
```
3. Optional - Install pyenv
    - You can skip this step if you don't mind modules being installed to your Python base.
    - Build systems don't play well with venv, thus pyenv.
```
brew install pyenv
export PYENV_ROOT="$HOME/.pyenv"
command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"
PYTHON_CONFIGURE_OPTS="--enable-framework --enable-ipv6 --enable-loadable-sqlite-extensions --enable-optimizations --with-lto=fat --with-system-expat --with-system-ffi --with-system-libmpdec" pyenv install 3.9.15
pyenv local 3.9.15
python3 -m pip install --upgrade pip
```
3. Build GDAL
    - Homebrew-provided GDAL has fewer features than QGIS needs.
```
curl -fsSLO http://download.osgeo.org/gdal/3.5.3/gdal-3.5.3.tar.xz
tar xf gdal-3.5.3.tar.xz
mkdir -p gdal-3.5.3/build
cd gdal-3.5.3/build || exit
cmake -G Ninja ..
ninja
ninja install
```
4. Build GrassGIS
```
pip3 install matplotlib numpy pillow ply python-dateutil six termcolor wxpython
curl -fsSLo grass-8.2.0.tar.gz https://github.com/OSGeo/grass/archive/refs/tags/8.2.0.tar.gz
tar xf grass-8.2.0.tar.gz
cd grass-8.2.0 || exit
./configure
make -j'nproc'
make install
```
5. Build SAGA
```
curl -fsSLO "https://downloads.sourceforge.net/project/saga-gis/SAGA%20-%208/SAGA%20-%208.4.0/saga-8.4.0.tar.gz"
tar xf saga-8.4.0.tar.gz
mkdir -p "saga-8.4.0/saga-gis/build"
cd "saga-8.4.0/saga-gis/build" || exit
cmake -G Ninja ..
ninja
ninja install
cd ../../.. || exit
```
6. Build PyQT
```
pip3 install autopep8 future httplib2 jinja2 lxml markupsafe mock nose2 owslib plotly psycopg2 pygments requests sip
pip3 install --config-settings="--confirm-license=" pyqt5 pyqt5-sip pyqt-builder
pip3 install pyqtnetworkauth pyqtpurchasing pyqtchart pyqt3d pyqtdatavisualization qscintilla
```
7. Build QGIS
```
curl -fsSLO https://download.qgis.org/downloads/qgis-3.28.0.tar.bz2
tar xf qgis-3.28.0.tar.bz2
mkdir qgis-3.28/build
cd qgis-3.28/build || exit
cmake -G Ninja ..
ninja
ninja install
```
