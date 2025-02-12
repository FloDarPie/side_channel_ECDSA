.PHONY: help tuto all fast biblio clean venv test preview attack exp plot

help:
	@echo -e "\033[0;32mUsage:\033[0m"
	@echo -e "make help\t\tDisplay this help"
	@echo -e "make tuto\t\tDisplay tutorial from README.md"
	@echo -e "make [all | fast]\tBuild report.tex without biber"
	@echo -e "make biblio\t\tBuild report.tex with his bilio"
	@echo -e "make clean\t\tRemove latex build byproducts in report/"
	@echo -e "\t\t\tand *.sage.py src/, src/test and src/plots"
	@echo -e "make venv\t\tSetup venv with libs"
	@echo -e "make test\t\tRun all unittest"
	@echo -e "make preview\t\tPreview attack params from src/plots/parameters.csv"
	@echo -e "make attack\t\tRun attack with params from src/plots/parameters.csv"
	@echo -e "make exp [VARS]\t\tRun experiences (cf. make tuto)"
	@echo -e "make plot [VARS]\tPlot exp results (cf. make tuto)\n"

tuto:
	python3 ./src/md_transform.py --target README.md

all: fast

fast: 
	@cd ./report && pdflatex -shell-escape report.tex && pdflatex -shell-escape report.tex

biblio: 
	@cd ./report && pdflatex -shell-escape report.tex &&\
	 biber report && pdflatex -shell-escape report.tex && pdflatex -shell-escape report.tex

clean:
	@cd ./report && rm -f *.aux *.log *.out *.bbl *.nlo *.bcf *.blg *.run.xml *.toc *.pygtex *.pygstyle .nfs*\
	 && cd ../src && rm -f *.sage.py\
	 && cd ./test && rm -f *.sage.py\
	 && cd ../plots && rm -f *.sage.py

venv: # source ecdsa_env/bin/activate
	@chmod +x ./src/setup_venv.sh
	./src/setup_venv.sh

test:
	@cd ./src/test/ && chmod +x ./launch_tests.sh && ./launch_tests.sh

preview:
	@cd ./src/plots && sage preview_params.sage

attack:
	@cd ./src/plots && sage experiment.sage

EMIN=0.1
EMAX=0.2
ENB=2
NMIN=5
NMAX=15
NSTEP=5
exp:
	@cd ./src/plots && sage run_some_atk.sage \
	$(EMIN) $(EMAX) $(ENB) $(NMIN) $(NMAX) $(NSTEP)

STYLE='best'
IN='last'
OUT='show' # displaying instead of saving
plot:
	@cd ./src/plots && python3 result_plotter.py $(STYLE) $(IN) $(OUT) 