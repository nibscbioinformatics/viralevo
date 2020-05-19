FROM conda/miniconda3
LABEL authors="Francesco Lescai and Thomas Bleazard" \
      description="Docker image containing all software requirements for the nibscbioinformatics/viralevo pipeline"



# Install the conda environment
COPY environment.yml /
RUN conda env create -f /environment.yml && conda clean -a

# Add conda installation dir to PATH (instead of doing 'conda activate')
ENV PATH /opt/conda/envs/nibscbioinformatics-viralevo-1.0dev/bin:$PATH

# Dump the details of the installed packages to a file for posterity
RUN conda env export --name nibscbioinformatics-viralevo-1.0dev > nibscbioinformatics-viralevo-1.0dev.yml
