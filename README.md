# Instruction-Level Power Side-Channel Leakage Evaluation of Soft-Core CPUs on Shared FPGAs

This directory contains the design files corresponding to the Springer Journal of Hardware and Systems Security (special issue on Multi-tenant Computing Security Challenges and Solutions) paper "Instruction-Level Power Side-Channel Leakage Evaluation of Soft-Core CPUs on Shared FPGAs" by Ognjen Glamocanin, Shashwat Shrivastava, Jinwei Yao, Nour Ardo, Mathias Payer, and Mirjana Stojilovic.

```
Overview:
│   │
│   └───README.md
│   │
│   └───LICENSE.md
│
└───boards/
│   │
│   └───alveo/: 
│   │   │
│   │   └───bitstreams/: Directory containing the bitstreams used for the experiments on the Alveo U200 Datacenter Card.
│   │   │
│   │   └───constraints/: Directory containing the constraints for RDS and TDC sensors.
│   │   │
│   │   └───rtl/: Directory containing the hardware files needed to create the project of the Alveo U200 Datacenter Card.
│   │   │
│   │   └───soft/: Directory containing all the software files need to collect the power traces on the Alveo U200 Datacenter Card.
│   │   │
│   │   └───tcl/: Directory containing the files that automatically create the project in Vivado by using the files from hw/.
│   │
│   └───sakura-x/: 
│      │
│      └───bitstreams/: Directory containing all the bitstreams used on the Sakura-X board. The placement strategy is specified in the bitstream name.
│      │
│      └───hw/: Directory containing all the hardware files needed to create the project on the Sakura-X board.
│      │    │
│      │    └───tcl/: Directory containing the TCL scripts to automatically set up a project in Vivado.
│      │
│      └───sw/: Directory containing the software files needed to collect the power traces on the Sakura-X board.
│
└───ml_attack/
│   │
│   └───docker/: Directory containing the docker file and entry scripts for the required ML environment.
│   │
│   └───attack/: Directory containing the ML scripts to perform the instruction leakage profiling.
│      │
│      └───models/: Directory containing the ML models used in the paper.
│      │
│      └───regression_generators/: Directory containing python scripts that create bash scripts used to schedule all ML training on a runai cluster (kubernetes). If runai is not used, these scripts can still be used to generate the parameters for the ML training scripts (`launch_job_nfs.py`), since the command to launch the training script is embedded in the runai call.
|
└───process/:
│   │
│   └───process\_traces/: Directory containing the scripts that process raw traces to obtain traces used in the ML profiling, for both boards.
│   │
│   └───process\_results/: Directory containing scripts that process the output of the ML profiling.
│        │
│        └───unpack\_results/: Directory containing scripts that unzip all the ML results.
│        │
│        └───collect\_accuracies/: Directory containing scripts that parse all the ML results and sum them in `.csv` format.
│
└───plot/: Directory containing scripts that plot all the figures in the paper.
|
└───template\_generation/: Directory containing all the template generation scripts.
    │
    └───firmware/: Directory containing the source files and instructions on how to install the RISC-V compiler.
    │
    └───instructions/: Directory containing the scripts to generate instruction templates.
    │
    └───snippets/: Directory containing the scripts to generate the code sequence templates.

```

## Sakura-X experiments

1. Generating templates
    * Generate the templates for Sakura X using the `template_generation/instructions/generate_templates.sh` script. Make sure to set the desired CPU to `riscy`, the desired number of templates per instruction to `10000`, and the desired type of templates to NOPs (for N templates) or random (for R templates).
    * Save the generated templates from the `out` folder to the desired directory.
2. Build Vivado project and generate bitstream
    * Start Vivado 2018.3. When Vivado is started, a TCL command-line interface appears in the lower part of the GUI. Use this TCL command-line interface to change the directory:
       ```bash
          cd sakura_x/hw/tcl
       ```
    * Give a name to your project as follows:
       ```bash
          set project_name <your_project_name>
       ```
    * Choose your desired sensor and execute the corresponding TCL script (one for each placement), e.g.,
       ```bash
          source desired_tcl_script.tcl
       ```
    * Vivado automatically creates the project. To implement the design, hit the `Run Implementation` button.
    * Click on the `Generate Bitstream` button to generate the bitstream of the implementation.
3. Calibrating sensors (repeated for each bitstream/placement)
    * Change the variable `TEMPLATE_PATH[]` in `boards/sakura-x/sw/main.c` to point to the directory where the templates are stored.
    * Change the variable `DUMP_PATH[]` in `boards/sakura-x/sw/main.c` to point to the directory where the test traces will be saved.
    * Compile the Sakura-X interface software found in `boards/sakura-x/sw/`
    * Program control FPGA with the bitstream in `boards/sakura-x/hw/bitstreams/ctrl/sasebo_giii_ctrl_24MHz.bit`
    * Program main FPGA with the bitstream generated in step 2.
    * Run the `unload_sio.sh` and `setupFTD.sh` scripts in the `boards/sakura-x/sw/Debug` folder
    * Run the compiled Sakura-X interface software found in `boards/sakura-x/sw/Debug` by running `./FTDexampleAES -t 100 -s 500 1000 -c 1 -i data/ -d data/`
    * Follow instructions and calibrate sensors (so that the clock edge is at the middle of the delay line, for example `0x00ff`)
    * Save calibration for each sensor, and replace it in `boards/sakura-x/sw/main.c` file (matrix `idc_idf[5][16]`)
    * Recompile the software
    * Reprogram the main FPGA with the bitstream generated in step 2.
4. Recording opcode positioner traces
    * Run the `regression_quick.sh` and collect traces with no averaging (for opcode extraction)
5. Extracting start and end locations
    * When step 4 is done, run the `process_opcodes_sakura.py` in `template_generation/instructions` folder (make sure to change the according paths in the scripts to point to the templates folder and the newly collected traces folder), and run the script to generate the start and end times for the metadata file.
6. Recording Exp-IN-N, Exp-OUT1-N, Exp-OUT1-R, and Exp-OUT2-N datasets
    * Program the main Sakura-X FPGA with the according bitstream
    * Make sure to use the correct calibration for each sensor, by setting it in `boards/sakura-x/sw/main.c` file (matrix `idc_idf[5][16]`), according to the values from step 2 for that bitstream
    * Change the variable `TEMPLATE_PATH[]` in `boards/sakura-x/sw/main.c` to point to the directory where the templates are stored.
    * Change the variable `DUMP_PATH[]` in `boards/sakura-x/sw/main.c` to point to the directory where the test traces will be saved.
    * Compile the code
    * Run the `regression.sh` and collect traces
7. Processing the raw traces
    * Set the correct paths in the `regression.sh` script in `HaSS/process/process_traces/sakura`
    * Run Make
    * Run the `regression.sh` script, which creates the averaged traces for the given dataset (but also traces with 1, 10, ..., 90 averaging).
8. ML profiling the traces
    * Create the docker image in `ml_attack/docker`
    * Generate the ML scripts needed to run the ML training using scripts in `ml_attack/attack/regression_generators`. There is one script per table in the paper.
    * In case of the use of RunAI, push the docker image to a docker repository, and before running the generator scripts, make sure to update the `--pvc` path of the RunAI command with a valid drive, and the `-i` path to the docker repository and the docker name
    * In case of the use of RunAI, run the generated bash scripts, which will schedule RunAI jobs
    * In case of regular use, extract the command to launch training (`launch_job_*.py ...`) and use it in the Docker image to run the ML training jobs.
    * For more information use the help option of the `launch_job_nfs.py` script
    * Save the results of all ML models to one board and dataset-specific directory
9. Unzipping the results
    * Once all the results are collected in step 8, run the `create_unpack_regression_sakura.py` (make sure to change the according paths) script from `process/process_results/unpack_results`
    * Run the generated bash script to unpack all the results
10. Collecting the results
    * Run all the python notebooks (except the `*alveo.ipynb`) from `process/process_results/collect_results` to collect all the results (make sure to change the according paths)
11. Plotting the results
    * Run all the python notebooks from `plot` to plot the figures in the paper

## Alveo experiments

1. Generating templates (instructions and snippets)
    * Generate the templates for Alveo using the `template_generation/instructions/generate_templates.sh` script. Make sure to set the desired CPU to `picorv32`, the desired number of templates per instruction to `10000` or `20000`, and the desired type of templates to NOPs (for N templates) or random (for R templates).
    * Save the generated templates from the `alveo_out` folder to the desired directory.
2. Generate the bitstream
    * Vitis/Vivado 2022.1, XRT library 2.13.466
    * In `boards/alveo/picorv/alveo//tcl`, run `make_impl`
    * Bitstream will be generated in `boards/alveo/picorv/alveo/bin`
3. Calibrating sensors
    * Run `make` in the `boards/alveo/picorv/alveo/soft/host/calibrate` directory
    * Run the host command (in the `calibrate` directory):
      * `./host 29 32 16 32 96 0 1 /out/path`
    * This will sweep all possible calibration values for each sensor and save them in `idc_idf_sweep_sensor*_raw.csv` files, one per sensor.
    * Find manually a good calibration for each sensor (`0x00ff` is a good example)
    * Save IDC/IDF pair for each sensor in `generate.cpp`, and use it to generate the new `idc_idf.bin` file
4. Recording opcode positioner traces
    * Run `make` in the `boards/alveo/picorv/alveo/soft/host` directory
    * Run one of these three commands (depending on the dataset, and update the paths to the calibration, templates, and output traces), which records one trace per template:
      * For Exp-OUT-10k-N: `./host ../../bitstreams/single_bank/shell_v2/with_CPU_flags/BRAM/tdc_29/picorv_sca.xclbin 29 256 16 32 96 1 0 0 0 path_to_calibration/idc_idf.bin path_to_templates/nops/10k/ path_to_save_traces/nops/10k/`
      * For Exp-OUT-10k-R: `./host ../../bitstreams/single_bank/shell_v2/with_CPU_flags/BRAM/tdc_29/picorv_sca.xclbin 29 256 16 32 96 1 0 0 0 path_to_calibration/idc_idf.bin path_to_templates/random/10k/ path_to_save_traces/random/10k/`
      * For Exp-OUT-20k-R: `./host ../../bitstreams/single_bank/shell_v2/with_CPU_flags/BRAM/tdc_29/picorv_sca.xclbin 29 256 16 32 96 1 0 0 0 path_to_calibration/idc_idf.bin path_to_templates/random/20k/ path_to_save_traces/random/20k/`
5. Extracting start and end locations
    * When step 4 is done, run the `process_opcodes_alveo.py` in `template_generation/instructions` folder, and run the script to generate the start and end times for the metadata file (make sure to change the according paths).
6. Recording Exp-OUT-10k-N, Exp-OUT-10k-R, and Exp-OUT-20k-R datasets
    * Run one of these three commands (depending on the dataset, and update the paths to the calibration, templates, and output traces), which records thousand traces per template:
      * For Exp-OUT-10k-N: `./host ../../bitstreams/single_bank/shell_v2/with_CPU_flags/BRAM/tdc_29/picorv_sca.xclbin 29 256 16 32 96 1000 0 0 0 path_to_calibration/idc_idf.bin path_to_templates/nops/10k/ path_to_save_traces/nops/10k/`
      * For Exp-OUT-10k-R: `./host ../../bitstreams/single_bank/shell_v2/with_CPU_flags/BRAM/tdc_29/picorv_sca.xclbin 29 256 16 32 96 1000 0 0 0 path_to_calibration/idc_idf.bin path_to_templates/random/10k/ path_to_save_traces/random/10k/`
      * For Exp-OUT-20k-R: `./host ../../bitstreams/single_bank/shell_v2/with_CPU_flags/BRAM/tdc_29/picorv_sca.xclbin 29 256 16 32 96 1000 0 0 0 path_to_calibration/idc_idf.bin path_to_templates/random/20k/ path_to_save_traces/random/20k/`
7. Processing the raw traces
    * Set the correct paths in the `cut_regression.sh` script in `HaSS/process/process_traces/alveo`
    * Run the `cut_regression.sh` script, which creates the cut traces for the given dataset.
8. ML profiling the traces
    * Create the docker image in `ml_attack/docker`
    * Generate the ML scripts needed to run the ML training using the `create_regression_alveo.py` script in `ml_attack/attack/regression_generators`.
    * In case of the use of RunAI, push the docker image to a docker repository, and before running the generator scripts, make sure to update the `--pvc` path of the RunAI command with a valid drive, and the `-i` path to the docker repository and the docker name
    * In case of the use of RunAI, run the generated bash scripts, which will schedule RunAI jobs
    * In case of regular use, extract the command to launch training (`launch_job_*.py ...`) and use it in the Docker image to run the ML training jobs.
    * For more information use the help option of the `launch_job_nfs.py` script
    * Save the results of all ML models to one board and dataset-specific directory
9. Unzipping the results
    * Once all the results are collected in step 8, run the `create_unpack_regression_alveo.py` (make sure to change the according paths) script from `process/process_results/unpack_results`
    * Run the generated bash script to unpack all the results
10. Collecting the results
    * Run the `collect_accuracies_alveo.ipynb` python notebook from `process/process_results/collect_results` to collect all the results (make sure to change the according paths)
