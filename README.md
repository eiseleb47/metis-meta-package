# METIS Pipeline Installer

A tiny meta-package that installs the ESO stack required for the METIS Pipeline:
`pycpl`, `pyesorex`, `edps`, `adari_core`.

The `pycpl` portion of this meta package is installed from https://github.com/ivh/pycpl

To use the pipeline follow the following steps:  

Clone the repository:  
`git clone https://github.com/eiseleb47/metis-meta-package`  

Enter the repository locally:  
`cd metis-meta-package`  

Run the script:  
`./bootstrap.sh` 

Note: EDPS will ask you in which directory you want to store Pipeline products, to use the default just press `ENTER`

For the usage of the pipeline see: [METIS_Pipeline](https://github.com/eiseleb47/metis-meta-package)  
Remember that you need to prepend all commands with `uv run --env-file .env` while being in the repository.
