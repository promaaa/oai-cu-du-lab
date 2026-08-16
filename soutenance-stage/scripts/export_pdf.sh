#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root_dir="$(cd "${script_dir}/.." && pwd)"
pptx="${root_dir}/presentation/soutenance-stage-marc-duboc.pptx"
pdf="${root_dir}/presentation/soutenance-stage-marc-duboc.pdf"

if [[ ! -f "${pptx}" ]]; then
  echo "PowerPoint introuvable : ${pptx}" >&2
  exit 1
fi

soffice_bin="${SOFFICE:-}"
if [[ -z "${soffice_bin}" ]]; then
  soffice_bin="$(command -v soffice || command -v libreoffice || true)"
fi
if [[ -z "${soffice_bin}" ]]; then
  echo "LibreOffice/soffice est requis pour exporter le PDF." >&2
  exit 1
fi

export_tmp="$(mktemp -d "${TMPDIR:-/tmp}/soutenance-stage-pdf.XXXXXX")"
trap 'rm -rf "${export_tmp}"' EXIT

"${soffice_bin}" --headless --convert-to pdf --outdir "${export_tmp}" "${pptx}" >/dev/null
generated="${export_tmp}/soutenance-stage-marc-duboc.pdf"
if [[ ! -s "${generated}" ]]; then
  echo "L'export PDF n'a produit aucun fichier exploitable." >&2
  exit 1
fi
mv -f "${generated}" "${pdf}"

pages="$(pdfinfo "${pdf}" | awk '/^Pages:/ {print $2}')"
if [[ "${pages}" != "5" ]]; then
  echo "Le PDF contient ${pages:-0} pages au lieu de 5." >&2
  exit 1
fi

echo "${pdf}"
