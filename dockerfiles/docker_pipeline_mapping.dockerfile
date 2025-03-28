FROM continuumio/miniconda3:25.1.1-2

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
    bowtie2=2.5.4 \
    bwa=0.7.18 \
    gatk4=4.6.1.0 \
    picard=3.3.0 \
    sambamba=1.0.1 \
    samtools && \
    conda clean -afty

#RUN mamba install --force-reinstall -y java-jdk # Needed to fix "java: symbol lookup error: java: undefined symbol: JLI_StringDup" error

### SETTING WORKING ENVIRONMENT ------------ ###

# Set workdir to /home/
WORKDIR /home/

# Launch bash automatically
CMD ["/bin/bash"]
