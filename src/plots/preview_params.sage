import time
import random as rd
import numpy as np
from datetime import datetime
import sys

load("../impl_99.sage")
load("../md_transform.py")

param_file = 'attack_parameters.csv'
help_file = 'parameters_help.md'

with open(param_file, 'r') as file:
  content = file.read()

header = content.split("\n")[0]
print(header)
content = content.split("\n")[1:]

if "h" in sys.argv or "help" in sys.argv:
   print_md_file(help_file)
   exit()

# check errors
if content[-1] == "":
  content = content[:-1]

for instruction in content:
    print(instruction)
    emin,emax,enb,nmin,nmax,nstep,p_q,algo = instruction.split(' ; ')
    
    with open('./p_q_keys/'+p_q, "r", encoding="utf-8") as f:
      lines = f.readlines()  
      random_line = rd.choice(lines)
    p,q = random_line.split(':')
    p,q = int(p),int(q)

    # fixe les paramètres
    Zp = GF(p)
    Zq = GF(q)
    g = get_g(p,q)
    g = Zp(g)

    x = get_x(q)
    h = g ** x

    display_p_q_sizes(p,q)

    e_values = [f"{e_frac:.3f}" for e_frac in np.linspace(float(emin), float(emax), int(enb))]

    print("epsilon values:", e_values[0], e_values[1], "...", e_values[-1])

    n_values = range(int(nmin), int(nmax), int(nstep))
    print("n values:", n_values[0], n_values[1], "...", n_values[-1])

    print(f"number of tests: {len(e_values) * len(n_values)}\n")


    


