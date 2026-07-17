#!/usr/bin/env python3
import argparse
import sys
import os

sys.path.insert(0, '/code')

try:
    from marzban import models
    from marzban.db import get_db
    from datetime import datetime
    import hashlib
except ImportError as e:
    print(f"Error: {e}")
    sys.exit(1)

def create_admin(username, password, sudo=False):
    try:
        db = next(get_db())
        existing = db.query(models.Admin).filter(models.Admin.username == username).first()
        if existing:
            print(f"Admin '{username}' already exists")
            return True
        
        hashed = hashlib.sha256(password.encode()).hexdigest()
        admin = models.Admin(
            username=username,
            hashed_password=hashed,
            is_sudo=sudo,
            created_at=datetime.now()
        )
        db.add(admin)
        db.commit()
        print(f"✅ Admin '{username}' created (sudo: {sudo})")
        return True
    except Exception as e:
        print(f"❌ Error: {e}")
        return False

if name == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument('--username', required=True)
    parser.add_argument('--password', required=True)
    parser.add_argument('--sudo', action='store_true')
    args = parser.parse_args()
    success = create_admin(args.username, args.password, args.sudo)
    sys.exit(0 if success else 1)
