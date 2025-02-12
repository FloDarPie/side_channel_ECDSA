import time
import random as rd
import numpy as np
from datetime import datetime
import subprocess
from pathlib import Path
import os

load("../impl_99.sage")
load("../shared_functions.sage")
load("../ecdsa.sage")

hostname = subprocess.check_output(["cat", "/etc/hostname"], text=True).strip()

ssh_tty = os.environ.get('SSH_TTY', default="")
# print(ssh_tty)
if ssh_tty != "":
    hostname = "ssh:" + hostname # FIXME doesn't work outside of cremi

dossier = Path("./p_q_keys")

Zq = GF(curve.n)
p_size = int(curve.p).bit_length()

nb_test = 5

algorithms_1 = ['LLL', 'BKZ', 'fast']
algorithms_2 = ['BKZ_2', 'BKZ_half', 'BKZ_max', 'BKZ2_2', 'BKZ2_half', 'BKZ2_max']
algorithms_3 = ['LLL.simple', 'LLL.double', 'LLL.long', 'LLL.quaternion']

# structure de memorisation
date = datetime.now().strftime("%Y_%m_%d_%H_%M")
domain = f"./results/{hostname}_{date}"
os.makedirs(domain, exist_ok=True)

#nombre de tests que l'on réalise
for tested in range(nb_test):
    for algo in algorithms_1:
        filename = f"{domain}/P-256_{p_size}_{algo}_{tested}.csv"
        with open(filename, "w") as f:
            f.write("epsilon ; nb messages ; time (sec) ; correct\n")
        print(f'\n>>> Run all test : {algo} ')
        
        # parametres initiaux
        epsilon = 100
        pas_epsilon = 5
        nb_message = 2
        max_message = 100

        # warm up
        private_key,public_key = make_keypair()
        equations, ephemeral_keys, known_parts = data_gen_ecdsa(nb_message, float(0.5), Zq, private_key)
        s1 = equations[0][0]
        s1_inv = equations[0][1]
        r1 = equations[0][3]
        hm1 = equations[0][2]
        equations = rearrange_equations_ecdsa(equations, Zq)
        A = matrix_from_equations_ecdsa(equations, Zq)
        start = time.time() 
        B = A.LLL()

        balise = 0
        store_equations = []
        ephemeral_keys = []
        known_parts = []

        while 0 < epsilon <= 100:
            print(f"\r> Tested epsilon : {float(epsilon/100)} - {nb_message}", end='')
            
            
            index = 0 # index de la clé éphémère testée

            private_key,public_key = make_keypair()
            equations, ephemeral_keys, known_parts = data_gen_ecdsa(nb_message, float(epsilon/100), Zq, private_key)
            s1 = equations[index][0]
            s1_inv = equations[index][1]
            r1 = equations[index][3]
            hm1 = equations[index][2]
            equations = rearrange_equations_ecdsa(equations,Zq)
            A = matrix_from_equations_ecdsa(equations,Zq)
            start = time.time() 
            
            
            taille_block = floor(A.nrows()/2)
            if taille_block<2:
                taille_block+=1
            match algo:
                #study for BKZ
                case 'BKZ_2':
                    B = A.BKZ(algorithm='NTL', block_size=2)
                case 'BKZ_half':
                    B = A.BKZ(algorithm='NTL', block_size=taille_block)
                case "BKZ_max":
                    B = A.BKZ(algorithm='NTL', block_size=A.nrows())
                case 'BKZ2_2':
                    B = A.BKZ(block_size=2)
                case 'BKZ2_half':
                    B = A.BKZ(block_size=taille_block)
                case "BKZ2_max":
                    B = A.BKZ(block_size=A.nrows())
                
                #study for general
                case "LLL":
                    B = A.LLL()
                case "BKZ":
                    B = A.BKZ(algorithm='NTL')
                case "fast":
                    B = A.LLL(algorithm='fpLLL:fast')
                case 'LLL.simple':
                    B = A.LLL(algorithm='fpLLL:fast')
                case 'LLL.double':
                    B = A.LLL(algorithm='fpLLL:fast', fp='fp')
                case 'LLL.long':
                    B = A.LLL(algorithm='fpLLL:fast', fp='ld')
                case 'LLL.quaternion':
                    B = A.LLL(algorithm='fpLLL:fast', fp='qd')
                    
                case _: # other cases
                    raise ValueError("algo=%s is not available" % (algo))

            B = IntegerLattice(B)
            
            T = [0] + [ZZ(equations[index][1]) for index in range(nb_message-1)]
            closest = approximate_closest_vector(B,T)
            Z = [closest[i] - T[i] for i in range(nb_message)]
            elapsed = time.time() - start
            ####
            # Check zone
            ###
            zi_prime, lambda_i, zi_2prime, mu_i = known_parts[index]
            z1_found = reconstruct(Z[index+1],zi_prime, zi_2prime, lambda_i, mu_i)
            actual_z1 = ZZ(ephemeral_keys[index])
            z1_prime, lambda_1, z1_2prime, mu_1 = known_parts[0]
            hidden_z1 = z1_prime + 2^(mu_1)*z1_2prime
            private_key_found = (Zq(z1_found) - hm1*s1_inv) * s1 * r1^(-1)

            correct = z1_found == actual_z1 and private_key_found == private_key
 
            ###################

            if correct:
                with open(filename, "a") as f:
                    f.write(f"{float(epsilon/100)} ; {nb_message} ; {elapsed} ; {correct}\n")
                epsilon = epsilon - pas_epsilon
            else:
                nb_message += 1

            
            #fin du travail
            #  -- max messages
            if nb_message >= max_message:
                with open(filename, "a") as f:
                    f.write(f"{float(epsilon/100)} ; {nb_message} ; {elapsed} ; {correct}\n")
                break
            #  -- timeout
            '''if elapsed > 120:
                with open(filename, "a") as f:
                    f.write(f"{float(epsilon/100)} ; {nb_message} ; {elapsed} ; {correct}\n")
                break'''
                
        pass 
    pass
