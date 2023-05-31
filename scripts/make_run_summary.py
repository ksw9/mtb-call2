#!/usr/bin/env python3

"""
This script parses the reports generated by TrimGalore, Kraken2, BWA/Bowtie2, and TbProfiler and generates a single coherent report
"""

### ---------------------------------------- ###

def parseTrimGaloreReport(report_name):
    
    report = open(report_name).read().split('\n')
    
    raw_reads = [int(line.split(' ')[-1].replace(',', '')) for line in report if 'Total reads processed:' in line][0]
    reads_with_adapters = [int(line.split(' ')[-2].replace(',', '')) for line in report if 'Reads with adapters:' in line][0]
    trimmed_reads = [int(line.split(' ')[-2].replace(',', '')) for line in report if 'Reads written (passing filters):' in line][0]
    
    return raw_reads, reads_with_adapters, trimmed_reads

### ---------------------------------------- ###

def parseKraken2Report(report_name):
    
    report = open(report_name).read().split('\n')
    
    kraken_tb_reads = [int(line.split('\t')[1].replace(',', '')) for line in report if 'Mycobacterium tuberculosis complex' in line][0]
    
    return kraken_tb_reads

### ---------------------------------------- ###

def parseMappingReport(report_name):
    

    report = open(report_name).read().split('\n')
  
    report = open(report_name).read().split('\n')

    mapping_percentage = [float(line.split(' ')[-1][1:-1].split('%')[0]) for line in report if 'properly paired' in line][0]
    
    return mapping_percentage

### ---------------------------------------- ###

def parseDuplicationReport(report_name):
    
    _, header, dup_data = [block for block in open(report_name).read().split('\n\n') if '## METRICS CLASS\tpicard.sam.DuplicationMetrics' in block][0].split('\n')
    
    percent_duplication = float(dup_data.split('\t')[header.split('\t').index('PERCENT_DUPLICATION')])
    
    return percent_duplication

### ---------------------------------------- ###

def parseCoverageReport(report_name):
    
    _, metrics_header, metrics = [block for block in open(report_name).read().split('\n\n') if '## METRICS' in block][0].split('\n')
    histogram = [block for block in open(report_name).read().split('\n\n') if '## HISTOGRAM' in block][0].split('\n')[1:]
    histogram = [[int(n) for n in line.split('\t')] for line in histogram[1:]]
    
    mean_coverage, median_coverage, sd_coverage = [float(metrics.split('\t')[metrics_header.split('\t').index(h)]) for h in ['MEAN_COVERAGE', 'MEDIAN_COVERAGE', 'SD_COVERAGE']]
    
    sum_cov = sum([h[1] for h in histogram])
    
    cov_5 = 100 * [h[1] for h in histogram if h[0] == 5][0] / sum_cov
    cov_10 = 100 * [h[1] for h in histogram if h[0] == 10][0] / sum_cov
    cov_100_plus = 100 * sum([h[1] for h in histogram if h[0] >= 100]) / sum_cov
    
    return mean_coverage, median_coverage, sd_coverage, cov_5, cov_10, cov_100_plus

### ---------------------------------------- ###

def parseResistanceReport(report_name):
    
    summary_section = [block for block in open(report_name).read().split('\n\n') if 'Summary\n---' in block][0].split('\n')
    #resistance_report = [block for block in open(report_name).read().split('\n\n') if 'Resistance report\n---' in block][0].split('\n')[3:]
    
    strain, drug_resistance = [line.split(',')[1] for line in summary_section for field in ['Strain', 'Drug-resistance'] if field in line]
    strain = strain if strain != '' else 'NA'
    
    return strain, drug_resistance

### ------------------MAIN------------------ ###

from datetime import datetime
from sys import argv

### PARSE DATA ----------------------------- ###

# Import reads/sample list file name
reads_list_file = argv[argv.index("--reads_list_file") + 1]

# Import reads/sample list
reads_list = open(reads_list_file).read().split('\n')
reads_list_header, reads_list = reads_list[0].split('\t'), reads_list[1:]

# Init summary report
summary_header = ["Sample",
                  "Batch",
                  "Raw_Reads",
                  "Raw_Reads_With_Adapters",
                  "Trimmed_Raw_Reads",
                  "Kraken2_Raw_Reads",
                  "Mapping_Percentage",
                  "Duplication_Percentage",
                  "Coverage_Mean",
                  "Coverage_Median",
                  "Coverage_SD",
                  "Coverage_5_Percentage",
                  "Coverage_10_Percentage",
                  "Coverage_100+_Percentage",
                  "Strain",
                  "Drug_Resistance"]
summary = {h : [] for h in summary_header}

# Parse data for each sample specified in reads_list
for index, row in enumerate(reads_list):

    if not len(row):

        continue
    
    # Extract basic info
    sample, batch, fastq_1 = [row.split('\t')[reads_list_header.index(element)] for element in ['sample', 'batch', 'fastq_1']]
    summary['Sample'].append(sample)
    summary['Batch'].append(batch)
    
    # Parse R1 TrimGalore report
    raw_reads, reads_with_adapters, trimmed_reads = parseTrimGaloreReport(f'{fastq_1.split("/")[-1]}_trimming_report.txt')
    summary['Raw_Reads'].append(raw_reads)
    summary['Raw_Reads_With_Adapters'].append(reads_with_adapters)
    summary['Trimmed_Raw_Reads'].append(trimmed_reads)
    
    # Parse info from Kraken2 report
    raw_reads = parseKraken2Report(f'{sample}_kraken.report')
    summary['Kraken2_Raw_Reads'].append(raw_reads)
    
    # Parse mapping info
    percentage_mapped_reads = parseMappingReport(f'{sample}_mapping.log')
    summary['Mapping_Percentage'].append(percentage_mapped_reads)
    
    # Parse duplication info
    duplication_percentage = parseDuplicationReport(f'{sample}_marked_dup_metrics.txt')
    summary['Duplication_Percentage'].append(duplication_percentage)
    
    # Parse coverage info
    mean, median, sd, cov_5, cov_10, cov_100_plus = parseCoverageReport(f'{sample}_coverage_stats.txt')
    summary['Coverage_Mean'].append(mean)
    summary['Coverage_Median'].append(median)
    summary['Coverage_SD'].append(sd)
    summary['Coverage_5_Percentage'].append(cov_5)
    summary['Coverage_10_Percentage'].append(cov_10)
    summary['Coverage_100+_Percentage'].append(cov_100_plus)

    # Parse Tb-Profiler report
    strain, drug_resistance = parseResistanceReport(f'{sample}_lineageSpo_gatk.csv')
    summary['Strain'].append(strain)
    summary['Drug_Resistance'].append(drug_resistance)

### EXPORT DATA ---------------------------- ###

# Formatting text
summary_text = '\n'.join(['\t'.join(summary_header)] +
                         ['\t'.join([str(summary[h][i]) for h in summary_header]) for i in range(len(summary['Sample']))])

# Saving to tsv
with open(f'pipeline_run_summary_{str(datetime.now()).replace(" ", "_").replace(":", "-")}.tsv', 'w') as summary_out:
    summary_out.write(summary_text)
