import unittest

load("../impl_99.sage")
load("../shared_functions.sage")
load("../ecdsa.sage")

class TestP256(unittest.TestCase):

    def test_attack_default(self):
        Z = attack(A, equations)

        zi_prime, lambda_i, zi_2prime, mu_i = known_parts[index]
        z1_found = reconstruct(Z[index+1],zi_prime, zi_2prime, lambda_i, mu_i)
        actual_z1 = ZZ(ephemeral_keys[index])
        z1_prime, lambda_1, z1_2prime, mu_1 = known_parts[0]
        hidden_z1 = z1_prime + 2^(mu_1)*z1_2prime
        
        private_key_found = (Zq(z1_found) - hm1*s1_inv) * s1 * r1^(-1)
        self.assertEqual(private_key, private_key_found, "Bad key recovered")


    def test_attack_nearest_plane(self):
        Z = attack(A, equations,algo_babai='nearest_plane')

        zi_prime, lambda_i, zi_2prime, mu_i = known_parts[index]
        z1_found = reconstruct(Z[index+1],zi_prime, zi_2prime, lambda_i, mu_i)
        actual_z1 = ZZ(ephemeral_keys[index])
        z1_prime, lambda_1, z1_2prime, mu_1 = known_parts[0]
        hidden_z1 = z1_prime + 2^(mu_1)*z1_2prime
        
        private_key_found = (Zq(z1_found) - hm1*s1_inv) * s1 * r1^(-1)
        self.assertEqual(private_key, private_key_found, "Bad key recovered")


    def test_attack_round_off(self):
        Z = attack(A, equations,algo_babai='rounding_off')

        zi_prime, lambda_i, zi_2prime, mu_i = known_parts[index]
        z1_found = reconstruct(Z[index+1],zi_prime, zi_2prime, lambda_i, mu_i)
        actual_z1 = ZZ(ephemeral_keys[index])
        z1_prime, lambda_1, z1_2prime, mu_1 = known_parts[0]
        hidden_z1 = z1_prime + 2^(mu_1)*z1_2prime
        
        private_key_found = (Zq(z1_found) - hm1*s1_inv) * s1 * r1^(-1)
        self.assertEqual(private_key, private_key_found, "Bad key recovered")


if __name__ == '__main__':
    
    nb_signatures = 11
    n = nb_signatures - 1
    epsilon = 0.1

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

    

    unittest.main(verbosity=3)
