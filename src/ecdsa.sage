import collections
import hashlib as hasl
import random as rd

try:
    load("src/shared_functions.sage")
except:
    load("../shared_functions.sage")


# source: https://github.com/andreacorbellini/ecc/blob/master/scripts/ecdsa.py

EllipticCurve = collections.namedtuple('EllipticCurve', 'name p a b g n h')

curve = EllipticCurve(
    'P-256',
    # Field characteristic.
    p=0xffffffff00000001000000000000000000000000ffffffffffffffffffffffff,
    # 2^256 − 2^224 + 2^192 + 2^96 − 1
    # Curve coefficients.
    a=0xffffffff00000001000000000000000000000000fffffffffffffffffffffffc, # p - 3
    b=0x5ac635d8aa3a93e7b3ebbd55769886bc651d06b0cc53b0f63bce3c3e27d2604b,
    # Base point.
    g=(0x6b17d1f2e12c4247f8bce6e563a440f277037d812deb33a0f4a13945d898c296, # Gx
       0x4fe342e2fe1a7f9b8ee7eb4a7c0f9e162bce33576b315ececbb6406837bf51f5), # Gy
    # Subgroup order.
    n=0xffffffff00000000ffffffffffffffffbce6faada7179e84f3b9cac2fc632551,
    # Subgroup cofactor.
    h=1,
)

# curve = EllipticCurve(
#     'secp256k1',
#     # Field characteristic.
#     p=0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffefffffc2f,
#     # Curve coefficients.
#     a=0,
#     b=7,
#     # Base point.
#     g=(0x79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798,
#        0x483ada7726a3c4655da4fbfc0e1108a8fd17b448a68554199c47d08ffb10d4b8),
#     # Subgroup order.
#     n=0xfffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141,
#     # Subgroup cofactor.
#     h=1,
# )

# Modular arithmetic ##########################################################

def inverse_mod(k, p):
    """Returns the inverse of k modulo p.
    This function returns the only integer x such that (x * k) % p == 1.
    k must be non-zero and p must be a prime.
    """
    if k == 0:
        raise ZeroDivisionError('division by zero')

    if k < 0:
        # k ** -1 = p - (-k) ** -1  (mod p)
        return p - inverse_mod(-k, p)

    # Extended Euclidean algorithm.
    s, old_s = 0, 1
    t, old_t = 1, 0
    r, old_r = p, k

    while r != 0:
        quotient = old_r // r
        old_r, r = r, old_r - quotient * r
        old_s, s = s, old_s - quotient * s
        old_t, t = t, old_t - quotient * t

    gcd, x, y = old_r, old_s, old_t

    assert gcd == 1
    assert (k * x) % p == 1

    return x % p


# Functions that work on curve points #########################################

def is_on_curve(point):
    """Returns True if the given point lies on the elliptic curve."""
    if point is None:
        # None represents the point at infinity.
        return True

    x, y = point

    return (y * y - x * x * x - curve.a * x - curve.b) % curve.p == 0


def point_neg(point):
    """Returns -point."""
    assert is_on_curve(point)

    if point is None:
        # -0 = 0
        return None

    x, y = point
    result = (x, -y % curve.p)

    assert is_on_curve(result)

    return result


def point_add(point1, point2):
    """Returns the result of point1 + point2 according to the group law."""
    assert is_on_curve(point1)
    assert is_on_curve(point2)

    if point1 is None:
        # 0 + point2 = point2
        return point2
    if point2 is None:
        # point1 + 0 = point1
        return point1

    x1, y1 = point1
    x2, y2 = point2

    if x1 == x2 and y1 != y2:
        # point1 + (-point1) = 0
        return None

    if x1 == x2:
        # This is the case point1 == point2.
        m = (3 * x1 * x1 + curve.a) * inverse_mod(2 * y1, curve.p)
    else:
        # This is the case point1 != point2.
        m = (y1 - y2) * inverse_mod(x1 - x2, curve.p)

    x3 = m * m - x1 - x2
    y3 = y1 + m * (x3 - x1)
    result = (x3 % curve.p,
              -y3 % curve.p)

    assert is_on_curve(result)

    return result


def scalar_mult(k, point):
    """Returns k * point computed using the double and point_add algorithm."""
    assert is_on_curve(point)

    if k % curve.n == 0 or point is None:
        return None

    if k < 0:
        # k * point = -k * (-point)
        return scalar_mult(-k, point_neg(point))

    result = None
    addend = point

    while k:
        if k & 1:
            # Add.
            result = point_add(result, addend)

        # Double.
        addend = point_add(addend, addend)

        k >>= 1

    assert is_on_curve(result)

    return result


# Keypair generation and ECDSA ################################################

def make_keypair():
    """Generates a random private-public key pair."""
    private_key = rd.randrange(1, curve.n)
    public_key = scalar_mult(private_key, curve.g)

    return private_key, public_key


def hash_message(message):
    """Returns the truncated SHA512 hash of the message."""
    message_hash = hasl.sha512(message).digest()
    e = int.from_bytes(message_hash, 'big')

    # FIPS 180 says that when a hash needs to be truncated, the rightmost bits
    # should be discarded.
    z = e >> (e.bit_length() - int(curve.n).bit_length())

    assert z.bit_length() <= int(curve.n).bit_length()

    return z


def sign_message(private_key, message, ephem_key):
    z = hash_message(message)

    r = 0
    s = 0

    while not r or not s:
        # k = rd.randrange(1, curve.n)
        k = ephem_key
        x, y = scalar_mult(k, curve.g)

        r = x % curve.n
        s = ((z + r * private_key) * inverse_mod(k, curve.n)) % curve.n

    return (r, s)

def verify_signature(public_key, message, signature):
    z = hash_message(message)

    r, s = signature

    w = inverse_mod(s, curve.n)
    u1 = (z * w) % curve.n
    u2 = (r * w) % curve.n

    x, y = point_add(scalar_mult(u1, curve.g),
                     scalar_mult(u2, public_key))

    # if (r % curve.n) == (x % curve.n):
    #     return 'signature matches'
    # else:
    #     return 'invalid signature'
    return ((r % curve.n) == (x % curve.n))


def data_gen_ecdsa(n, epsilon, Zq, private_key) :
    """
    similaire à data_gen de la première implem mais adaptée aux données de ECDSA
    les clés éphémères sont appelées ki cette fois
    """
    ephemeral_keys = []
    equations = []
    part_known = []

    for i in range(n) :  
        mi = Zq.random_element()
        ki = Zq.random_element()
        ephemeral_keys.append(ki)
        m_byte_size = (int(mi).bit_length() + 7) // 8
        m_byte = int(mi).to_bytes(m_byte_size, 'big')
        ri,si = sign_message(private_key, m_byte, int(ki))
        ri = Zq(ri) ; si = Zq(si)
        hm = Zq(hash_message(m_byte)) 
        zi_prime,zi, zi_2prime, lambda_i, mu_i = hide_contiguous(ki,epsilon, Zq.order())
        part_known.append((zi_prime, lambda_i, zi_2prime, mu_i))

        equations.append([si,si**(-1),hm,ri,zi_prime,zi, zi_2prime, lambda_i, mu_i])
    
    return equations,ephemeral_keys,part_known

def rearrange_equations_ecdsa(equations,Zq) :
    """
    même fonction que pour dsa99 mais 
    """
    nb_sign = len(equations)
    for a in range(nb_sign):
        si,si_inv,hm,ri,zi_prime,zi, zi_2prime, lambda_i, mu_i = equations[a]
        # change to fit dsa attack :
        bi_inverse = si_inv
        fi = ri
        m = hm
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
    
    # construction des Zi, si, ti
    for index in range(n):
        Ci, Di, zi_prime, zi_2prime, lambda_i, mu_i = equations[index]
        exposant = Zq(2)^(-lambda_i)
        #               zi   + z_h*si      + ti
        equations[index] = [exposant*Ci*2^(lambda_h), exposant * (Ci*(zh_prime + 2**mu_h * zh_2prime)+zi_prime+Di+zi_2prime*2**mu_i) ]

    return equations


# C'est la même, j'ai juste changé les arguments pour avoir q
def matrix_from_equations_ecdsa(equations,Zq) :
    q = Zq.order()
    n = len(equations)
    A = Matrix(ZZ,n+1,n+1)
    A[0,0] = ZZ(-1)
    for index in range(n):
        A[0,index+1] = ZZ(equations[index][0])
        A[index+1,index+1] = ZZ(q)
    return A




demo = False
if demo:
    print('Curve:', curve.name)

    private, public = make_keypair()
    print("Private key:", hex(private))
    print("Public key: (0x{:x}, 0x{:x})".format(*public))

    msg = b'Hello!'
    signature = sign_message(private, msg)

    print()
    print('Message:', msg)
    print('Signature: (0x{:x}, 0x{:x})'.format(*signature))
    print('Verification:', verify_signature(public, msg, signature))

    msg = b'Hi there!'
    print()
    print('Message:', msg)
    print('Verification:', verify_signature(public, msg, signature))

    private, public = make_keypair()

    msg = b'Hello!'
    print()
    print('Message:', msg)
    print("Public key: (0x{:x}, 0x{:x})".format(*public))
    print('Verification:', verify_signature(public, msg, signature))
