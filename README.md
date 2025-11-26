# METIS Pipeline Installer

A tiny meta-package that installs the ESO stack required for the METIS Pipeline:
`pycpl`, `pyesorex`, `edps`, `adari_core`.

To use the pipeline follow the following steps:  

Clone the repository:  
`git clone https://github.com/eiseleb47/metis-meta-package`  

Enter the repository locally:  
`cd metis-meta-package`  

Make the script executable:  
`chmod +x bootstrap.sh`  

Run the script:  
`./bootstrap.sh`  

For the usage of the pipeline see: [METIS_Pipeline](https://github.com/eiseleb47/metis-meta-package)  
Remember that you need to prepend all commands with `uv run --env-file .env` while being in the repository.
