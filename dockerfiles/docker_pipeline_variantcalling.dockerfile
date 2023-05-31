FROM continuumio/miniconda3:4.12.0

### UPDATING CONDA ------------------------- ###

RUN conda update -y conda

### INSTALLING PIPELINE PACKAGES ----------- ###

# Adding bioconda to the list of channels
RUN conda config --add channels bioconda

# Adding conda-forge to the list of channels
RUN conda config --add channels conda-forge

# Installing mamba
RUN conda install -y mamba

# Installing packages
RUN mamba install -y \
    bcftools=1.17 \
    gatk4=4.3.0.0 \
    lofreq=2.1.5 \
    mummer=3.23 \
    samtools \
    tabix=1.11 && \
    conda clean -afty

RUN mamba install --force-reinstall -y java-jdk # Needed to fix "java: symbol lookup error: java: undefined symbol: JLI_StringDup" error

### SETTING WORKING ENVIRONMENT ------------ ###

# Set workdir to /home/
WORKDIR /home/

# Launch bash automatically
CMD ["/bin/bash"]
