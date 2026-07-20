#!/usr/bin/env bash
# Challenge 4 automated solver test — solves ONLY from the participant Honey.jpeg
# (the recovered bundle supplies qtbl.py etc.). Asserts the final flag.
#
# Player chain: carve -> crack secret.enc (weak 'desertstorm', in the shipped wordlist
# + rockyou) -> unzip bundle -> derive keyblock from STEGO_KEY_386.txt via the "386"
# rule (records 3,8,6) -> qtbl extract AES key -> decrypt passwords.enc (raw key+IV)
# -> try recovered passwords on payload.enc -> flag.
set -uo pipefail
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
CARRIER="$REPO_ROOT/participant/challenges/04-stegosaurus-3/Honey.jpeg"
WORK="$REPO_ROOT/build/scratch/c4/solvetest"
EXPECT='Flag{Y0u haVe EnCouNTeR3d a w!Ld s1eEP p@RA1y$!S DEm0n}'
[ -f "$CARRIER" ] || { echo "C4 FAIL: missing $CARRIER" >&2; exit 1; }
rm -rf "$WORK"; mkdir -p "$WORK"

python3 - "$CARRIER" "$WORK" "$EXPECT" <<'PY'
import sys, subprocess, os, pathlib, zipfile
carrier, work, expect = sys.argv[1], pathlib.Path(sys.argv[2]), sys.argv[3]
data = open(carrier, 'rb').read()

def find_after(hay, needle, start):
    return hay.find(needle, start)
def find_all_after(hay, needle, start):
    offs=[]; i=hay.find(needle,start)
    while i!=-1: offs.append(i); i=hay.find(needle,i+1)
    return offs

SALT=b'Salted__'; PK=b'PK\x03\x04'; SOI=b'\xff\xd8\xff'
# carve by structure, always searching *forward* from the previous component
secret_start = data.find(SALT)
mid          = find_after(data, PK, secret_start+8)          # mid.zip
inner_start  = find_after(data, SOI, mid+4)                  # inner JPEG (not the cover at 0)
salts_after_inner = find_all_after(data, SALT, inner_start)
payload_start = salts_after_inner[0]
payload_end   = salts_after_inner[1] if len(salts_after_inner) > 1 else len(data)
assert -1 not in (secret_start, mid, inner_start), "carve failed to locate a component"

(work/'secret.enc').write_bytes(data[secret_start:mid])
(work/'nothing.jpg').write_bytes(data[inner_start:payload_start])
(work/'payload.enc').write_bytes(data[payload_start:payload_end])
print(f"carved: secret.enc={mid-secret_start}B inner={payload_start-inner_start}B payload.enc={payload_end-payload_start}B")

def run(cmd): return subprocess.run(cmd, capture_output=True)

# 1) crack secret.enc — intended weak password (recoverable via the shipped wordlist/rockyou)
weak='desertstorm'
r=run(['openssl','enc','-d','-aes-256-cbc','-pbkdf2','-pass',f'pass:{weak}','-in',str(work/'secret.enc'),'-out',str(work/'bundle.zip')])
assert r.returncode==0 and zipfile.is_zipfile(work/'bundle.zip'), f"secret.enc crack failed: {r.stderr.decode()[:200]}"
with zipfile.ZipFile(work/'bundle.zip') as z: z.extractall(work/'bundle')
have=sorted(os.listdir(work/'bundle')); print("bundle:", have)
for need in ('qtbl.py','STEGO_KEY_386.txt','passwords.enc','iv.bin'):
    assert need in have, f"bundle missing {need}"

# 2) derive keyblock from STEGO_KEY_386.txt: "386" -> records 3,8,6 (24 chars each)
skt=(work/'bundle'/'STEGO_KEY_386.txt').read_bytes().rstrip(b'\n')
recs=[skt[i*24:(i+1)*24] for i in range(len(skt)//24)]
keyblock=(recs[2]+recs[7]+recs[5]).decode()

# 3) extract the raw AES key from the inner JPEG's quantization tables
r=run(['python3',str(work/'bundle'/'qtbl.py'),'extract','-i',str(work/'nothing.jpg'),'-o',str(work/'aeskey.bin'),'-k',keyblock])
assert r.returncode==0 and (work/'aeskey.bin').exists() and (work/'aeskey.bin').stat().st_size==32, \
    f"qtbl extract failed: {r.stdout.decode()} {r.stderr.decode()}"

# 4) decrypt passwords.enc with raw key + IV (no pbkdf2)
keyhex=(work/'aeskey.bin').read_bytes().hex()
ivhex=(work/'bundle'/'iv.bin').read_bytes().hex()
r=run(['openssl','enc','-d','-aes-256-cbc','-in',str(work/'bundle'/'passwords.enc'),'-out',str(work/'passwords.txt'),'-K',keyhex,'-iv',ivhex])
assert r.returncode==0, f"passwords.enc decrypt failed: {r.stderr.decode()[:200]}"
pwtxt=(work/'passwords.txt').read_text(errors='replace')

# 5) try each recovered password against payload.enc
cands=[];
for line in pwtxt.splitlines():
    s=line.strip()
    if s: cands.append(s)
    cands += [t for t in s.split() if t]
flag=None; seen=set()
for c in cands:
    if c in seen: continue
    seen.add(c)
    r=run(['openssl','enc','-d','-aes-256-cbc','-pbkdf2','-pass',f'pass:{c}','-in',str(work/'payload.enc'),'-out',str(work/'payload.zip')])
    if r.returncode!=0 or not zipfile.is_zipfile(work/'payload.zip'): continue
    with zipfile.ZipFile(work/'payload.zip') as z:
        for n in z.namelist():
            if n.endswith('flag.txt'): flag=z.read(n).decode(errors='replace').strip()
    if flag: break
assert flag is not None, "no recovered password decrypted payload.enc to a flag"
print("recovered flag:", flag)
assert flag==expect, f"flag mismatch:\n got {flag!r}\n exp {expect!r}"
print("C4 PASS")
PY
rc=$?
[ $rc -eq 0 ] && echo "C4 solve_test: OK" || echo "C4 solve_test: FAILED (rc=$rc)"
exit $rc
