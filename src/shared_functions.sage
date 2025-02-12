from sage.modules.free_module_integer import IntegerLattice
from random import random



def print_bin(n,len=160) :
    print("{:0{}b}".format(n,len))

def print_hex(n,len=40) :
    print("{:0{}x}".format(n,len))


def hide_contiguous_simple(y,epsilon) :
    if epsilon < 0 or epsilon > 1 : # je sais pas gérer les erreurs en python, -1 c'est bien lol
        return -1
    __lambda = floor(160*epsilon) # nb de bit de y à retourner
    return int(y) & (2^__lambda - 1), __lambda


#renvoie les blocs d'information connus et inconnus depuis une clé éphémère
def hide_contiguous(y,epsilon, q) :
    if not 0 < epsilon <= 1 :
        raise ValueError(" - epsilon doit être entre 0 et 1.")
    y = int(y)

    total = len(bin(q)[2:])
    nb_bits = floor(total*epsilon)    # nb de bit de y connus
    unknow = total - nb_bits          # nb de bits inconnus
    
    # séparation en deux blocs initiaux ou finaux
    p = random()
    __lambda = floor(p * nb_bits)
    mu = unknow + __lambda
    
    #application de masque
    a = y & ((1 << __lambda) - 1)
    b = (y >> __lambda) & ((1 << (mu - __lambda)) - 1)
    c = y >> mu

    assert y == a+b*2**__lambda+c*2**mu, "Erreur lors de la découpe de la clé éphémère en trois blocs"
    
    return a,b,c,__lambda,mu



# on fait assez simple en prenant d qui divise la taille de q pour découper y en d gros blocs de même taille
# et epsilon avec 1/epsilon qui divise la taille d'un bloc size(q)/d pour obtenir des Zi,j entiers constants = 2 ^ (epsilon*size(q)/d)
# Attention : si cette condition n'est pas remplie, la proportion de bits connus retournée sera != epsilon 
# et la construction de D dans matrix_from_equations devra être modifiée
def hide_non_contiguous(y,epsilon,q,d) :
    if not 0 < epsilon <= 1 :
        raise ValueError(" - epsilon doit être entre 0 et 1.")
    y = int(y)

    total = len(bin(q)[2:])
    block_size = total//d
    unknown_size = floor(block_size*epsilon)
    lambda_list = []
    y_prime = 0

    
    for index in range(d) :
        lambda_j = (block_size * index)+1
        lambda_list.append(lambda_j)
        # les lambdas sont tous un bit après la délimitation de chaque bloc 
        # (TODO : rajouter de l'aléatoire en faisant attention à ce que les blocs inconnus ne se touchent pas)
        yj = y & ((1 << (block_size)) - 1)
        y = y >> block_size

        low_part = yj & 1
        high_part = yj >> (unknown_size+1)
        hidden_yj = low_part | high_part << (unknown_size+1) # effacement d'un certain nombre de bits de ce bloc de y
        y_prime |= hidden_yj << (lambda_j-1)
    return y_prime,lambda_list



def reconstruct(z,z_prime, z_2prime, __lambda, mu) :
    return z_prime + z*2**__lambda + z_2prime*2**mu


def reconstruct_non_contiguous(z_prime, lambda_list, zj_list) :
    for i,lmbda in enumerate(lambda_list) :
        z_prime += zj_list[i] * 2**lmbda
    return z_prime


# production de la matrice
def matrix_from_equations(equations,n) :
    A = Matrix(ZZ,n+1,n+1)
    A[0,0] = ZZ(-1)
    for index in range(n):
        A[0,index+1] = ZZ(equations[index][0])
        A[index+1,index+1] = ZZ(q)
    return A


# Réduction de matrice
def attack(matrix, equations, algo='LLL', algo_babai='embedding', block_size=10) :
    block = block_size
    match algo:
        case 'LLL':
            B = matrix.LLL()
        case 'BKZ':
            B = matrix.BKZ(algorithm='NTL', block_size=block)
        case "fast":
            B = matrix.LLL(algorithm='fpLLL:fast')
        case _: # other cases
            raise ValueError("algo=%s is not available" % (algo))
    n =  len(equations)
    B = IntegerLattice(B)
    # Target
    T = [0] + [ZZ(equations[index][1]) for index in range(n)]
    # Babai sur la matrice réduite
    closest = approximate_closest_vector(B,T,algorithm=algo_babai)
    # On enlève la target pour retrouver les zi
    Z = [closest[i] - T[i] for i in range(n+1)]
    
    return Z

# Babai algorithm
def approximate_closest_vector(self, t, delta=None, algorithm='embedding', *args, **kwargs):
        r"""
        Compute a vector `w` in this lattice which is close to the target vector `t`.
        The ratio `\frac{|t-w|}{|t-u|}`, where `u` is the closest lattice vector to `t`,
        is exponential in the dimension of the lattice.
        """
        if delta is None:
            delta = ZZ(99)/ZZ(100)

        # Bound checks on delta are performed in is_LLL_reduced
        # if not self._reduced_basis.is_LLL_reduced(delta=delta):
        #     self.LLL(*args, delta=delta, **kwargs)

        B = self._reduced_basis
        t = vector(t)

        if algorithm == 'embedding':
            L = matrix(QQ, B.nrows()+1, B.ncols()+1)
            L.set_block(0, 0, B)
            L.set_block(B.nrows(), 0, matrix(t))
            weight = (B[-1]*B[-1]).isqrt()+1  # Norm of the largest vector
            L[-1, -1] = weight

            # The vector should be the last row but we iterate just in case
            for v in reversed(L.LLL(delta=delta, *args, **kwargs).rows()):
                if abs(v[-1]) == weight:
                    return t - v[:-1]*v[-1].sign()
            raise ValueError('No suitable vector found in basis.'
                             'This is a bug, please report it.')

        elif algorithm == 'nearest_plane':
            G = B.gram_schmidt()[0]

            b = t
            for i in reversed(range(G.nrows())):
                b -= B[i] * ((b * G[i]) / (G[i] * G[i])).round("even")
            return (t - b).change_ring(ZZ)

        elif algorithm == 'rounding_off':
            # t = x*B might not have a solution over QQ so we instead solve
            # the system x*B*B^T = t*B^T which will be the "closest" solution
            # if it does not exist, same effect as using the psuedo-inverse
            sol = (B*B.T).solve_left(t*B.T)
            return vector(ZZ, [QQ(x).round('even') for x in sol])*B

        else:
            raise ValueError("algorithm must be one of 'embedding', 'nearest_plane' or 'rounding_off'")
