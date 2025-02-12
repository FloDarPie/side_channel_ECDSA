# compatibility for homework
try:
    from Cryptodome.Hash import SHA1
except ModuleNotFoundError:
    from Crypto.Hash import SHA1

from sage.modules.free_module_integer import IntegerLattice
from random import random

try:
    load("src/shared_functions.sage")
except:
    load("../shared_functions.sage")


### ATTENTION : J'ai noté q à la place de p le nombre premier de 160bits 
# (ici p est le premier de plus de 1024bit qui sert à obtenir un sous groupe multiplicatif d'ordre premier q)

# Retourne l'entier de 160bits correspondant au hashé de l'entier n
def sha1(n) :
    s = SHA1.new()
    n_byte_size = (int(n).bit_length() + 7) // 8
    s.update(int(n).to_bytes(n_byte_size, 'big'))
    h = s.hexdigest()
    del s
    return int(h , 16)

# generation des paramètres du DSA
# return p,q,seed,counter
def generate_p_q(L,N): 
    g = N
    n = (L-1) // g
    found_q = False

    while True :
        # generating q
        while not found_q :
            seed = ZZ.random_element(0,2**g)
            a = sha1(seed)
            zz = (seed + 1) % (2 ** g)
            z = sha1(zz)
            U = a ^^ z  # type: ignore
            mask = 2 ** (N - 1) + 1
            q = U | mask
            if q.is_prime() :
                found_q = True

        # generating p
        counter = 0 ; offset = 2
        while counter < 2 ** 12 :
            W = 0
            for k in range(n+1) :
                zzz = (seed + offset + k) % 2**g
                Vk = sha1(zzz)
                W += Vk * 2**(k*g)
            X = W + 2 ** (L - 1)
            c = X % (2 * q)
            p = X - (c - 1)
            if p > 2 ** (L - 1) :
                if p.is_prime() :
                    return p,q,seed,counter
            counter += 1
            offset += n + 1
        found_q = False

# On veut un générateur du sous groupe multiplicatif d'ordre q de Z/pZ
def get_g(p,q) :
    Zp = GF(p)
    e = (p - 1) / q
    h = Zp.random_element()
    while h^e == 1 :
        h = Zp.random_element()

    g = h**e
    return g

# Générateur de clé privé dans Zq
def get_x(q):
    Zq = GF(q)
    return Zq.random_element()

# Le message m est dans Zq !
# Application de la signature
# renvoie (m, g^y, b)
def sign(m,g,x,y) :
    gy = g^y
    b = (m + x * Zq(sha1(gy))) * y^(-1)
    return gy,b

# sign1 doit correspondre à g^y et sign2 à b
def verify(m,sign1,sign2,h,g) :
    sign2_inv = sign2^(-1)
    exp1 = m * sign2_inv
    part1 = g^exp1
    exp2 = sha1(sign1) * sign2_inv
    part2 = h^exp2
    return part1 * part2 == sign1


# x est la clé secrète et (p,q,g,h) la clé publique
def display_public_element(p,q,g,h):
    print(f"p = {p}\nq = {q}\ng = {g}\nh = {h}")

def display_p_q_sizes(p,q):
    print(f"p size: {int(p).bit_length()} bits, q size: {int(q).bit_length()} bits")


def display_equations(tab):
    for i in tab:
        print(i)

# print n en binaire sur 160bits
def bin160(n) :
    n_bin = bin(n).split('b')[1]
    t = len(n_bin)   
    if t < 160 :
        n_bin = [0]*(160-t) + [int(i) for i in n_bin]
    print(''.join([str(i) for i in  n_bin[:160]]))


#Collecte de données
def data_gen(n, epsilon, Zq, g, x) :
    ephemeral_keys = []
    equations = []
    part_known = []
    for _ in range(n) :  
        m = Zq.random_element()
        yi = Zq.random_element()
        ephemeral_keys.append(yi)
        gyi,bi = sign(m,g,x,yi)
        fi = Zq(sha1(gyi)) 
        zi_prime,zi, zi_2prime, lambda_i, mu_i = hide_contiguous(yi,epsilon, Zq.order())
        assert yi == zi_prime+zi*2**lambda_i+zi_2prime*2**mu_i, "Erreur lors de la découpe de la clé éphémère en trois blocs - data_gen"
        part_known.append((zi_prime, lambda_i, zi_2prime , mu_i))


        assert m == bi*yi - x*fi, "Erreur lors de la signature de nos messages"
        equations.append([m,bi**(-1),fi,zi_prime, zi_2prime, lambda_i, mu_i])
    
    return equations,ephemeral_keys,part_known


# version non_contiguë avec d blocks inconnus
def data_gen_non_contiguous(nb_sign, epsilon, d, Zq, g, x) :
    ephemeral_keys = []
    equations = []
    yi_prime_list = []
    lambda_i_list = []

    for _ in range(nb_sign) :
        m = Zq.random_element()
        yi = Zq.random_element()
        ephemeral_keys.append(yi)
        gyi,bi = sign(m,g,x,yi)
        fi = Zq(sha1(gyi))
        yi_prime,lambda_i = hide_non_contiguous(yi,epsilon, Zq.order(),d)
        yi_prime_list.append(yi_prime)
        lambda_i_list.append(lambda_i)

        equations.append([m,bi**(-1),fi,yi_prime, lambda_i])

    return equations, ephemeral_keys, yi_prime_list, lambda_i_list



#réarrangement des données
def rearrange_equations(equations,nb_sign) :
    for a in range(nb_sign):
        m,bi_inverse,fi,zi_prime, zi_2prime, lambda_i, mu_i = equations[a]
        #            yi +        x*Ci     +   Di
        equations[a] = [ - (bi_inverse*fi), (-bi_inverse*m), zi_prime, zi_2prime, lambda_i, mu_i]

    # reduction de l'inconnu x
    Ch,Dh,zh_prime, zh_2prime, lambda_h, mu_h = equations[-1]; equations = equations[:-1]; n = nb_sign - 1
    Ch_inv = Ch**(-1)
    x = [-Ch_inv,-Ch_inv*Dh ]
    for index in range(n):
        Ci = equations[index][0]
        equations[index][0] = Ci * x[0] 
        equations[index][1] += Ci * x[1]
    
    # construction des si et ti
    for index in range(n):
        Ci, Di, zi_prime, zi_2prime, lambda_i, mu_i = equations[index]
        exposant = Zq(2)^(-lambda_i)
        #               zi   + z_h*si      + ti
        equations[index] = [exposant*Ci*2^(lambda_h), exposant * (Ci*(zh_prime + 2**mu_h * zh_2prime)+zi_prime+Di+zi_2prime*2**mu_i) ]

    return equations



def rearrange_equations_non_contiguous(equations,nb_sign,Zq) :
    for a in range(nb_sign):
        m,bi_inverse,fi,yi_prime, lambda_i = equations[a]
        #            yi +        x*Ci     +   Di
        equations[a] = [ - (bi_inverse*fi), (-bi_inverse*m), yi_prime, lambda_i]
    
    # reduction de l'inconnu x
    Ch,Dh,yh_prime, lambda_h = equations[-1]; equations = equations[:-1]; n = nb_sign - 1
    Ch_inv = Ch**(-1)
    x = [-Ch_inv,-Ch_inv*Dh ]
    for index in range(n):
        Ci = equations[index][0]
        equations[index][0] = Ci * x[0] 
        equations[index][1] += Ci * x[1]
    
    # construction des si et ri (ce sont des listes) et ti (elem de Zq)
    for index in range(n):
        Ai, Bi, yi_prime, lambda_i = equations[index]
        inv = Zq(2)^(-lambda_i[0])
        Ai2 = Ai*inv ; Bi2 = Bi*inv
        r0 = [Zq(2)^lmbda for lmbda in lambda_h]
        d = len(lambda_i)
        
        si = [Zq(2)^lambda_i[j] * inv for j in range(1,d)]  # longueur d-1
        ri = [r0j * Ai2 for r0j in r0]                      # longueur d
        ti = yi_prime * inv + Ai2 * yh_prime + Bi2

        equations[index] = [si,ri,ti]

    return equations



# production de la matrice
def matrix_from_equations(equations,n) :
    A = Matrix(ZZ,n+1,n+1)
    A[0,0] = ZZ(-1)
    for index in range(n):
        A[0,index+1] = ZZ(equations[index][0])
        A[index+1,index+1] = ZZ(q)
    return A



def matrix_from_equations_non_contiguous(equations,n,d,q,epsilon) :
    R = Matrix(ZZ, [equations[i][1] for i in range(n)])
    Rt = R.transpose()

    S = Matrix(ZZ, n*(d-1), n)
    for i in range(n) :
        line = i * (d-1)
        column = i
        si = equations[i][0]
        for j,sij in enumerate(si) :
            S[line+j,column] = sij
    
    Id1 = - matrix.identity(d*(n+1)-n)
    new = block_matrix([[Rt],[S]])
    upper_part = block_matrix([[Id1,new]])

    Id2 = -q * matrix.identity(n)
    zero = Matrix(ZZ,n,d*(n+1)-n)
    lower_part = block_matrix([[zero,Id2]])

    left_matrix = block_matrix([[upper_part],[lower_part]])

    # Construction de D | TODO : garder les lambdas i dans equations pour calculer les Zi,j et donc les Ji,j 
    # Pour l'instant, les Ji,j ont tous la même valeur puisque 'unknown_size' dans 'hide_non_contiguous' est le même pour tous les blocs
    
    # Zi,j = 2 ^ (epsilon*160/d) d'où :
    # Ji,j = 2 ^ (epsilon*160*(n+1) - epsilon*160/d ) 

    Jij = 2 ** (floor(epsilon*160)*(n+1) - floor(epsilon*160)//d )
    D = Jij * matrix.identity(d*(n+1))

    B = left_matrix * D
   
    return B


#################################


def timed_attack(epsilon, n, Zq, g, x, algo='LLL'):
  equations, ephemeral_keys, known_parts = data_gen(n, epsilon, Zq, g, x)
  equations = rearrange_equations(equations, n)
  A = matrix_from_equations(equations, n-1)
  start = time.time() # data treatment doesn't count in atk duration
  match algo:
    case 'LLL':
        B = A.LLL()
    case 'BKZ':
        B = A.BKZ(algorithm='NTL')
    case "fast":
        B = A.LLL(algorithm='fpLLL:fast')
    case _: # other cases
        raise ValueError("algo=%s is not available" % (algo))

  B = IntegerLattice(B)

  # Target
  T = [0] + [ZZ(equations[index][1]) for index in range(n-1)]
  # Babai sur la matrice réduite
  closest = approximate_closest_vector(B,T)
  # On enlève la target pour retrouver les zi
  Z = [closest[i] - T[i] for i in range(n)]
  elapsed = time.time() - start

  zi_prime, lambda_i, zi_2prime, mu_i = known_parts[0]

  z0_found = zi_prime + Z[1]*2**lambda_i + zi_2prime*2**mu_i
  actual_z0 = ZZ(ephemeral_keys[0])
  correct = (z0_found == actual_z0) 
  return elapsed, correct



def timed_attack_non_contiguous(epsilon, d, nb_sign, Zq, g, x, algo='LLL'):
  equations, ephemeral_keys, yi_prime_list, lambda_i_list = data_gen_non_contiguous(nb_sign, epsilon, d, Zq, g, x)
  equations = rearrange_equations_non_contiguous(equations, nb_sign, Zq)
  n = nb_sign - 1
  q = Zq.order()
  Jij = 2 ** (floor(epsilon*160)*(n+1) - floor(epsilon*160)//d )
  A = matrix_from_equations_non_contiguous(equations, n, d, q, epsilon)
  start = time.time() # data treatment doesn't count in atk duration
  match algo:
    case 'LLL':
        B = A.LLL()
    case 'BKZ':
        B = A.BKZ(algorithm='NTL')
    case "fast":
        B = A.LLL(algorithm='fpLLL:fast')
    case _: # other cases
        raise ValueError("algo=%s is not available" % (algo))

  B = IntegerLattice(B)

  # Target
  T = [0]*(d*(n+1)-n) + [ZZ(equations[index][2] * Jij) for index in range(n)]
  # Babai sur la matrice réduite
  closest = approximate_closest_vector(B,T)
  # On enlève la target pour retrouver les zi
  Z = [closest[i] - T[i] for i in range(d*(n+1))]
  elapsed = time.time() - start

  z1_j = Z[d:2*d] # les d premiers correspondent à z0 ie zh, z1 est donc sur les d suivants
  z1_j = [e//Jij for e in z1_j]

  z1_prime = yi_prime_list[0]
  lambda_1_list = lambda_i_list[0]
  z1_found = reconstruct_non_contiguous(z1_prime,lambda_1_list,z1_j)
  actual_z1 = ZZ(ephemeral_keys[0])
  correct = (z1_found == actual_z1) 
  return elapsed, correct

