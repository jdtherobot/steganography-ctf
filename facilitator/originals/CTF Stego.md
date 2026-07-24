## Challenge 1
### Title: Photo Day lvl 2

> Goal: email with OPENSSL stego .txt in jpeg, known password in e-mail body

---

### My steps

1. **Encrypt the flag** (base64 for metadata-safe text)  
    `openssl enc -aes-256-cbc -pbkdf2 -salt -k passphraseToEncrypt -a -in flagFile -out encryptedFlagOutput.enc.b64`

2. **Embed the encrypted text** into a JPEG Comment field (create a new output image)  
    `exiftool '-Comment<=encryptedFlagOutput.enc.b64' -o outputImage.jpeg inputImage.jpg`

3. **Verify the comment is present**  
    `exiftool outputImage.jpeg | grep -i comment`

---

### Player steps

1. **Standard metadata check**  
    `exiftool outputImage.jpeg'
    Comment is clearly an encrypted string
    
2. **Player recovery + decrypt** 
    `exiftool -b -Comment outputImage.jpeg > encryptedFlagOutput.enc.b64`  
    `openssl enc -aes-256-cbc -d -pbkdf2 -k passphraseUsedToEncrypt -a -in encryptedFlagOutput.enc.b64 -out flag.txt`
---

## Challenge 2
###Title: Stegosaurus 1

> Goal STEGHIDE stego .txt in jpeg, guessable password, optional brute force

---

### My steps

1. **Create an encrypted/stego JPEG**  
    `steghide embed -cf inputImage.jpg -ef fileWithFlag -sf outputImage.jpg -p passphrase`

---

### Player steps

1. **Brute force (Kali)**  
    Decompress rockyou (if needed) and write to /tmp:  
    `zcat /usr/share/wordlists/rockyou.txt.gz > /tmp/rockyou.txt`  
    Run stegcracker with that wordlist:  
    `stegcracker outputImage.jpg /tmp/rockyou.txt`

2. **Player extraction**  
   `steghide extract -sf outputImage.jpg -p passphraseFound -xf extractedFileWithFlag`

---

### Player Hints (optional)  
- HINT: WE WILL, WE WILL...
- Alt HINT: try common password lists / stego tools.
---

## Challenge 3 
###Title: Stegosaurus 2

Goal > Computer Architecture Puzzle for the real nerds.

---

###Suggested Requirement: Complete Stegosaurus 1

Exact same photo from Challenge 2 will be here.  If they completed Challenge 2, it will be easier.
### Puzzle Introduction
    MMU,
    Your TLB is empty. You must perform a PT walk to resolve a virtual address into a physical location in our memory warehouse. 
    VA = 0x0000_0100_4040_1005
    
### Admin note: 
    Player breaks up hex address into 9-bit indices and a 12-bit offset. Mask/shift works, but converting to binary first may be easiest, then you can easily break down:
    L1 > L2 > L3 > L4 > Offset
    PML4 (Page-Map Level-4) > PDPT (Page-Directory-Pointer Table) > PD (Page Directory) > PT (Page Table) > Offset
    
### Warehouse Mapping
- L1 (rows 1-10) → 99
- L2 (vertical shelf, bottom = 1 → top = 3) → 99
- L3 (horizontal section front = 1 → back = 2) → 99
- L4 (sub-section 56 apokes per grate, 2 grates for each L3. 8 sections of 7 spokes each) → 99
- Offset → box # within that L4 sub-section (page frame) → 99

###Extra Hint (Optional)
    Split the 48-bit VA into **[L1 9][L2 9][L3 9][L4 9][OFFSET 12]**
    Walk level by level (L1 → L2 → L3 → L4), then use the offset to pick the exact box. :)
    
1. **Player finds physical note**
    TL: "Honey" TR: "Badger"
    In center: "dCode □ □ □ □ "
    Below in center: "Line #9"
    BL: "Heck"  TR: "Yeah"
    
2. **In Challenge 2 Flag.txt on line #9**
    UPNAHLNSIBESOLTUEBUPDNEY
    Run through cipher to get flag for Challenge 3
---

## Challenge 4  
### Title: Stegosaurus 3

> Goal: One JPEG with multiple embedded payloads (decoys + inner image + real flag)  
> Players: binwalk → note offsets → dd carve → openssl/unzip/file → repeat

---

### My steps

1. Prepare files
   - Create flag.txt (the real flag)
   - Create secret.txt (decoy text: “better luck next time”)
   - Create do_not_open.txt (for a red-herring ZIP; contains a Four-Square decoy)
   - Create passwords.txt (lists passwords for all blobs: real and decoys)
   - Create random.bin 
     `openssl rand -out random.bin 4096`
   - Create STEGO_KEY.txt or otherwise document the key
    For my exercise, I use keyblock.txt for the exact key, and I have STEGO_KEY_368.txt as a hint for the users, the key is found inside but needs the player to solve. The player does not get keyblock.txt
   - Save helper script qtbl_stego.py (JPEG Quantization-Table stego helper)
    I use this script to embed data in the qtbl, I give a duplicate to the player named qtbl.py with the instructions removed to make it more difficult to analyze. The player does not get 'qtbl_stego.py'
   
2. Make ZIP archives
   - Zip flag.txt → payload.zip
   'zip -j payload.zip flag.txt'
   - Zip do_not_open.txt → mid.zip (leave unencrypted)
   'zip -j mid.zip do_not_open.txt'
   - Do not zip passwords.txt; we will encrypt it and zip that into a bundle later
   - We will zip secret.txt + qtbl.py + STEGO_KEY_368.txt later. (this is how players obtain the helper script and solve a small puzzle for the stego key)

3. Encrypt with OpenSSL (binary, not base64)
   - Real flag ZIP → payload.enc using a strong, non-guessable password (PASSWORD)  
    My password for this exercise is
    L35f#t8w2&(X$MK8:`SPXa=WV{F%L1G7u8@[>6yI;<N=]=e5#5
    and is saved in 'pw.txt' for ease of encrypting
   'openssl enc -aes-256-cbc -pbkdf2 -salt -pass file:./pw.txt -in payload.zip -out payload.enc'
   - Decoy ZIP (secret.zip) → secret.enc using an easy password (DECOYPASSWORD)
    My password for this exercise is
    DesertStorm#82pLm 
     `openssl enc -aes-256-cbc -pbkdf2 -salt -pass pass:DECOYPASSWORD -in secret.zip -out secret.enc`
   - Decoy random bytes (random.bin) → decoy_random.enc using an easy password (DECOYPASSWORD2)
   My password for this exercise is
   P@$$w0rd1!
     `openssl enc -aes-256-cbc -pbkdf2 -salt -pass pass:DECOYPASSWORD2 -in random.bin -out decoy_random.enc`

---

4. Create Key hidden in inner image quantization table that will be used to decrypt passwords.enc

### 1) generate a random 32-byte AES key (raw)
openssl rand -out aeskey.bin 32

### 2) embed the raw 32-byte key into the inner image (requires updated script above)
python3 qtbl_stego.py embed -i inner.jpeg -o nothingtoseehere.jpg -m aeskey.bin -k "$(cat keyblock.txt)"

### 3) create a random IV for AES-CBC (16 bytes)
openssl rand -out iv.bin 16

### 4) get hex forms for OpenSSL raw-key encryption
KEYHEX=$(xxd -p aeskey.bin | tr -d '\n')
IVHEX=$(xxd -p iv.bin | tr -d '\n')

### 4. Build the inner image
   - Hide passwords.txt inside inner.jpg using quantization-table stego with a key (STEGO_KEY) to produce nothingtoseehere.jpg  
     'python qtbl_stego.py embed -i inner.jpg -o nothingtoseehere.jpg -m passwords.txt -k "$(cat keyblock.txt)"'

### 5) encrypt passwords.txt with raw AES key (no passphrase) using AES-256-CBC and the IV
openssl enc -aes-256-cbc -in passwords.txt -out passwords.enc -K "$KEYHEX" -iv "$IVHEX"

### 6) Build the secret bundle **including** passwords.enc + secret.enc + iv.bin + qtbl.py + STEGO_KEY_368.txt
    'zip -j secret_bundle.zip qtbl.py STEGO_KEY_368.txt secret.enc passwords.enc iv.bin'

### 7) Weakly encrypt the bundle so players can crack it
openssl enc -aes-256-cbc -pbkdf2 -salt -pass pass:DesertStorm#82pLm -in secret_bundle.zip -out secret.enc

### 8) Assemble final carrier (mid.zip + secret.enc + nothingtoseehere.jpg + payload.enc + decoy_random.enc)
cat Honey_orig.jpg mid.zip secret.enc nothingtoseehere.jpg payload.enc decoy_random.enc > Honey.jpg

### 9) Quick local sanity check (optional)
   - `binwalk Honey.jpg`  
     Expect multiple offsets: OpenSSL (secret.enc), ZIP (mid.zip), JPEG (inner_decoy.jpg), OpenSSL (payload.enc), OpenSSL (decoy_random.enc)
---

### Critical Path

1. Decrypt secret.enc (easy password / brute force) → secret_bundle.zip → get qtbl.py + iv.bin

2. Carve nothingtoseehere.jpg from Honey.jpg (use the inner JPEG offset from binwalk)
    'dd if=Honey.jpg of=inner_decoy.jpg bs=1 skip=OFFSET_INNER_JPEG'

3. Use the script + STEGO_KEY to recover passwords.txt
    'python qtbl_stego.py extract -i inner_decoy.jpg -k "STEGO_KEY" -o passwords.txt'

4. Use those passwords to decrypt payload.enc → payload.zip → flag.txt
---

### Additional possible player steps



---

### Admin notes
