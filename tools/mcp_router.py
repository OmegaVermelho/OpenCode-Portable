#!/usr/bin/env python3
import argparse
import hashlib
import os
import sys
from pathlib import Path

try:
    from cryptography.hazmat.primitives.ciphers.aead import AESGCM
    HAS_CRYPTOGRAPHY = True
except Exception:
    HAS_CRYPTOGRAPHY = False


def derive_key(password: str, salt: bytes) -> bytes:
    return hashlib.pbkdf2_hmac("sha256", password.encode("utf-8"), salt, 200_000, dklen=32)


def encrypt_file(input_path: str, output_path: str, password: str):
    if not HAS_CRYPTOGRAPHY:
        raise RuntimeError("PyCryptodome/cryptography is required. Install: pip install cryptography")

    data = Path(input_path).read_bytes()
    salt = os.urandom(16)
    nonce = os.urandom(12)
    key = derive_key(password, salt)
    ciphertext = AESGCM(key).encrypt(nonce, data, None)
    payload = salt + nonce + ciphertext
    out = Path(output_path)
    out.write_bytes(payload)
    try:
        os.chmod(output_path, 0o600)
    except Exception:
        pass


def decrypt_file(input_path: str, output_path: str, password: str):
    if not HAS_CRYPTOGRAPHY:
        raise RuntimeError("PyCryptodome/cryptography is required. Install: pip install cryptography")

    blob = Path(input_path).read_bytes()
    if len(blob) < 28:
        raise ValueError("Arquivo cifrado inválido ou corrompido.")

    salt = blob[:16]
    nonce = blob[16:28]
    encrypted = blob[28:]
    key = derive_key(password, salt)
    plain = AESGCM(key).decrypt(nonce, encrypted, None)
    Path(output_path).write_bytes(plain)
    try:
        os.chmod(output_path, 0o600)
    except Exception:
        pass


def main():
    parser = argparse.ArgumentParser(description="Encrypt/decrypt settings file using AES-256 with PBKDF2")
    parser.add_argument("--encrypt", action="store_true")
    parser.add_argument("--decrypt", action="store_true")
    parser.add_argument("--input", required=True)
    parser.add_argument("--output", required=True)
    parser.add_argument("--password", required=True)
    args = parser.parse_args()

    if args.encrypt and args.decrypt:
        parser.error("Escolha apenas uma operação: --encrypt ou --decrypt")
    if not args.encrypt and not args.decrypt:
        parser.error("Informe --encrypt ou --decrypt")

    try:
        if args.encrypt:
            encrypt_file(args.input, args.output, args.password)
        else:
            decrypt_file(args.input, args.output, args.password)
    except Exception as exc:
        print(f"[ERROR] {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
