FROM golang:alpine
LABEL maintanier="Penpen7 <Raosys@live.jp>"
ENV PKG="cmake build-base pkgconf linux-headers zlib-dev zlib-static"
RUN apk update && apk upgrade && apk add --no-cache ${PKG}
ENV OPENCV_VERSION=4.4.0
ENV OPENCV_TMP=/tmp/opencv
ENV CXX g++
ENV CPP g++
ENV CC gcc
RUN mkdir ${OPENCV_TMP} && cd ${OPENCV_TMP} && \
    wget  -O - https://github.com/opencv/opencv/archive/${OPENCV_VERSION}.tar.gz | tar zxf - && \
    wget -O -  https://github.com/opencv/opencv_contrib/archive/${OPENCV_VERSION}.tar.gz | tar zxf - && \
    cd opencv-${OPENCV_VERSION} && mkdir build && cd build && \
    cmake \
    -D CMAKE_BUILD_TYPE=RELEASE \
    -D CMAKE_INSTALL_PREFIX=/usr/local \
    -D OPENCV_EXTRA_MODULES_PATH=${OPENCV_TMP}/opencv_contrib-${OPENCV_VERSION}/modules \
    -D WITH_FFMPEG=OFF \
    -D INSTALL_C_EXAMPLES=NO \
    -D INSTALL_PYTHON_EXAMPLES=NO \
    -D BUILD_ANDROID_EXAMPLES=NO \
    -D BUILD_DOCS=NO \
    -D BUILD_TESTS=NO \
    -D BUILD_PERF_TESTS=NO \
    -D BUILD_EXAMPLES=NO \
    -D BUILD_opencv_java=NO \
    -D BUILD_opencv_python=NO \
    -D BUILD_opencv_python2=NO \
    -D BUILD_opencv_python3=NO \
    -D BUILD_SHARED_LIBS=OFF \
    -D ENABLE_CXX11=ON \
    -D OPENCV_GENERATE_PKGCONFIG=ON .. && \
    make -j4 && \
    make install && \
    cd && rm -rf ${OPENCV_TMP}
RUN apk add --no-cache git && go get -u -d gocv.io/x/gocv

ENV PKG_CONFIG_PATH /usr/local/lib64/pkgconfig:/usr/lib/pkgconfig/
ENV LD_LIBRARY_PATH /usr/local/lib64
ENV CGO_CPPFLAGS -I/usr/local/include
ENV OPENCVCGO $GOPATH/src/gocv.io/x/gocv/cgo.go
RUN echo '// +build !customenv' > ${OPENCVCGO} && \
    echo 'package gocv' >> ${OPENCVCGO} && \
    echo '// Changes here should be mirrored in contrib/cgo.go and cuda/cgo.go.' >> ${OPENCVCGO} && \
    echo '' >> ${OPENCVCGO} && \
    echo '/*' >> ${OPENCVCGO} && \
    echo '#cgo pkg-config: --static opencv4 zlib' >> ${OPENCVCGO} && \
    echo '#cgo CXXFLAGS:   --std=c++11' >> ${OPENCVCGO} && \
    echo '#cgo LDFLAGS:    -static' >> ${OPENCVCGO} && \
    echo '*/' >> ${OPENCVCGO} && \
    echo 'import "C"' >> ${OPENCVCGO}
RUN cd $GOPATH/src/gocv.io/x/gocv/cmd/version && \
    go build -x --ldflags '-extldflags "-s -w -static"' main.go && file ./main && ./main
