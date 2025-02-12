import unittest
load("../impl_99.sage")


class TestDSA(unittest.TestCase):

  # set up, tear down to randomize priv key

    def test_contiguous_epsilon_0_50(self):
        epsilon = 0.50
        equations, ephemeral_keys, known_parts = data_gen(n+1, epsilon, Zq,g, x)
        equations = rearrange_equations(equations,n+1)
        A = matrix_from_equations(equations,n)
        Z = attack(A, equations)
        zi_prime, lambda_i, zi_2prime, mu_i = known_parts[index]
        z0_found = zi_prime + Z[index+1]*2**lambda_i + zi_2prime*2**mu_i
        actual_z0 = ZZ(ephemeral_keys[index])
        self.assertEqual(z0_found, actual_z0, "Wrong value, ephemeral key not recovered")

    def test_contiguous_epsilon_0_25(self):
        epsilon = 0.25
        equations, ephemeral_keys, known_parts = data_gen(n+1,epsilon, Zq,g, x)
        equations = rearrange_equations(equations,n+1)
        A = matrix_from_equations(equations,n)
        Z = attack(A, equations)
        zi_prime, lambda_i, zi_2prime, mu_i = known_parts[index]
        z0_found = zi_prime + Z[index+1]*2**lambda_i + zi_2prime*2**mu_i
        actual_z0 = ZZ(ephemeral_keys[index])
        self.assertEqual(z0_found, actual_z0, "Wrong value, ephemeral key not recovered")

    # def test_contiguous_epsilon_0_20(self): #fails
    #     epsilon = 0.20
    #     equations, ephemeral_keys, known_parts = data_gen(n+1, epsilon)
    #     equations = rearrange_equations(equations,n+1)
    #     A = matrix_from_equations(equations,n)
    #     Z = attack(A, equations)
    #     offset = ZZ(160*epsilon)
    #     z0_found = Z[index+1]*2^offset + known_parts[index]
    #     actual_z0 = ZZ(ephemeral_keys[index])
    #     self.assertEqual(z0_found, actual_z0, "Wrong value, ephemeral key not recovered")
  

if __name__ == '__main__':
    p = 906451402757531491528347543991965234378604973129269705492472129523782487766614021889227442682267886074307292927204600169914974164281891819286851424239355717753220030403878552060160148901948842626145985604965725925995708353545622337042837155897328722293454170436280382414179204815920139165021038274214324133441128748041485323750264965207
    q = 1059913563491035635396448336427206671662765775323
    Zp = GF(p)
    Zq = GF(q)
    g = 293371185853534367511844757434644570812647513218435580316069229785172955124429736895770945422242233686785606862787032030077878386643174691259013000164799577907874573865328598727158515510280793452269117630500180299498233510391795063046406707109176370083243422230003054010329258322170583298853051287181677571803798228224133321144496297461
    g = Zp(g)
    x = Zq(1234567890987654321)
    h = g ** x
    n = 4
    index = 0 # index de la clé éphémère testée

    unittest.main(verbosity=3)
