FROM conda/miniconda3
LABEL authors="Francesco Lescai and Thomas Bleazard" \
      description="Docker image containing all software requirements for the nibscbioinformatics/viralevo pipeline"

# Install procps so that Nextflow can poll CPU usage
RUN apt-get update && apt-get install -y procps && apt-get clean -y

# Install the conda environment
COPY environment.yml /
RUN conda env create -f /environment.yml && conda clean -a

# For Bandage it needs separate installation of libGL.so.1
RUN apt-get install -y libgl1-mesa-glx && apt-get clean -y

# Add conda installation dir to PATH (instead of doing 'conda activate')
ENV PATH /usr/local/envs/nibscbioinformatics-viralevo-1.0dev/bin:$PATH

# install samtools separately because it introduces complexities with conda
RUN apt-get install -y wget
RUN apt-get install -y gcc \
make \
libbz2-dev \
zlib1g-dev \
libncurses5-dev \
libncursesw5-dev \
liblzma-dev
RUN wget https://github.com/samtools/samtools/releases/download/1.9/samtools-1.9.tar.bz2
RUN tar -vxjf samtools-1.9.tar.bz2
WORKDIR /samtools-1.9
RUN make
RUN make install
WORKDIR /

## also install BCFtools manually because of unresolvable dependencies
RUN wget https://github.com/samtools/bcftools/releases/download/1.9/bcftools-1.9.tar.bz2
RUN tar -vxjf bcftools-1.9.tar.bz2
WORKDIR bcftools-1.9
RUN make
RUN make install
WORKDIR /

# Dump the details of the installed packages to a file for posterity
RUN conda env export --name nibscbioinformatics-viralevo-1.0dev > nibscbioinformatics-viralevo-1.0dev.yml
