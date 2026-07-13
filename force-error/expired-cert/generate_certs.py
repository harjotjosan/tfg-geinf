import datetime
from cryptography import x509
from cryptography.x509.oid import NameOID
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.asymmetric import rsa
from cryptography.hazmat.primitives import serialization
import ipaddress
import os

def generate_cert(cert_path, key_path, valid_days, expired=False):
    # Generate private key
    private_key = rsa.generate_private_key(
        public_exponent=65537,
        key_size=2048,
    )

    # Subject and Issuer are the same for self-signed
    subject = issuer = x509.Name([
        x509.NameAttribute(NameOID.COMMON_NAME, "carparts-proxy"),
    ])

    now = datetime.datetime.now(datetime.timezone.utc)
    if expired:
        # Validity is in the past: from 366 days ago to 1 day ago
        not_before = now - datetime.timedelta(days=366)
        not_after = now - datetime.timedelta(days=1)
    else:
        # Valid starting 1 day ago (to avoid any time synchronization edge cases) for 365 days
        not_before = now - datetime.timedelta(days=1)
        not_after = now + datetime.timedelta(days=valid_days)

    builder = x509.CertificateBuilder()
    builder = builder.subject_name(subject)
    builder = builder.issuer_name(issuer)
    builder = builder.public_key(private_key.public_key())
    builder = builder.serial_number(x509.random_serial_number())
    builder = builder.not_valid_before(not_before)
    builder = builder.not_valid_after(not_after)

    # Add Subject Alternative Names (SANs)
    sans = [
        x509.DNSName("carparts-proxy"),
        x509.DNSName("localhost"),
        x509.IPAddress(ipaddress.ip_address("10.0.27.228")),
        x509.IPAddress(ipaddress.ip_address("127.0.0.1")),
    ]
    builder = builder.add_extension(
        x509.SubjectAlternativeName(sans),
        critical=False,
    )

    # Self-sign
    cert = builder.sign(private_key, hashes.SHA256())

    # Write private key
    with open(key_path, "wb") as f:
        f.write(private_key.private_bytes(
            encoding=serialization.Encoding.PEM,
            format=serialization.PrivateFormat.TraditionalOpenSSL,
            encryption_algorithm=serialization.NoEncryption()
        ))

    # Write certificate
    with open(cert_path, "wb") as f:
        f.write(cert.public_bytes(serialization.Encoding.PEM))

if __name__ == "__main__":
    script_dir = os.path.dirname(os.path.abspath(__file__))
    certs_dir = os.path.join(script_dir, "certs")
    os.makedirs(certs_dir, exist_ok=True)
    
    generate_cert(
        os.path.join(certs_dir, "valid.crt"),
        os.path.join(certs_dir, "valid.key"),
        365,
        expired=False
    )
    print("Generated valid.crt/key")
    
    generate_cert(
        os.path.join(certs_dir, "expired.crt"),
        os.path.join(certs_dir, "expired.key"),
        365,
        expired=True
    )
    print("Generated expired.crt/key")
