# Help to setup parameters for the attack

To run the attack, you have to configure ***attack_parameters.csv***.

Parameters to define are:

- **EMIN**: proportion of ephemeral key minimal knowledge
- **EMAX**: proportion of ephemeral key maximal knowledge
- **ENB**: number of equidistant epsilon values between **EMIN** and **EMAX** (used in *np.linspace*)
- **NMIN**: minimal number of signatures known
- **NMAX**: maximal number of signatures known
- **NSTEP**: size of the step from **NMIN** to **NMAX** (used in *range*)
- **p_q**: choice of size keys for p and q
- **ALGO**: choice of algorithm (**LLL**/**BKZ**/**fastLLL**) to reduce the lattice

At the end, the file should look like this:

	EMIN ; EMAX ; ENB ; NMIN ; NMAX ; NSTEP ; p_q ; ALGO
	0.10 ; 0.1 ; 10 ; 1 ; 8 ; 1 ; 2048_250 ; BKZ
	0.010 ; 0.1 ; 10 ; 3 ; 8 ; 2 ; 1024_160 ; LLL
