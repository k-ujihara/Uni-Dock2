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

ARG UNIDOCK2_COMMIT_ID=e098d70eb00509399a850e3682915fe6ca3963a0
RUN cd /tmp \
    && \
    wget https://github.com/dptech-corp/Uni-Dock2/archive/$UNIDOCK2_COMMIT_ID.zip -O Uni-Dock2.zip \
    && \
    unzip Uni-Dock2.zip

RUN conda install mamba -c conda-forge

RUN mamba install -y ipython ipykernel ipywidgets requests numba pathos tqdm jinja2 numpy pandas scipy
RUN mamba install -y -c conda-forge rdkit openmm mdanalysis openbabel pyyaml networkx ipycytoscape pdbfixer
RUN mamba install -y -c nvidia/label/cuda-11.8.0 cuda
RUN conda install -y msys_viparr_lpsolve55 ambertools_stable -c conda-forge -c http://quetz.dp.tech:8088/get/baymax --no-repodata-use-zst

RUN mamba install -y cmake=3.31
RUN conda install -y -c conda-forge openbabel 
RUN pip install rdkit openmm mdanalysis 

RUN cd /tmp/Uni-Dock2-$UNIDOCK2_COMMIT_ID/unidock/unidock_engine \
    && \
    mkdir build \
    && \
    cd build \
    && \
    cmake ../ud2 -DCMAKE_BUILD_TYPE=Release \
    && \
    make ud2 -j \
    && \
    cd ../../.. \
    && \
    python setup.py install

RUN mamba install -y msys_viparr_lpsolve55 ambertools_stable -c conda-forge -c http://quetz.dp.tech:8088/get/baymax

# RUN cd /tmp \
#     && \
#     cd Uni-Dock2-$UNIDOCK2_COMMIT_ID \
#     && \
#     bash install.sh

# SHELL ["/bin/bash", "--login", "-c"]
# RUN echo "conda activate ud2pub" >> ~/.bashrc
# ENV PATH=/opt/conda/envs/ud2pub/bin:$PATH
    
WORKDIR /workspace
