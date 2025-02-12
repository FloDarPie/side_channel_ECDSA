import time
import random as rd
import numpy as np
from datetime import datetime
import sys

load("../impl_99.sage")
load("../md_transform.py")

# param_file = 'parameters.csv'
param_file = 'attack_parameters.csv'
help_file = 'parameters_help.md'

file = open(param_file, 'r')
content = file.read()
file.close()
content = content.split("\n")[1:]

help_message = "##########################################################################\n"
help_message += "To run full_attack, you have to configure 'parameters.csv'.\n"
help_message += "The list of parameters to define is :\n"
help_message += "- EMIN : knowledge of ephemeral key know minimal\n"
help_message += "- EMAX : knowledge of ephemeral key know maximal\n"
help_message += "- ENB : number of sample tested beetween EMIN & EMAX\n"
help_message += "- NMIN : minimal number of signatures know\n"
help_message += "- NMAX : maximal number of signatures know\n"
help_message += "- NSTEP : coverage beetween the two bornes of signature\n"
help_message += "- p_q : choice of size keys\n"
help_message += "- ALGO : choice of algorithm to reduce the lattice LLL / BKZ / fastLLL\n"

if "h" in sys.argv or "help" in sys.argv:
  # print(help_message)
  print_md_file(help_file)
  exit()

# check errors
if content[-1] == "":
  content = content[:-1]

for instruction in content:
    emin,emax,enb,nmin,nmax,nstep,p_q,algo = instruction.split(' ; ')

    filename = "./results/"+p_q+"_"+algo+"_"+datetime.now().strftime("%Y_%m_%d_%H_%M")+".csv"
    with open(filename, "a") as f:
        f.write("epsilon ; n ; elapsed (sec) ; correct\n")

    print(f'> Run all test : {p_q}')
    #sélection du couple de clé
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

    #warm up (otherwise first mesure is longer)
    test_epsilon = 0.9
    test_n = 40
    elapsed, correct = timed_attack(test_epsilon, test_n, Zq, g, x, 'LLL')

    #run all attacks
    for epsilon_frac in np.linspace(float(emin), float(emax), int(enb)):
      epsilon = f"{epsilon_frac:.3f}"
      print(f">>> Tested epsilon : {epsilon}")
      for n in range(int(nmin), int(nmax), int(nstep)):
        elapsed, correct = timed_attack(float(epsilon), n, Zq, g, x, algo)
        with open(filename, "a") as f:
           f.write(f"{epsilon} ; {n} ; {elapsed} ; {correct}\n")
print('> Done.')


