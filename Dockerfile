FROM alpine:3.18 as builder

RUN apk add \
    bzip2-dev \
    curl \
    dpkg-dev dpkg \
    expat-dev \
    findutils \
    gcc \
    gdbm-dev \
    libc-dev \
    libffi-dev \
    linux-headers \
    make \
    ncurses-dev \
    openssl1.1-compat-dev \
    patch \
    pax-utils \
    readline-dev \
    sqlite-dev \
    util-linux-dev \
    xz-dev \
    zlib-dev

ENV PYTHON_VERSION=2.7.18

COPY patches /root/patches/

RUN mkdir /usr/local/src \
 && curl -L -s -o /usr/local/src/Python-${PYTHON_VERSION}.tgz "https://www.python.org/ftp/python/$PYTHON_VERSION/Python-$PYTHON_VERSION.tgz" \
 && cd /usr/local/src \
 && tar xzvf Python-${PYTHON_VERSION}.tgz \
 && cd Python-${PYTHON_VERSION} \
 && patch -p 1 -i /root/patches/unchecked-ioctl.patch \
 && patch -p 1 -i /root/patches/musl-find_library.patch \
 && patch -p 1 -i /root/patches/cve-2019-20907.patch \
 && patch -p 1 -i /root/patches/cve-2020-26116.patch \
 && patch -p 1 -i /root/patches/cve-2020-27619.patch \
 && patch -p 1 -i /root/patches/cve-2021-3177.patch \
 && patch -p 1 -i /root/patches/cve-2021-23336.patch \
 && patch -p 1 -i /root/patches/cve-2021-3733.patch \
 && patch -p 1 -i /root/patches/cve-2021-3737.patch \
 && patch -p 1 -i /root/patches/cve-2021-4189.patch \
 && patch -p 1 -i /root/patches/cve-2022-0391.patch \
 && patch -p 1 -i /root/patches/cve-2015-20107.patch \
 && patch -p 1 -i /root/patches/cve-2022-45061.patch \
 && patch -p 1 -i /root/patches/cve-2023-24329.patch \
 && ./configure \
    --enable-shared \
    --with-system-expat \
    --with-system-ffi \
    --enable-optimizations \
 && make \
# set thread stack size to 1MB so we don't segfault before we hit sys.getrecursionlimit()
# https://github.com/alpinelinux/aports/commit/2026e1259422d4e0cf92391ca2d3844356c649d0
        EXTRA_CFLAGS="-DTHREAD_STACK_SIZE=0x100000" \
# setting PROFILE_TASK makes "--enable-optimizations" reasonable: https://bugs.python.org/issue36044
# https://github.com/docker-library/python/issues/160#issuecomment-509426916
        PROFILE_TASK='-m test.regrtest --pgo \
            test_array \
            test_base64 \
            test_binascii \
            test_binhex \
            test_binop \
            test_bytes \
            test_c_locale_coercion \
            test_class \
            test_cmath \
            test_codecs \
            test_compile \
            test_complex \
            test_csv \
            test_decimal \
            test_dict \
            test_float \
            test_fstring \
            test_hashlib \
            test_io \
            test_iter \
            test_json \
            test_long \
            test_math \
            test_memoryview \
            test_pickle \
            test_re \
            test_set \
            test_slice \
            test_struct \
            test_threading \
            test_time \
            test_traceback \
            test_unicode \
        ' \
 && make install \
 && cd /root \
 && rm -rf /usr/local/src \
 && find /usr/local -depth \
    \( \
        \( -type d -a \( -name test -o -name tests -o -name idle_test \) \) \
        -o \( -type f -a \( -name '*.pyc' -o -name '*.pyo' -o -name 'libpython*.a' \) \) \
    \) -exec rm -rf '{}' +

ENV PYTHON_PIP_VERSION=20.3.4 \
    PYTHON_SETUPTOOLS_VERSION=44.1.1

RUN curl -OL -s https://raw.githubusercontent.com/pypa/get-pip/20.3.4/get-pip.py \
 && export PYTHONDONTWRITEBYTECODE=1 \
 && python get-pip.py --disable-pip-version-check --no-cache-dir --no-compile "pip==$PYTHON_PIP_VERSION" "setuptools==$PYTHON_SETUPTOOLS_VERSION" \
 && rm -f get-pip.py


FROM alpine:3.18

COPY --from=builder /usr/local /usr/local

RUN find /usr/local -type f -executable -not \( -name '*tkinter*' \) -exec scanelf --needed --nobanner --format '%n#p' '{}' ';' \
    | tr ',' '\n' \
    | sort -u \
    | awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
    | xargs -rt apk add

CMD ["python2.7"]
