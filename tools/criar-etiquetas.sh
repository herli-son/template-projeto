#!/usr/bin/env bash
# Cria no repositório as etiquetas que as regras usam (o GitHub não copia
# etiquetas de um template). Precisa do gh autenticado:
#   tools/criar-etiquetas.sh            (no repositório atual)
#   tools/criar-etiquetas.sh dono/repo
repo=()
[[ -n "${1:-}" ]] && repo=(--repo "$1")

criar() { gh label create "$1" --color "$2" --description "$3" --force "${repo[@]}"; }

criar "feature" "1d76db" "Conjunto de User Stories"
criar "user story" "0e8a16" "Entrega dentro de uma Feature"
criar "bug" "d73a4a" "Algo que não funciona como deveria"
criar "aguardando publicação" "fbca04" "Pronta na develop ou numa beta; fecha quando o código chegar na main"
