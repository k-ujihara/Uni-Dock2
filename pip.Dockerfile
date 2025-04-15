FROM nvidia/cuda:11.8.0-cudnn8-devel-ubuntu22.04 AS unidock2

ENV LANG=C.UTF-8 LC_ALL=C.UTF-8
ENV DEBIAN_FRONTEND=noninteractive 

RUN apt-get update -q && \
    apt-get install -q -y --no-install-recommends \
        build-essential \
        bzip2 \
        ca-certificates \
        cmake \
        curl \
        git \
        libboost-all-dev \
        libeigen3-dev \
        libglib2.0-0 \
        libsm6 \
        libxext6 \
        libxrender1 \
        libxml2-dev \
        mercurial \
        openssh-client \
        procps \
        sqlite3 \
        subversion \
        swig \
        unzip \
        wget \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

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
    /opt/conda/bin/conda clean -afy

ENV PATH=/opt/conda/bin:$PATH

RUN conda install mamba -c conda-forge

# OpenBabel
ARG OPENBABEL_COMMIT_ID=10da8d7b8916e5301298c7eba3a162ebba7d7de3
RUN PYTHONHOME=/opt/conda/bin/python3.10 \
    && \
    cd /tmp \
    && \
    wget "https://github.com/openbabel/openbabel/archive/${OPENBABEL_COMMIT_ID}.zip" -O openbabel.zip \
    && \
    unzip openbabel.zip \
    && \
    mv "openbabel-${OPENBABEL_COMMIT_ID}" /opt/openbabel && \
    rm /tmp/openbabel.zip && \
    rm -rf "openbabel-$OPENBABEL_COMMIT_ID" && \
    cd /opt/openbabel && \
    mkdir -p build && \
    cd build && \
    cmake -DWITH_MAEPARSER=OFF -DWITH_COORDGEN=OFF -DPYTHON_BINDINGS=ON -DRUN_SWIG=ON ..  && \
    make -j`nproc` && \
    make install && \
    rm -r /opt/openbabel

# RUN pip install \
#     ipycytoscape==1.3.3 \
#     ipykernel==6.29.5 \
#     ipython==8.30.0 \
#     ipywidgets==8.1.5 \
#     jinja2==3.1.6 \
#     numba==0.61.0 \
#     numpy==1.26.4 \
#     pandas==2.2.3 \
#     pathos==0.3.0 \
#     rdkit==2024.9.6 \
#     requests==2.32.3 \
#     scipy==1.15.2 \
#     typing-extensions==4.13.0 \
#     PyYAML==6.0.2 \
#     tqdm

# RUN pip install \
#     biopython==1.85 \
#     gsd==3.4.2 \
#     MDAnalysis==2.9.0 \
#     OpenMM==8.2.0 \
#     ParmEd==4.3.0 \
#     tidynamics==1.1.2

# RUN pip install \
#     blosc \
#     filelock \
#     greenlet \
#     h5py \
#     joblib \
#     munkres \
#     netCDF4 \
#     networkx \
#     patsy \
#     pytng \
#     reportlab \
#     scikit-learn \
#     seaborn

# RUN cd /tmp \
#     && \
#     wget https://github.com/openmm/pdbfixer/archive/refs/tags/v1.11.zip \
#     && \
#     unzip v1.11.zip \
#     && \
#     cd pdbfixer-1.11 \
#     && \
#     pip install . \
#     && \
#     cd /tmp \
#     && \
#     rm -rf pdbfixer-1.11 \
#     && \
#     rm v1.11.zip

# RUN conda install -y -c conda-forge \
#     ambertools==24.8

# RUN conda install -y msys_viparr_lpsolve55 -c conda-forge -c http://quetz.dp.tech:8088/get/baymax --no-repodata-use-zst

# RUN conda install -y -c conda-forge cmake=3.31

# ARG UNIDOCK2_COMMIT_ID=e098d70eb00509399a850e3682915fe6ca3963a0
# RUN cd /tmp \
#     && \
#     wget https://github.com/dptech-corp/Uni-Dock2/archive/$UNIDOCK2_COMMIT_ID.zip -O Uni-Dock2.zip \
#     && \
#     unzip Uni-Dock2.zip

# RUN cd /tmp \
#     && \
#     cd Uni-Dock2-$UNIDOCK2_COMMIT_ID \
#     && \
#     cd unidock/unidock_engine \
#     && \
#     mkdir build \
#     && \
#     cd build \
#     && \
#     cmake ../ud2 -DCMAKE_BUILD_TYPE=Release \
#     && \
#     make ud2 -j

# RUN 
#     python setup.py install
