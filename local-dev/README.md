# Local MySQL (`mysql.db.local`)

Docker MySQL on your **host**, reachable from Minikube pods as **`mysql.db.local`**.

## Setup

```bash
cp .env.example .env          # optional: customize passwords
chmod +x scripts/setup-local-mysql.sh
./scripts/setup-local-mysql.sh
```

Then redeploy dev services:

```bash
kubectl apply -k user-service/overlays/dev
kubectl apply -k product-service/overlays/dev
```

## Hostnames

| Client | Host | Port |
|--------|------|------|
| Your laptop (mysql client, IDE) | `mysql.db.local` or `127.0.0.1` | 3306 |
| Pods (`user-service`, `product-service`) | `mysql.db.local` | 3306 |
| Pods (default `DB_HOST=mysql`) | `mysql` Service → host gateway | 3306 |

## Credentials (default)

- Database: `appdb`
- User: `user` / `password`
- Root: `root` / `rootpassword`

## Notes

- `hotel-app` still has in-cluster MySQL; use `mysql.db.local` only for services patched in dev overlays.
- If Minikube IP changes, re-run `./scripts/setup-local-mysql.sh`.
