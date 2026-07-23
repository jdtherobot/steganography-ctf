# Stego CTF — build & validation harness.
# Every recipe reads the immutable archive via ARCHIVE_DIR and writes only into the repo.
SHELL := /bin/bash
ARCHIVE_DIR ?= /Users/jdtherobot/Documents/GitHub/CTF Challenges/archive
export ARCHIVE_DIR

CHALLENGES := 01-photo-day 02-stegosaurus-1 03-stegosaurus-2-warehouse 04-stegosaurus-3

.PHONY: help inventory build-challenges test-challenges \
        scan-secrets verify-archive all clean

help:
	@echo "Stego CTF targets:"
	@echo "  make inventory         regenerate the archive SHA-256 inventory + fingerprint"
	@echo "  make build-challenges  run every facilitator/challenges/NN/rebuild.sh"
	@echo "  make test-challenges   run every facilitator/challenges/NN/solve_test.sh (asserts flags)"
	@echo "  make scan-secrets      PRE-PUBLISH GATE: prove no secret leaks into participant/"
	@echo "  make verify-archive    confirm the archive fingerprint is unchanged"
	@echo "  make all               build-challenges + test-challenges + scan-secrets + verify-archive"

inventory:
	@python3 build/inventory/make_inventory.py

build-challenges:
	@for c in $(CHALLENGES); do \
	  s="facilitator/challenges/$$c/rebuild.sh"; \
	  if [ -f "$$s" ]; then echo "== rebuild $$c =="; bash "$$s" || exit 1; \
	  else echo "-- skip $$c (no rebuild.sh yet) --"; fi; \
	done

test-challenges:
	@rc=0; for c in $(CHALLENGES); do \
	  s="facilitator/challenges/$$c/solve_test.sh"; \
	  if [ -f "$$s" ]; then echo "== test $$c =="; bash "$$s" || rc=1; \
	  else echo "-- skip $$c (no solve_test.sh yet) --"; fi; \
	done; exit $$rc

scan-secrets:
	@bash build/secret-scan/scan.sh

verify-archive:
	@baseline="build/inventory/archive_inventory.sha256"; \
	if [ ! -f "$$baseline" ]; then echo "no baseline fingerprint; run 'make inventory' first" >&2; exit 1; fi; \
	tmp="$$(mktemp -d)"; \
	python3 build/inventory/make_inventory.py "$$tmp" >/dev/null; \
	if diff -q "$$baseline" "$$tmp/archive_inventory.sha256" >/dev/null; then \
	  echo "verify-archive: PASS — fingerprint unchanged ($$(cat "$$baseline"))"; rc=0; \
	else \
	  echo "verify-archive: FAIL — archive fingerprint changed!"; \
	  echo "  baseline: $$(cat "$$baseline")"; echo "  now:      $$(cat "$$tmp/archive_inventory.sha256")"; rc=1; \
	fi; rm -rf "$$tmp"; exit $$rc

all: build-challenges test-challenges scan-secrets verify-archive

clean:
	@rm -rf build/scratch/* build/out/* 2>/dev/null; echo "cleaned build scratch/out"
