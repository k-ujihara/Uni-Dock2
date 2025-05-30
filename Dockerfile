# FROM nvidia/cuda:12.8.0-cudnn-devel-ubuntu24.04 AS base
FROM nvidia/cuda:12.8.1-cudnn-devel-ubuntu22.04 AS base

ENV LANG=C.UTF-8 LC_ALL=C.UTF-8
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update -q \
    && \
    apt-get upgrade -y

RUN apt-get update -q \
    && \
    apt-get install -q -y --no-install-recommends \
        bzip2 \
        curl \
        git \
        procps \
        unzip \
        wget \
    && \
    apt-get clean \
    && \
    rm -rf /var/lib/apt/lists/*

ARG CONDA_VERSION=py310_25.1.1-2
RUN UNAME_M="$(uname -m)" && \
    MINICONDA_URL="https://repo.anaconda.com/miniconda/Miniconda3-${CONDA_VERSION}-Linux-x86_64.sh" && \
    wget "${MINICONDA_URL}" -O miniconda.sh -q && \
    mkdir -p /opt && \
    bash miniconda.sh -b -p /opt/conda && \
    rm miniconda.sh && \
    ln -s /opt/conda/etc/profile.d/conda.sh /etc/profile.d/conda.sh && \
    echo ". /opt/conda/etc/profile.d/conda.sh" >> ~/.bashrc && \
    echo "conda activate base" >> ~/.bashrc && \
    find /opt/conda/ -follow -type f -name '*.a' -delete && \
    find /opt/conda/ -follow -type f -name '*.js.map' -delete && \
    /opt/conda/bin/conda clean -afy && \
    echo -e "channels:\n  - conda-forge\n" > /opt/conda/.condarc
ENV PATH=/opt/conda/bin:$PATH

RUN pip install numpy==1.26.4

FROM base AS build_msys

RUN pip install \
        pybind11==2.13.6 \
        SCons==4.9.1

ARG MSYS_COMMIT_ID=93edd955dc550b4267b3601283d7f2619be2d548
RUN mkdir -p /tmp \
    && \
    cd /tmp \
    && \
    wget https://github.com/DEShawResearch/msys/archive/$MSYS_COMMIT_ID.zip -O msys.zip \
    && \
    unzip msys.zip \
    && \
    rm -f msys.zip \
    && \
    mv /tmp/msys-$MSYS_COMMIT_ID /tmp/msys

RUN cd /tmp/msys/external/lpsolve \
    && \
    wget https://sourceforge.net/projects/lpsolve/files/lpsolve/5.5.2.5/lp_solve_5.5.2.5_source.tar.gz \
    && \
    tar xzf lp_solve_5.5.2.5_source.tar.gz \
    && \
    rm -f lp_solve_5.5.2.5_source.tar.gz

RUN cd /tmp/msys/external/inchi \
    && \
    wget https://github.com/IUPAC-InChI/InChI/releases/download/v1.05/INCHI-1-SRC.zip \
    && \
    unzip INCHI-1-SRC.zip \
    && \
    rm -f INCHI-1-SRC.zip

COPY msys.patch /tmp/msys.patch
RUN cd /tmp/msys \
    && \
    patch -p1 < /tmp/msys.patch \
    && \
    rm /tmp/msys.patch

RUN cp -r $(python -c "import pybind11; print(pybind11.get_include())")/pybind11 \
    $(python -c "import sysconfig; print(sysconfig.get_config_vars()['INCLUDEPY'])")/

RUN apt-get update -q \
    && \
    apt-get install -q -y --no-install-recommends \
        libboost-all-dev \
        libsqlite3-dev \
        zlib1g-dev \
    && \
    apt-get clean \
    && \
    rm -rf /var/lib/apt/lists/*

RUN cd /tmp/msys \
    && \
    PYTHONPATH=external scons \
        -j`nproc` \
        PYTHONVER=310 \
        -D MSYS_WITH_INCHI=1 \
        -D MSYS_WITH_LPSOLVE=1

RUN mkdir -p /opt/msys \
    && \
    mv /tmp/msys/build/bin /opt/msys/bin \
    && \
    mv /tmp/msys/build/lib /opt/msys/lib \
    && \
    rm -rf /tmp/msys

FROM build_msys AS unidock2

RUN conda install conda-forge::ambertools=22.5

RUN apt-get update -q \
    && \
    apt-get install -q -y --no-install-recommends \
        libboost-all-dev \
        cmake \
        swig \
    && \
    apt-get clean \
    && \
    rm -rf /var/lib/apt/lists/*

# OpenBabel
ARG OPENBABEL_COMMIT_ID=889c350feb179b43aa43985799910149d4eaa2bc
COPY openbabel.patch /tmp/openbabel.patch
RUN cd /tmp \
    && \
    wget "https://github.com/openbabel/openbabel/archive/${OPENBABEL_COMMIT_ID}.zip" -O openbabel.zip \
    && \
    unzip openbabel.zip \
    && \
    rm openbabel.zip \
    && \
    cd openbabel-${OPENBABEL_COMMIT_ID} \
    && \
    patch -p1 < /tmp/openbabel.patch \
    && \
    rm -f /tmp/openbabel.patch \
    && \
    mkdir -p build \
    && \
    cd build \
    && \
    cmake -DWITH_MAEPARSER=OFF -DWITH_COORDGEN=OFF -DPYTHON_BINDINGS=ON -DRUN_SWIG=ON .. \
    && \
    make -j`nproc` \
    && \
    make install \
    && \
    cd /tmp \
    && \
    rm -rf openbabel-${OPENBABEL_COMMIT_ID}

RUN pip install \
        openmm==8.2.0 \
    && \
    cd /tmp \
    && \
    wget https://github.com/openmm/pdbfixer/archive/refs/tags/v1.11.zip \
    && \
    unzip v1.11.zip \
    && \
    cd pdbfixer-1.11 \
    && \
    python -m pip install . \
    && \
    cd /tmp \
    && \
    rm -f v1.11.zip \
    && \
    rm -rf pdbfixer-1.11

RUN pip install \
    MDAnalysis==2.9.0 \
    networkx==3.4.2 \
    pathos==0.3.4 \
    PyYAML==6.0.2 \
    rdkit==2024.9.6

COPY --from=build_msys /opt/msys/bin /usr/local/bin
COPY --from=build_msys /opt/msys/lib /usr/local/lib
ENV LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH
RUN mv /usr/local/lib/python/msys $(python -c "from distutils import sysconfig; print(sysconfig.get_python_lib(1,0))")/
    
ARG UNIDOCK2_COMMIT_ID=047ed37c65d01d359109bae4eab060931924e1cc
RUN cd /tmp \
    && \
    git clone https://github.com/dptech-corp/Uni-Dock2 \
    && \
    cd Uni-Dock2 \
    && \
    git checkout $UNIDOCK2_COMMIT_ID \
    && \
    cd unidock/unidock_engine \
    && \
    pip install . \
    && \
    cd ../.. \
    && \
    pip install .

WORKDIR /workspace
