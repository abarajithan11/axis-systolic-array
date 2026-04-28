FROM openroad/orfs:latest

ARG DEBIAN_FRONTEND=noninteractive  

USER root

# Base tools + RISC-V + Verilator deps + GUI waveform tools
RUN apt-get update && apt-get install -y \
    build-essential \
    git curl wget \
    python3 python3-pip python-is-python3 \
    libelf-dev srecord \
    autoconf automake autotools-dev \
    libmpc-dev libmpfr-dev libgmp-dev \
    gawk bison flex texinfo patchutils libexpat1-dev \
    libfl2 libfl-dev \
    help2man perl \
    liblzma-dev libunwind-dev libgoogle-perftools-dev numactl \
    gcc-riscv64-unknown-elf \
    ccache \
    vim \
    x11-apps \
    gtkwave \
    klayout \
    && rm -rf /var/lib/apt/lists/*

ENV PATH="/OpenROAD-flow-scripts/tools/install/yosys/bin:/OpenROAD-flow-scripts/tools/install/OpenROAD/bin:${PATH}"

# Python deps (project + riscv-dv)
COPY ibex-soc/python-requirements.txt /tmp/python-requirements.txt
COPY ibex-soc/vendor/google_riscv-dv/requirements.txt /tmp/vendor/google_riscv-dv/requirements.txt

RUN python3 -m pip install --no-cache-dir \
        -r /tmp/python-requirements.txt \
        -r /tmp/vendor/google_riscv-dv/requirements.txt \
    && rm -rf /tmp/python-requirements.txt /tmp/vendor

RUN python3 -m pip install --no-cache-dir numpy

# Provide riscv32 aliases pointing at riscv64-unknown-elf toolchain
RUN for t in g++ gcc ld objcopy objdump; do \
      ln -sf "$(command -v riscv64-unknown-elf-$t)" "/usr/local/bin/riscv32-unknown-elf-$t"; \
    done

# Verilator
ARG VERILATOR_VERSION=v5.042
RUN git clone https://github.com/verilator/verilator.git \
    && cd verilator && git checkout "${VERILATOR_VERSION}" \
    && autoconf && ./configure \
    && make -j"$(nproc)" && make install \
    && cd .. && rm -rf verilator

# Non-root user
ARG USERNAME=usr
ARG UID=1000
ARG GID=1000

RUN groupadd -g "${GID}" "${USERNAME}" \
    && useradd -m -u "${UID}" -g "${GID}" "${USERNAME}"

USER ${USERNAME}
WORKDIR /repo

# Simple colored prompt with user@host
RUN echo 'export PS1="\[\e[0;33m\][\u@\h \W]\$ \[\e[m\] "' >> /home/${USERNAME}/.bashrc
