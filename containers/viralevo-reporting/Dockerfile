FROM conda/miniconda3
LABEL authors="Francesco Lescai and Thomas Bleazard" \
      description="Docker image containing all software requirements for the nibscbioinformatics/viralevo pipeline"

# Install procps so that Nextflow can poll CPU usage
RUN apt-get update && apt-get install -y procps wget && apt-get clean -y

## Fix locales problem
RUN apt-get install -y locales
RUN locale-gen --purge "en_GB.UTF-8"
RUN dpkg-reconfigure --frontend noninteractive locales

# Install the conda environment
COPY environment.yml /
RUN conda env create -f /environment.yml && conda clean -a

# Add conda installation dir to PATH (instead of doing 'conda activate')
ENV PATH /usr/local/envs/viralevo-reporting/bin:$PATH
