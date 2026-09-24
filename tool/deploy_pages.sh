#!/usr/bin/env bash
# Publica o build web na branch gh-pages (GitHub Pages servindo a branch).
# Uso: tool/deploy_pages.sh
# Alternativa: ativar o GitHub Actions no repositório e usar
# .github/workflows/deploy-pages.yml, que faz o mesmo a cada push na main.
set -euo pipefail

REPO_URL="$(git remote get-url origin)"
REPO_NAME="$(basename -s .git "$REPO_URL")"
COMMIT="$(git rev-parse --short HEAD)"

dart run build_runner build --delete-conflicting-outputs
flutter build web --release --base-href "/$REPO_NAME/"

cd build/web
cp index.html 404.html   # fallback para URLs sem '#'
touch .nojekyll
rm -rf .git
git init -q -b gh-pages
git add -A
git commit -q -m "Deploy do build web ($COMMIT)"
git push -f "$REPO_URL" gh-pages
rm -rf .git

echo "Publicado em https://$(git -C ../.. remote get-url origin | sed -E 's#.*github.com[:/]([^/]+)/.*#\1#').github.io/$REPO_NAME/"
