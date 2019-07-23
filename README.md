Proteomic Pipeline Generator
============================

Proteomic Pipeline generator is a command line script that generates multiple pipelines for use with proteomics data.

## Programs
The PPG currently uses two types of software: database search software, and statistical validation software. It also offers statistical enrichment analysis with g:profiler and pathway analysis with Reactome.

### Database search
  * [Comet](http://comet-ms.sourceforge.net/)
  * [X!tandem](https://www.thegpm.org/tandem/)
  * [MS-GF+](https://omics.pnl.gov/software/ms-gf)
  
### Statistical validation
  * [PeptideProphet](https://sourceforge.net/projects/sashimi/files/Trans-Proteomic%20Pipeline%20%28TPP%29/) (not avalible outside of the TPP)
  * [Percolator](https://github.com/percolator/percolator/wiki)

### Analysis
 * [g:profiler](https://biit.cs.ut.ee/gprofiler/page/docs)
 * [Reactome](https://reactome.org/)  

## Instalation
Add the location of the programs that you have installed to second collumn of the install_locations file.  
If no programs are added the script will check `PATH` for installation.  

## Options
The PPG is issued with multiple variables some are required.  
**Options required to generate the pipelines**  
[`-P [Programs to build pipelines for]`](https://github.com/pieterklap/Pipeline#Programs)  


**Options required to automaticaly run the pipelines**  
`-i [input file]`  
`-p [parameterfiles]` `(in the same order as the programs)`      

**Optional variables**  
`-l [logfile location]`   
`-o [output directory]`  
`-L [locations of the generated scripts]`   
`-s "[options]"` `(for use on the LUMC sharkcluster calls the scripts with qsub with everyting after the -s)`  
 all the parameters passed to -s have to be entered inbetween ' '  
 example: `-s '-pe BWA 4 -cwd'`
 
 `-n || --norun` causes the scripts to not run   
 `-g || --genparam` only generates the parameter files   
`--autorun` automaticaly run the pipeline when running localy.   
 `-S || --noScripts` Don't generate new scripts you can give the location of the scripts you want to run.   
