try:
    from Cryptodome.Hash import SHA256
    from Cryptodome.PublicKey import ECC
    from Cryptodome.Signature import DSS
except:
    from Crypto.Hash import SHA256
    from Crypto.PublicKey import ECC
    from Crypto.Signature import DSS
import unittest

class TestECDSA(unittest.TestCase):

    def test_msg_digest_differs(self):
        self.assertNotEqual(msg_bad_digest, msg_sent_digest, "ECDSA digest should differ")

    def test_msg_sign_differs(self):
        bad_digest_sign = signer.sign(msg_bad_digest)
        self.assertNotEqual(bad_digest_sign, digest_sign, "ECDSA sign should differ")

    def test_valid_verify(self):
        try:
            verifier.verify(msg_sent_digest, digest_sign)
        except ValueError:
            self.fail("The message is authentic, verify should work.")
        else:
            print("Verify worked correctly", end=' ', flush=True)

    def test_verify_bad_digest(self):
        with self.assertRaises(ValueError):
            verifier.verify(msg_bad_digest, digest_sign)

    def test_verify_bad_sign(self):
        bad_digest_sign = signer.sign(msg_bad_digest)
        with self.assertRaises(ValueError):
            verifier.verify(msg_sent_digest, bad_digest_sign)

if __name__ == '__main__':
    priv_key = ECC.import_key(open('test_keys/private_key.pem').read())
    pub_key = ECC.import_key(open('test_keys/public_key.pem').read())

    msg_sent = b'I give my permission to eat some pasta'
    msg_rec_bad = b'I give my permission to eat ariel pods'
    msg_rec_nice = msg_sent

    msg_sent_digest = SHA256.new(msg_sent)
    msg_bad_digest = SHA256.new(msg_rec_bad)

    signer = DSS.new(priv_key, 'fips-186-3')
    digest_sign = signer.sign(msg_sent_digest)

    verifier = DSS.new(pub_key, 'fips-186-3')

    unittest.main(verbosity=3)