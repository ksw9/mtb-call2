#!/usr/bin/env python3

"""
This script parses a single-sample unzipped vcf file and filters it.
N.B. Filter expression indicates variants that ARE desired (e.g. TYPE==indel => indels are kept, whereas TYPE!=indel => indels are removed)

FILTER DESCRIPTION
------------------

Individual filters are separated by ||
e.g. QD > 2.0 && FS < 60.0 || DP > 10 equals 2 filters, QD > 2.0 && FS < 60.0 and DP > 10

Each filter can be composed of multiple conditions, separated by &&
e.g. QD > 2.0 && FS < 60.0 indicates two separate conditions, QD > 2.0 and FS < 60.0

Parameters that can be filtered for are:
- Individual columns of the vcf: '#CHROM', 'POS', 'ID', 'REF', 'ALT', 'QUAL', 'FILTER'
- Data from the 'INFO' or 'FORMAT' columns: GT, AD, DP, GQ, etc.

Variants can also be filtered by type:
e.g. TYPE == "SNP" will only keep SNPs and remove insertions and indels

If --remove_extreme_depth or --remove_extreme_qual are set in the command line arguments, then variants with depth or quality above/below 2 standard deviations from mean depth/quality are removed

Example of filter string:    
QD > 2.0 && QUAL > 20 && DP > 10 || TYPE == "SNP"

This will generate two filters:
1) Filter for QD, QUAL, and DP values
2) Only keep SNPs

If --pass_with_one_filter is set in the command line arguments, then variants that satisfy at least one filtering condition are kept.
Otherwise, all filters have to be satisfied.

e.g. A variant has depth 10 and quality 20. If the filter string is 'DP > 100 || QUAL > 10', then two filters are generated:
1) Filter for DP (variant fails)
2) Filter for QUAL (variant passes)
With the --pass_with_one_filter option, the variant will pass.
Without the --pass_with_one_filter option, the variant will be removed.
"""

### ---------------------------------------- ###

def parse_args():

    print(f'args = {argv}')
    
    # Filter string
    if '--vcf_filter' in argv:

        vcf_filter_raw = argv[argv.index("--vcf_filter") + 1]

    else:

        vcf_filter_raw = 'QUAL > 0'
    
    # path to unzipped vcf file
    vcf_file = argv[argv.index("--vcf_file") + 1]
    
    # Whether to remove variants with depth > (mean - 2 * std) or depth < (mean + 2 * std)
    # Usually, these are variants in repetitive regions, so this filter should only be used if fasta is unmasked
    if '--remove_extreme_depth' in argv:
        
        depth_filter_toggle = True
    
    else:
        
        depth_filter_toggle = False
    
    # Whether to remove variants with quality > (mean - 2 * std) or depth < (mean + 2 * std)
    # Usually, these are variants in repetitive regions, so this filter should only be used if fasta is unmasked
    if '--remove_extreme_qual' in argv:
        
        qual_filter_toggle = True
    
    else:
        
        qual_filter_toggle = False
    
    # Whether to pass variants that fit all filters or at least one
    if '--pass_with_one_filter' in argv:
        
        use_all_filters = False
    
    else:
        
        use_all_filters = True

    return vcf_filter_raw, vcf_file, depth_filter_toggle, qual_filter_toggle, use_all_filters

### ---------------------------------------- ###

def parse_vcf_filter(filter_string):
    
    # Parsing multi-parameters filter string e.g. 'QD > 2.0 && FS < 60.0 && MQ > 40.0 && DP > 10 && QUAL > 20 && QUAL != "." && RGQ > 20'
    # String is first broken in || blocks which indicate separate filters (e.g. QD > 2.0 && FS < 60.0 || DP > 10 equals 2 filters, QD > 2.0 && FS < 60.0 and DP > 10)
    # Filter blocks are further broken in '&&' blocks, then the terms are parsed and stored into individual subfilters.
    
    filter_string = filter_string.replace(' ', '').split('||')
    
    parsed_filters = []
    
    for fs_block in filter_string:
        
        new_filter = {field : [] for field in ['parameter', 'operator', 'value']}
        
        fs_block = fs_block.replace('(', '').replace(')', '').split('&&')
        
        for fs in fs_block:
            
            operator = [op for op in ['==', '!=', '<=', '<', '>=', '>'] if op in fs][0]
            
            parameter, value = fs.split(operator)
            
            try:
                
                value = float(value)
            
            except:
                
                value = value.replace('"', '')
        
            new_filter['parameter'].append(parameter)
            new_filter['operator'].append(operator)
            new_filter['value'].append(value)
        
        parsed_filters.append(new_filter)
    
    return parsed_filters

### ---------------------------------------- ###

def parse_vcf(path):
    
    header, data = [], []
    
    with open(path, 'r') as raw_input:
        
        for line in raw_input:
        
            line = line.replace('\n', '')
            
            if line.startswith('##'):
                    
                header.append(line)
            
            elif line.startswith('#CHROM'):
                
                columns = line.split('\t')
                
            elif len(line):
                
                data.append(line.split('\t'))
            
            else:
                
                pass
        
    return header, columns, data

### ---------------------------------------- ###

def depth_outlier_filter(cols, data, toggle):
    
    if toggle and len(data) >= 10:

        # Get depth mean and std
        info_col = cols.index('INFO')
        depth = [[int(d.replace('DP=', '')) for d in dat[info_col].split(';') if d.startswith('DP=')][0] for dat in data]
        depth_mean = sum(depth) / len(depth)
        depth_std = (sum([(val - depth_mean)**2 for val in depth]) / (len(depth) - 1))**0.5
        
        var_filter = [(d > (depth_mean - 2 * depth_std)) & (d < (depth_mean + 2 * depth_std)) for d in depth]

    else:
        
        var_filter = [True for _ in range(len(data))]
    
    return var_filter

### ---------------------------------------- ###

def qual_outlier_filter(cols, data, toggle):
    
    if toggle and len(data) >= 10:

        # Get depth mean and std
        qual_col = cols.index('QUAL')
        qual = [float(dat[qual_col]) for dat in data]
        qual_mean = sum(qual) / len(qual)
        qual_std = (sum([(val - qual_mean)**2 for val in qual]) / (len(qual) - 1))**0.5
        
        var_filter = [(q > (qual_mean - 2 * qual_std)) & (q < (qual_mean + 2 * qual_std)) for q in qual]

    else:
        
        var_filter = [True for _ in range(len(data))]
    
    return var_filter

### ---------------------------------------- ###

def filter_vars(cols, data, vf):
    
    parameters, operators, values = vf['parameter'], vf['operator'], vf['value']
    
    var_filter = []
    
    for p,o,v in zip(parameters, operators, values):
    
        if p in cols:
            
            col_index = cols.index(p)
            
            try:
                
                vars_vals = [float(d[col_index]) for d in data]
            
            except:
                
                vars_vals = [d[col_index] for d in data]
            
            p_filter = [(vv == v) if o == '=='
                        else (vv != v) if o == '!='
                        else (vv <= v) if o == '<='
                        else (vv < v) if o == '<'
                        else (vv >= v) if o == '>='
                        else (vv > v) if o == '>'
                        else True
                        for vv in vars_vals]
            
            var_filter.append(p_filter)
        
        elif f'{p}=' in data[0][cols.index('INFO')]:
            
            col_index = cols.index('INFO')
            subcol_indexes = [[n for n,i in enumerate(d[col_index].split(';')) if i.startswith(f'{p}=')][0] if f'{p}=' in d[col_index]
                              else -1
                              for d in data]
            
            vars_vals = [float(d[col_index].split(';')[subcol].replace(f'{p}=', '')) if subcol != -1
                         else -1
                         for d,subcol in zip(data, subcol_indexes)]
            
            p_filter = [False if vv == -1
                        else (vv == v) if o == '=='
                        else (vv != v) if o == '!='
                        else (vv <= v) if o == '<='
                        else (vv < v) if o == '<'
                        else (vv >= v) if o == '>='
                        else (vv > v) if o == '>'
                        else True
                        for vv in vars_vals]
            
            var_filter.append(p_filter)
        
        elif p in data[0][cols.index('FORMAT')].split(':'):
            
            col_index = -1
            subcol_indexes = [[n for n,i in enumerate(d[cols.index('FORMAT')].split(':')) if i == p][0] if p in d[cols.index('FORMAT')].split(':')
                              else -1
                              for d in data]
            
            try:
                
                vars_vals = [float(d[col_index].split(':')[subcol]) if subcol != -1
                             else -1
                             for d,subcol in zip(data, subcol_indexes)]
                
            except:
                
                vars_vals = [float(d[col_index].split(':')[subcol].split(',')[-1]) if subcol != -1
                             else -1
                             for d,subcol in zip(data, subcol_indexes)]
            
            p_filter = [False if vv == -1
                        else (vv == v) if o == '=='
                        else (vv != v) if o == '!='
                        else (vv <= v) if o == '<='
                        else (vv < v) if o == '<'
                        else (vv >= v) if o == '>='
                        else (vv > v) if o == '>'
                        else True
                        for vv in vars_vals]
            
            var_filter.append(p_filter)
        
        elif p == 'TYPE':
            
            ref_col, alt_col = cols.index('REF'), cols.index('ALT')
            
            vars_type = ['SNP' if ((len(d[ref_col]) == len(d[alt_col])) and (len(d[ref_col]) == 1))
                         else 'indel' if (len(d[ref_col]) > len(d[alt_col]))
                         else 'insert' if (len(d[ref_col]) < len(d[alt_col]))
                         else 'NA'
                         for d in data]
            
            p_filter = [(vt == v) if o == '=='
                        else (vt != v)
                        for vt in vars_type]
            
            var_filter.append(p_filter)
        
        else:
        
            var_filter.append([True for _ in range(len(data))])
        
    # Merge individual filters
    if len(var_filter) == 1:
        
        var_filter = var_filter[0]
    
    else:
        
        var_filter = [sum([v[i] for v in var_filter]) == len(parameters) for i in range(len(data))]
    
    return var_filter

### ------------------MAIN------------------ ###

from sys import argv

### IMPORT DATA ----------------------------- ###

# Parse cli
vcf_filter_raw, vcf_file, depth_filter_toggle, qual_filter_toggle, use_all_filters = parse_args()

# Parse filter
vcf_filter = parse_vcf_filter(vcf_filter_raw)

# Load vcf file
vcf_header, vcf_columns, vcf_data = parse_vcf(vcf_file)

### Filter variants

if len(vcf_data):

    # Init list of filtered values
    all_filters = []

    # Extreme depth filter
    depth_filter = depth_outlier_filter(vcf_columns, vcf_data, depth_filter_toggle)
    all_filters.append(depth_filter)

    # Extreme quality filter
    qual_filter = depth_outlier_filter(vcf_columns, vcf_data, qual_filter_toggle)
    all_filters.append(qual_filter)

    # Process individual filters
    for vcf_f in vcf_filter:
        
        new_filter = filter_vars(vcf_columns, vcf_data, vcf_f)
        
        all_filters.append(new_filter)

    # Merge individual filters
    if len(all_filters) == 1:
        
        final_filter = all_filters[0]

    elif use_all_filters:
        
        final_filter = [sum([v[i] for v in all_filters]) == len(all_filters) for i in range(len(vcf_data))]
    
    else:
        
        final_filter = [sum([v[i] for v in all_filters]) > 0 for i in range(len(vcf_data))]

    # Filter vcf data
    vcf_data_filtered = ['\t'.join(v) for v,f in zip(vcf_data, final_filter) if f]

    discarded_n = len(vcf_data) - len(vcf_data_filtered)
    discarded_percent = round(100 * discarded_n / len(vcf_data), 3)
    print(f'Discarded {discarded_n} / {len(vcf_data)} variants ({discarded_percent}%)')

else:

    vcf_data_filtered = []

### Write to file

output_name = vcf_file.split('/')[-1].replace('.vcf', '_filtered.vcf')

with open(output_name, 'w') as output:
    
    output.write('\n'.join(vcf_header + ['\t'.join(vcf_columns)] + vcf_data_filtered))
