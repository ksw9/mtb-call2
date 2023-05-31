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
# N.B. have to add weasyprint and specify tb-profiler=4.4.2 or the version automatically installed is 2.8
RUN mamba install -y \
    bbmap=39.01 \
    kraken2=2.1.2 \
    seqtk=1.4 && \
    conda clean -afty

### FIX KRAKEN2-BUILD ---------------------- ###

# Fixes the "rsync_from_ncbi.pl: unexpected FTP path (new server?)" error
# Thanks to Bent Petersen, PhD (https://www.bpetersen.dk/post/kraken2-rsync_from_ncbi-pl-unexpected-ftp-path-new-server-for)
#RUN mv /opt/conda/libexec/rsync_from_ncbi.pl /opt/conda/libexec/rsync_from_ncbi.pl.bak && \
#    sed '46 s/ftp/https/' /opt/conda/libexec/rsync_from_ncbi.pl.bak > /opt/conda/libexec/rsync_from_ncbi.pl && \
#    chmod 775 /opt/conda/libexec/rsync_from_ncbi.pl

### SETTING WORKING ENVIRONMENT ------------ ###

# Set workdir to /home/
WORKDIR /home/

# Launch bash automatically
CMD ["/bin/bash"]
