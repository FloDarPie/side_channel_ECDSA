import time
import random as rd
import numpy as np
from datetime import datetime
import subprocess
from pathlib import Path
import os

load("../impl_99.sage")



hostname = subprocess.check_output(["cat", "/etc/hostname"], text=True).strip()

ssh_tty = os.environ.get('SSH_TTY', default="")
# print(ssh_tty)
if ssh_tty != "":
    hostname = "ssh:" + hostname

dossier = Path("./p_q_keys")

p_q_keys = [] 

nb_test = 5

algorithms_1 = ['LLL', 'BKZ', 'fast']
algorithms_2 = ['BKZ_2', 'BKZ_half', 'BKZ_max', 'BKZ2_2', 'BKZ2_half', 'BKZ2_max']
algorithms_3 = ['LLL.simple', 'LLL.double', 'LLL.long', 'LLL.quaternion']

# test sur plusieurs taille de clés
for f in dossier.glob("*"):
    p_q_keys.append(f.name)
#choix de la clé la plus petite
p_q_keys = [p_q_keys[0]]


#nombre de tests que l'on réalise
for index in range(nb_test):
    #Lancement des tests
    for p_q in p_q_keys:
        print(f'>>> Selection parameters : {p_q}')
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
        test_n = 2
        _,_ = timed_attack(test_epsilon, test_n, Zq, g, x, 'LLL')
        ##########
        

        # structure de memorisation
        date = datetime.now().strftime("%Y_%m_%d_%H_%M")
        domain = f"./results/{hostname}_{date}"
        os.makedirs(domain, exist_ok=True)
            
        for algo in algorithms_3:
            filename = f"{domain}/{p_q}_{algo}_{index}.csv"
            with open(filename, "w") as f:
                f.write("epsilon ; nb messages ; time (sec) ; correct\n")
            print(f'\n>>> Run all test : {algo} ')
            
            # parametres initiaux
            epsilon = 50
            pas_epsilon = 0.5
            nb_message = 2

            max_message = 100

            balise = 0
            store_equations = []
            ephemeral_keys = []
            known_parts = []
            while 0 < epsilon <= 100:
                print(f"\r> Tested epsilon : {float(epsilon/100)} - {nb_message}", end='')

                ###################
                # Génération des paramètres
                if balise != epsilon:
                    balise = epsilon
                    store_equations, ephemeral_keys, known_parts = data_gen(nb_message, epsilon/100, Zq, g, x)                
                else:
                    new_equation, new_ephemeral_key, new_known_part = data_gen(1, epsilon/100, Zq, g, x)
                    store_equations.append(new_equation[0])
                    ephemeral_keys.append(new_ephemeral_key)
                    known_parts.append(new_known_part)
                #####
                
                equations = rearrange_equations(store_equations[:], nb_message)
                A = matrix_from_equations(equations, nb_message-1)
                start = time.time() 
                '''
                match algo:
                case 'LLL':
                    B = A.LLL()
                case 'BKZ':
                    B = A.BKZ(algorithm='NTL')
                case "fast":
                    B = A.LLL(algorithm='fpLLL:fast')
                case _: # other cases
                    raise ValueError("algo=%s is not available" % (algo))
                '''
                
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
                        B = A.BKZ(algorithm='fpLLL:fast')

                    #study for LLL fast
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

                zi_prime, lambda_i, zi_2prime, mu_i = known_parts[0]

                z0_found = zi_prime + Z[1]*2**lambda_i + zi_2prime*2**mu_i
                actual_z0 = ZZ(ephemeral_keys[0])
                correct = (z0_found == actual_z0)
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
