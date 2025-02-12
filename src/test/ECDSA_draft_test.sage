import unittest
load("../ecdsa.sage")

class TestP256(unittest.TestCase):

    def test_verify_sign_hello(self):
        priv_key, pub_key = make_keypair()
        sign_hello = sign_message(priv_key, hello_msg)
        
        self.assertTrue(verify_signature(pub_key, hello_msg, sign_hello), hello_msg.decode() + " signature verify failed")

    def test_verify_sign_coffee(self):
        priv_key, pub_key = make_keypair()
        sign_coffee = sign_message(priv_key, coffee_msg)
        
        self.assertTrue(verify_signature(pub_key, coffee_msg, sign_coffee), coffee_msg.decode() + " signature verify failed")

    def test_wrong_sign_coffee_verify_hello(self):
        priv_key, pub_key = make_keypair()
        sign_coffee = sign_message(priv_key, coffee_msg)
        
        self.assertFalse(verify_signature(pub_key, hello_msg, sign_coffee), coffee_msg.decode() + " signature verify should have failed")
  

if __name__ == '__main__':
    
    hello_msg = b'Hello!'
    coffee_msg = b'I need some coffee'

    unittest.main(verbosity=3)
