import sys
import time

load("src/impl_99.sage")
load("src/shared_functions.sage")
load("src/ecdsa.sage")

from sage.modules.free_module_integer import IntegerLattice


###################################################################################################

########## Pour lancer : sage src/main.sage <nb_signatures> <epsilon> <mode> <nb_blocs> ###########

###################################################################################################
# pour <mode> : ECDSA pour l'attaque sur ECDSA, n'importe quoi pour l'attaque de 99 sur DSA 160bits
#               NON_C pour l'attaque en non_contiguë avec nb_blocs à 2 par défaut




# p,q,seed,counter = generate_p_q(1024,160)
# print(p,int(p).bit_length())
# print(q,int(q).bit_length())
# print(seed)

p = 906451402757531491528347543991965234378604973129269705492472129523782487766614021889227442682267886074307292927204600169914974164281891819286851424239355717753220030403878552060160148901948842626145985604965725925995708353545622337042837155897328722293454170436280382414179204815920139165021038274214324133441128748041485323750264965207
q = 1059913563491035635396448336427206671662765775323
# seed = 739379029894990508348846705218308531725075052272
Zp = GF(p)
Zq = GF(q)

g = 293371185853534367511844757434644570812647513218435580316069229785172955124429736895770945422242233686785606862787032030077878386643174691259013000164799577907874573865328598727158515510280793452269117630500180299498233510391795063046406707109176370083243422230003054010329258322170583298853051287181677571803798228224133321144496297461
g = Zp(g)

x = Zq(1234567890987654321)
h = g ** x

#display_public_element(p,q,g,h)
'''
#Pourcentage de bits connu
epsilon = 0.5

# Nombre de signatures récupérés
n = 40

index = 0 # index de la clé éphémère testée
equations, ephemeral_keys, known_parts = data_gen(n+1, epsilon, Zq, g, x)
equations = rearrange_equations(equations,n+1)
A = matrix_from_equations(equations,n)
0
#Étude de l'attaque en opérations simples
Z = attack(A, equations)
zi_prime, lambda_i, zi_2prime, mu_i = known_parts[index]
z0_found = zi_prime + Z[index+1]*2**lambda_i + zi_2prime*2**mu_i
actual_z0 = ZZ(ephemeral_keys[index])
print(actual_z0, "nb bits :",len(bin(actual_z0)))
print(Z[index+1], "nb bits :",len(bin(Z[index+1])))
print(z0_found, "nb bits :",len(bin(z0_found)))
z0_found = Zq(z0_found)
print(z0_found, "nb bits :",len(bin(z0_found)))

print("z0_found == actual_z0: ", z0_found == actual_z0)
'''
##################

ECDSA = False

if len(sys.argv) < 4 or len(sys.argv) > 5 :
    print("Expected format : sage src/main.sage <nb_signatures> <epsilon> <mode> <nb_blocs>")
    sys.exit(1)

nb_signatures = int(sys.argv[1])
n = nb_signatures - 1
epsilon = float(sys.argv[2])
mode = sys.argv[3]

if len(sys.argv) == 5 :
    d = int(sys.argv[4])
else :
    d = 2

##################
match mode :
    case 'NON_C' :
        
        if len(sys.argv) == 4 :
            print("No unknown blocks number specified, launched with default value : 2\n")
        print("Attack on DSA99 non_contiguous with {} unknown blocks".format(d))
        
        elapsed, correct = timed_attack_non_contiguous(epsilon, d, nb_signatures, Zq, g, x, algo='LLL')
        
        print(elapsed, correct)
        


    case 'ECDSA' :

        print("Attack on ECDSA with p256 elliptic curve :\n")
        Zq = GF(curve.n)
        index = 0 # index de la clé éphémère testée

        private_key,public_key = make_keypair()
        equations, ephemeral_keys, known_parts = data_gen_ecdsa(nb_signatures, epsilon, Zq, private_key)
        s1 = equations[index][0]
        s1_inv = equations[index][1]
        r1 = equations[index][3]
        hm1 = equations[index][2]
        equations = rearrange_equations_ecdsa(equations,Zq)
        A = matrix_from_equations_ecdsa(equations,Zq)

        Z = attack(A, equations)

        zi_prime, lambda_i, zi_2prime, mu_i = known_parts[index]
        z1_found = reconstruct(Z[index+1],zi_prime, zi_2prime, lambda_i, mu_i)
        actual_z1 = ZZ(ephemeral_keys[index])
        z1_prime, lambda_1, z1_2prime, mu_1 = known_parts[0]
        hidden_z1 = z1_prime + 2^(mu_1)*z1_2prime
        print("actual_z1:", hex(int(actual_z1)))
        print("hidden_z1:", hex(int(hidden_z1)))
        print("z1_found :", hex(int(z1_found)))

        print("z1_found == actual_z1: ", z1_found == actual_z1)

        private_key_found = (Zq(z1_found) - hm1*s1_inv) * s1 * r1^(-1)
        print("private key recovered :", private_key == private_key_found)


        correct_zi_count = 0
        for index in range(nb_signatures) :
            zi_prime, lambda_i, zi_2prime, mu_i = known_parts[index]
            # j'ai pas réussi à modifier Z pour remettre z0 à la fin donc tout est décalé de 1
            if reconstruct(Z[(index+1)%(nb_signatures)],zi_prime, zi_2prime, lambda_i, mu_i) == ZZ(ephemeral_keys[index]) :
                correct_zi_count += 1
        print("Number of ephemeral key recovered :", correct_zi_count) # ça devrait toujours être égal au nombre de signature quand l'attaque fonctionne

    case _:
        print("DSA99 attack :")
        equations, ephemeral_keys, known_parts = data_gen(nb_signatures, epsilon, Zq, g, x)
        equations = rearrange_equations(equations,nb_signatures)
        A = matrix_from_equations(equations,n)

        start = time.time()
        Z = attack(A, equations, algo='BKZ', block_size=35)
        end = time.time()
        elapsed = end-start

        index = 0
        zi_prime, lambda_i, zi_2prime, mu_i = known_parts[index]
        z1_found = zi_prime + Z[index+1]*2**lambda_i + zi_2prime*2**mu_i
        actual_z1 = ZZ(ephemeral_keys[index])
        z1_prime, lambda_1, z1_2prime, mu_1 = known_parts[0]
        hidden_z1 = z1_prime + 2^(mu_1)*z1_2prime
        print("actual_z1:", hex(int(actual_z1)))
        print("hidden_z1:", hex(int(hidden_z1)))
        print("z1_found :", hex(int(z1_found)))


        print("z1_found == actual_z1: ", z1_found == actual_z1)
        print("Attack duration :", elapsed)
