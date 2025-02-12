# Attaque par canal auxiliaire sur la signature ECDSA et réduction de réseau

## Project's guide

### Discover commands

    make help # make commands usage
    make tuto # display this tutorial

### Setup project

#### Install libs in venv and test code

    make venv # install virtual environnement and librairies❗

#### Enter virtual environment

    source ecdsa_env/bin/activate # enter project venv🔥

#### Test if there is some bug

    make test # run test on source code of this project

### Run an attack

#### Parameters setup

    python3 src/md_transform.py --target src/plots/parameters_help.md # display param help
    nano src/plots/attack_parameters.csv # setup params for attack❗
    make preview # visualize attack parameters🔥

#### Run the attack

    make attack # run attack with these params❗

### Read and visualise results

#### Display basic information

    ls -R src/plots/results/ # find all attack results

##### Get last folder and last file in this folder

    LD=\$(ls -tdr -- src/plots/results/*/ | tail -n 1) # get last folder
    LF=\$(ls -Art \$LD | tail -n 1) ; less \$LD\$LF # read latest result

#### Plot results from .csv

##### Plot with default params

    make plot # display scatterplots from last edited folder in src/plots/results/

##### Plot with custom params

STYLE can have any value in: *pairplot*, *scatterplots*, *logt_size*, *epsi_time* and *best*

    make plot STYLE=pairplot IN=your_exp_folder/*.csv OUT=auto # save pairplot with auto name

    make plot STYLE=scatterplots IN=last OUT=show # show scatterplots (won't work with SSH)

## Missions

- f(g^y) is the only thing that changes for ECDSA: r = x[n] is a pseudo hash to Z/nz
- P-256, try sage implementation, just give base point and field and use the 3 coordinates (x,y,z)
- Redaction section DSA, ECDSA, autres
- Calculer les temps en moyenne sur plusieurs mesures
