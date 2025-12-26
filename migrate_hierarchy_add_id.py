#!/usr/bin/env python3
"""
Generate node IDs from name for each node and store in 'id' field.

Requirements:
    pip install firebase-admin

Usage:
    1. Put your Firebase service account JSON file somewhere accessible
    2. Update SERVICE_ACCOUNT_KEY_PATH and TENANT_ID below
    3. Run: python migrate_generate_node_ids_from_name.py
"""

import time
import firebase_admin
from firebase_admin import credentials, firestore

# ----------------------------------------------------------------------
# CONFIG - CHANGE THESE
# ----------------------------------------------------------------------
SERVICE_ACCOUNT_KEY_PATH = "build\wall-d-fcc76-firebase-adminsdk-fbsvc-d296f34e23.json"  # TODO: change
TENANT_ID = "default_tenant"  # TODO: change if needed

# Firestore collection path
COLLECTION_PATH = f"tenants/{TENANT_ID}/organizations/hierarchy/nodes"


def generate_id_from_name(raw_name: str) -> str:
    """
    Python equivalent of your Dart _generateIdFromName:

      1. lowercase
      2. only letters / digits / space / - / _
      3. spaces and - to _
    """
    lower = raw_name.lower()
    buffer = []

    for ch in lower:
        code = ord(ch)
        is_alpha_num = (97 <= code <= 122) or (48 <= code <= 57)  # a-z, 0-9
        if is_alpha_num:
            buffer.append(ch)
        elif ch in [" ", "-", "_"]:
            buffer.append("_")
        # other characters are skipped

    id_val = "".join(buffer)

    # collapse multiple underscores (RegExp('_+') equivalent)
    while "__" in id_val:
        id_val = id_val.replace("__", "_")

    id_val = id_val.strip()

    if id_val.startswith("_"):
        id_val = id_val[1:]
    if id_val.endswith("_"):
        id_val = id_val[:-1]

    if not id_val:
        # same idea as node_${DateTime.now().millisecondsSinceEpoch}
        id_val = f"node_{int(time.time() * 1000)}"

    return id_val


def main():
    print("Connecting to Firestore...")
    cred = credentials.Certificate(SERVICE_ACCOUNT_KEY_PATH)
    firebase_admin.initialize_app(cred)
    db = firestore.client()

    coll = db.collection(COLLECTION_PATH)
    docs = list(coll.stream())
    print(f"Found {len(docs)} nodes in {COLLECTION_PATH}")

    if not docs:
        print("No nodes to update.")
        return

    confirm = input("This will update the 'id' field for ALL nodes. Continue? (yes/no): ").strip().lower()
    if confirm != "yes":
        print("Aborted.")
        return

    batch = db.batch()
    batch_ops = 0
    updated = 0

    for i, doc in enumerate(docs, 1):
        data = doc.to_dict() or {}
        name = data.get("name") or doc.id

        new_id = generate_id_from_name(name)

        # Update only the 'id' field in the document data (doc ID stays same)
        batch.update(doc.reference, {"id": new_id})
        batch_ops += 1
        updated += 1

        print(f"[{i}/{len(docs)}] name='{name}' -> id='{new_id}' (docId: {doc.id})")

        # Commit batch every 400 operations for safety
        if batch_ops >= 400:
            batch.commit()
            print("Committed batch of 400 operations")
            batch = db.batch()
            batch_ops = 0

    if batch_ops > 0:
        batch.commit()
        print("Committed final batch")

    print(f"Done. Updated 'id' field for {updated} nodes.")


if __name__ == "__main__":
    main()
