try:
    from Cryptodome.Cipher import AES 
    from Cryptodome.Util.Padding import pad, unpad
except:
    from Crypto.Cipher import AES 
    from Crypto.Util.Padding import pad, unpad
import os
import unittest

BLOC = 16

def padMessage(plaintext, size):
    padLen = (size - (len(plaintext) % size))
    #print(padLen)
    textByteArray = bytearray(plaintext)
    #print(textByteArray)
    for i in range(padLen):
        textByteArray.append(padLen)
    return bytes(textByteArray)

def aes_cbc_encrypt(plaintext, keyabc, iv):
    padded = padMessage(plaintext, BLOC)
    cipher = AES.new(keyabc, AES.MODE_CBC, IV=iv)
    ciphertext = cipher.encrypt(padded)
    return ciphertext

def aes_cbc_decrypt(ciphertext, keyabc, iv):
    cipher = AES.new(keyabc, AES.MODE_CBC, IV=iv)
    (paddedtext) = cipher.decrypt(ciphertext)
    plaintext = unpad(paddedtext, BLOC, style='pkcs7')
    return plaintext

class TestAESCBC(unittest.TestCase):

    def test_cypher_decypher_hello(self):
        ciphertext = aes_cbc_encrypt(plaintext, keyabc, IV)
        decrypted = aes_cbc_decrypt(ciphertext, keyabc, IV)
        self.assertEqual(plaintext, decrypted, "AES CBC encrypt then decrypt differs from original plaintext")

    def test_chiff_key_change_hello(self):
        ciphertext = aes_cbc_encrypt(plaintext, keyabc, IV)
        ciphertext_bis = aes_cbc_encrypt(plaintext, keyqrs, IV)
        self.assertNotEqual(ciphertext, ciphertext_bis, "Ciphertexts should be different")

    def test_cypher_decypher_random(self):
        randomtext = os.urandom(BLOC)
        ciphertext = aes_cbc_encrypt(randomtext, keyabc, IV)
        decrypted = aes_cbc_decrypt(ciphertext, keyabc, IV)
        self.assertEqual(randomtext, decrypted, "AES CBC encrypt then decrypt not reversed correctly")

    def test_chiff_key_change_random(self):
        randomtext = os.urandom(BLOC)
        ciphertext = aes_cbc_encrypt(randomtext, keyabc, IV)
        ciphertext_bis = aes_cbc_encrypt(randomtext, keyqrs, IV)
        self.assertNotEqual(ciphertext, ciphertext_bis, "Ciphertexts should be different")

if __name__ == '__main__':
    plaintext = b'hello world!'
    keyabc = b'abcdefghijklmnop'
    keyqrs = b'qrstuvwxyz000000'
    IV = os.urandom(BLOC)
    unittest.main(verbosity=3)
