import fs from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { Presentation, PresentationFile } from "@oai/artifact-tool";

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(process.env.SOUTENANCE_ROOT || path.join(scriptDir, ".."));
const buildDir = path.join(root, ".build");
const outputDir = path.join(root, "presentation");
const pptxPath = path.join(outputDir, "soutenance-stage-marc-duboc.pptx");

const W = 1280;
const H = 720;
const C = {
  bg: "#07131F",
  panel: "#0D2030",
  panel2: "#102A3D",
  ink: "#F5F8FB",
  muted: "#A9BAC8",
  faint: "#607486",
  cyan: "#35D3CB",
  cyanSoft: "#183D45",
  amber: "#FFB547",
  amberSoft: "#3B2B19",
  green: "#70E0A1",
  line: "#294152",
  red: "#F07178",
};
const FONT = "Arial";

function addText(slide, text, x, y, w, h, size, options = {}) {
  const shape = slide.shapes.add({
    geometry: "textbox",
    name: options.name,
    position: { left: x, top: y, width: w, height: h },
    fill: "none",
    line: { style: "solid", fill: "none", width: 0 },
  });
  shape.text = text;
  shape.text.style = {
    typeface: FONT,
    fontSize: size,
    bold: Boolean(options.bold),
    color: options.color || C.ink,
    alignment: options.align || "left",
    verticalAlignment: options.valign || "top",
    lineSpacing: options.lineSpacing || 1.0,
    autoFit: "shrinkText",
    wrap: "square",
    insets: options.insets || { top: 0, right: 0, bottom: 0, left: 0 },
  };
  return shape;
}

function addBox(slide, x, y, w, h, options = {}) {
  return slide.shapes.add({
    geometry: options.geometry || "roundRect",
    name: options.name,
    position: { left: x, top: y, width: w, height: h },
    fill: options.fill || C.panel,
    line: {
      style: options.lineStyle || "solid",
      fill: options.line || C.line,
      width: options.lineWidth === undefined ? 1 : options.lineWidth,
    },
    borderRadius: options.radius === undefined ? 14 : options.radius,
  });
}

function addRule(slide, x, y, w, h = 0, color = C.line, width = 2, dashed = false) {
  return slide.shapes.add({
    geometry: "line",
    position: { left: x, top: y, width: w, height: h },
    fill: "none",
    line: { style: dashed ? "dashed" : "solid", fill: color, width },
  });
}

function addDot(slide, cx, cy, d, fill, line = fill, lineWidth = 0) {
  return slide.shapes.add({
    geometry: "ellipse",
    position: { left: cx - d / 2, top: cy - d / 2, width: d, height: d },
    fill,
    line: { style: "solid", fill: line, width: lineWidth },
  });
}

function addTitle(slide, section, title, number) {
  addText(slide, section.toUpperCase(), 72, 30, 850, 24, 16, {
    bold: true,
    color: C.cyan,
    name: `section-${number}`,
  });
  addText(slide, title, 72, 54, 1136, 64, 48, {
    bold: true,
    color: C.ink,
    lineSpacing: 0.92,
    name: `title-${number}`,
  });
  addRule(slide, 72, 128, 1136, 0, C.line, 1);
}

function addFooter(slide, number) {
  addText(slide, "MARC DUBOC  ·  KAUST × IMT ATLANTIQUE", 72, 680, 530, 18, 13, {
    bold: true,
    color: C.faint,
    valign: "middle",
    name: `footer-${number}`,
  });
  addText(slide, `${String(number).padStart(2, "0")} / 05`, 1110, 680, 98, 18, 13, {
    bold: true,
    color: C.faint,
    align: "right",
    valign: "middle",
  });
}

function addNode(slide, x, y, w, h, label, detail, accent = C.cyan) {
  addBox(slide, x, y, w, h, { fill: C.panel2, line: C.line, radius: 12 });
  addRule(slide, x, y, 5, h, accent, 5);
  addText(slide, label, x + 18, y + 17, w - 34, 28, 22, { bold: true });
  addText(slide, detail, x + 18, y + 50, w - 34, h - 60, 16, { color: C.muted });
}

function setNotes(slide, script, sources) {
  slide.speakerNotes.textFrame.setText(`${script}\n\n[Sources]\n${sources.map((s) => `- ${s}`).join("\n")}`);
  slide.speakerNotes.setVisible(true);
}

function slideOne(p) {
  const s = p.slides.add();
  s.background.fill = C.bg;
  addTitle(s, "01 · Contexte et mission", "Sécuriser l'alerte 5G exige une station vérifiable", 1);

  addText(s, "KAUST  ·  SeRBER  ·  7 AVRIL - 31 JUILLET 2026", 72, 145, 540, 24, 16, {
    bold: true,
    color: C.muted,
  });
  addText(s, "Security for UAV-Based 5G-Advanced and 6G Networks", 72, 178, 520, 50, 22, {
    bold: true,
    color: C.amber,
    lineSpacing: 0.94,
  });
  addText(s, "MISSION", 72, 250, 190, 24, 16, { bold: true, color: C.cyan });
  addText(
    s,
    "Construire une station 5G légère et distribuée pour étudier, au sol, la sécurité des alertes d'urgence.",
    72,
    282,
    400,
    150,
    32,
    { bold: true, lineSpacing: 1.05 },
  );
  addText(s, "Objectif sécurité : rendre la chaîne PWS observable avant d'évaluer la menace.", 72, 470, 400, 68, 22, {
    color: C.muted,
    lineSpacing: 1.05,
  });

  addRule(s, 655, 328, 80, 0, C.cyan, 3);
  addRule(s, 910, 328, 70, 0, C.cyan, 3);
  addRule(s, 1070, 390, 0, 60, C.cyan, 3);
  addNode(s, 505, 280, 150, 96, "5G CORE + CU", "fonctions fixes", C.cyan);
  addNode(s, 735, 280, 175, 96, "F1", "Ethernet · Wi-Fi · 5G", C.cyan);
  addNode(s, 980, 280, 180, 96, "DU ARM + B210", "nœud déportable", C.cyan);
  addNode(s, 980, 450, 180, 96, "TERMINAL", "PWS + données", C.green);
  addText(s, "RADIO D'ACCÈS", 996, 406, 150, 22, 14, { bold: true, color: C.faint, align: "center" });

  addBox(s, 685, 514, 235, 62, { fill: C.amberSoft, line: C.amber, radius: 12 });
  addText(s, "OBJECTIF UAV", 703, 525, 200, 20, 15, { bold: true, color: C.amber, align: "center" });
  addText(s, "Vol non réalisé", 703, 548, 200, 22, 22, { bold: true, align: "center" });
  addRule(s, 925, 545, 45, 0, C.amber, 2, true);

  addFooter(s, 1);
  setNotes(
    s,
    "Bonjour. À KAUST, du 7 avril au 31 juillet, mon stage s'intitulait Security for UAV-Based 5G-Advanced and 6G Networks. Au sein de SeRBER, j'ai travaillé sur la sécurité des réseaux. Une station 5G sur drone peut rétablir une couverture, mais expose les alertes d'urgence à de nouveaux risques. Ma mission : construire une station OpenAirInterface légère et distribuée pour étudier ce scénario au sol, de façon contrôlée. Le cœur et la CU restent fixes ; la DU et la radio forment le nœud déportable.\n\nTransition : Pour rendre ce scénario crédible, il fallait préserver toute la chaîne de service, pas seulement démarrer deux logiciels.",
    [
      "KAUST_IMT_CellularSecurity_v2.pdf — intitulé officiel, objectifs et encadrement.",
      "https://serber.kaust.edu.sa/ — environnement de recherche SeRBER.",
      "oai-cu-du-lab/docs/STATUS.md et docs/BASELINES.md — périmètre et état consolidé.",
    ],
  );
}

function slideTwo(p) {
  const s = p.slides.add();
  s.background.fill = C.bg;
  addTitle(s, "02 · Problématique", "Déporter la DU crée un problème à trois couches", 2);
  addText(s, "Comment déporter la DU sans perdre PWS ni le service de données ?", 110, 146, 1060, 62, 32, {
    bold: true,
    align: "center",
    valign: "middle",
  });

  addRule(s, 414, 248, 0, 190, C.line, 1);
  addRule(s, 835, 248, 0, 190, C.line, 1);
  addText(s, "01", 82, 246, 70, 50, 42, { bold: true, color: C.faint });
  addText(s, "CALCUL", 160, 258, 215, 30, 24, { bold: true, color: C.cyan });
  addText(s, "ARM\nSCTP\nCPU · USB 3", 160, 302, 210, 128, 28, { bold: true, lineSpacing: 1.12 });
  addText(s, "02", 465, 246, 70, 50, 42, { bold: true, color: C.faint });
  addText(s, "TRANSPORT F1", 545, 258, 240, 30, 24, { bold: true, color: C.cyan });
  addText(s, "Routage\nLatence\nMTU · chemin réel", 545, 302, 260, 128, 28, { bold: true, lineSpacing: 1.12 });
  addText(s, "03", 885, 246, 70, 50, 42, { bold: true, color: C.faint });
  addText(s, "RADIO + SERVICE", 965, 258, 240, 30, 24, { bold: true, color: C.cyan });
  addText(s, "BLER\nMCS\nTerminal · PWS", 965, 302, 220, 128, 28, { bold: true, lineSpacing: 1.12 });

  addText(s, "UNE PREUVE DE BOUT EN BOUT", 72, 476, 330, 24, 16, { bold: true, color: C.muted });
  addRule(s, 150, 550, 980, 0, C.faint, 3);
  const proofX = [170, 478, 786, 1094];
  const proofLabels = ["F1 observé", "UE enregistré", "Internet", "PWS affiché"];
  for (let i = 0; i < proofX.length; i++) {
    addDot(s, proofX[i], 550, 24, i === 3 ? C.green : C.cyan, C.bg, 4);
    addText(s, proofLabels[i], proofX[i] - 100, 578, 200, 30, 22, { bold: true, align: "center" });
  }
  addText(s, "Baseline Ethernet = retour à un état connu", 72, 632, 1136, 28, 22, {
    bold: true,
    color: C.amber,
    align: "center",
  });
  addFooter(s, 2);
  setNotes(
    s,
    "La question était : comment exécuter la DU sur une plateforme légère, transporter F1 sur un lien non idéal et conserver PWS ainsi que les données du terminal ? Trois couches interagissaient : le calcul ARM et l'USB vers la radio ; le transport, avec routage, latence et MTU ; enfin la radio, avec BLER et adaptation MCS. J'ai donc défini quatre preuves : F1 observé sur le bon chemin, terminal enregistré, session de données avec Internet, puis alerte affichée. La baseline Ethernet restait disponible pour revenir à un état connu.\n\nTransition : Ces critères ont transformé le stage en une suite d'expériences isolées et comparables à une référence.",
    [
      "oai-cu-du-lab/README.md — architecture, transports, validation et rollback.",
      "oai-cu-du-lab/docs/evidence/PWS-F1.md et docs/NETWORK.md — chemin PWS et transports F1.",
    ],
  );
}

function slideThree(p) {
  const s = p.slides.add();
  s.background.fill = C.bg;
  addTitle(s, "03 · Méthode et planning", "Deux pivots ont structuré ma méthode", 3);

  addText(s, "CONTRIBUTION PERSONNELLE", 930, 143, 278, 22, 15, { bold: true, color: C.cyan, align: "right" });
  addRule(s, 118, 302, 1042, 0, C.faint, 3);
  const xs = [120, 380, 640, 900, 1160];
  const dates = ["AVRIL", "MAI", "MAI - JUIN", "JUIN - JUIL.", "JUILLET"];
  const phases = ["Socle 5G", "PWS sur F1", "3 transports", "Pi + Jetson", "Mesure + transmission"];
  const contrib = ["5GC · B210 · UE", "patch PWS", "GRE · WireGuard", "noyau SCTP · USB 3", "prévols · preuves · rollback"];
  for (let i = 0; i < xs.length; i++) {
    addDot(s, xs[i], 302, 26, i === 0 ? C.ink : C.cyan, C.bg, 5);
    addText(s, dates[i], xs[i] - 100, 194, 200, 24, 16, { bold: true, color: C.muted, align: "center" });
    addText(s, phases[i], xs[i] - 112, 228, 224, 40, 25, { bold: true, align: "center", valign: "middle" });
    addText(s, contrib[i], xs[i] - 116, 334, 232, 50, 22, { bold: i > 0, color: i > 0 ? C.cyan : C.muted, align: "center", valign: "middle" });
  }

  addText(s, "PIVOTS", 72, 420, 100, 22, 16, { bold: true, color: C.amber });
  addRule(s, 72, 454, 540, 0, C.line, 1);
  addRule(s, 668, 454, 540, 0, C.line, 1);
  addText(s, "1 radio partagée", 72, 470, 230, 32, 24, { bold: true, color: C.faint });
  addText(s, "→", 307, 468, 48, 34, 28, { bold: true, color: C.amber, align: "center" });
  addText(s, "B210 accès + modem donneur", 365, 470, 247, 58, 24, { bold: true });
  addText(s, "Changer l'hôte", 668, 470, 190, 32, 24, { bold: true, color: C.faint });
  addText(s, "→", 862, 468, 48, 34, 28, { bold: true, color: C.amber, align: "center" });
  addText(s, "Mesurer MSS · BLER · MCS", 925, 470, 283, 58, 24, { bold: true });

  addBox(s, 72, 578, 1136, 66, { fill: C.cyanSoft, line: C.cyan, radius: 12 });
  addText(s, "BASELINE  →  HYPOTHÈSE  →  MESURE  →  CORRECTION  →  REPRODUCTION", 98, 598, 1084, 28, 24, {
    bold: true,
    color: C.ink,
    align: "center",
  });
  addFooter(s, 3);
  setNotes(
    s,
    "En avril, j'ai reproduit le cœur 5G, la B210 et le terminal. En mai, j'ai séparé CU et DU puis complété le chemin SIB8 sur F1, le gestionnaire DU et la copie sûre du message. J'ai ensuite transporté F1 par Wi-Fi/GRE, puis par 5G/WireGuard. Un premier choix a échoué : partager la même cellule entre accès et backhaul créait une dépendance circulaire au redémarrage. J'ai séparé la B210 d'accès et le modem donneur. Enfin, j'ai porté la DU sur Raspberry Pi et Jetson, construit un noyau Jetson avec SCTP, fiabilisé l'USB 3 et automatisé prévols, preuves et rollback. Chaque pivot est consigné dans l'historique canonique et les preuves assainies. La méthode est restée : baseline, hypothèse, mesure, correction, reproduction.\n\nTransition : Cette démarche donne des résultats solides, à condition de ne pas confondre meilleurs runs et comparaison statistique.",
    [
      "Historique Git de oai-cu-du-lab — chronologie et décisions consolidées.",
      "github.com/promaaa/jetson-kernel-sctp — noyau SCTP, vérification et rollback Jetson.",
      "oai-cu-du-lab — console opérateur, portes de preuve et consolidation de juillet 2026.",
    ],
  );
}

function slideFour(p) {
  const s = p.slides.add();
  s.background.fill = C.bg;
  addTitle(s, "04 · Résultats, impact et limites", "Trois F1 validés ; 68 Mbit/s sur Jetson au sol", 4);

  addText(s, "CHAÎNE DE SERVICE VALIDÉE SUR TERMINAL COMMERCIAL", 72, 145, 620, 22, 15, { bold: true, color: C.muted });
  addRule(s, 110, 205, 1000, 0, C.green, 3);
  const chainX = [130, 455, 780, 1105];
  const chainLabels = ["F1", "UE enregistré", "Internet", "PWS affiché"];
  for (let i = 0; i < chainX.length; i++) {
    addDot(s, chainX[i], 205, 22, C.green, C.bg, 4);
    addText(s, chainLabels[i], chainX[i] - 105, 171, 210, 26, 22, { bold: true, align: "center" });
  }

  addRule(s, 452, 275, 0, 158, C.line, 1);
  addRule(s, 828, 275, 0, 158, C.line, 1);
  const metrics = [
    { x: 72, value: "89", unit: "Mbit/s soutenus", context: "x86 · Ethernet", note: "≈100 pic" },
    { x: 476, value: "52", unit: "Mbit/s max", context: "x86 · Wi-Fi/GRE", note: "" },
    { x: 852, value: "68", unit: "Mbit/s max", context: "Jetson · 5G/WireGuard", note: "run final validé" },
  ];
  for (const m of metrics) {
    addText(s, m.value, m.x, 270, 140, 78, 58, { bold: true, color: C.cyan });
    addText(s, m.unit, m.x + 145, 292, 225, 30, 23, { bold: true });
    addText(s, m.context, m.x, 356, 330, 28, 22, { bold: true, color: C.muted });
    if (m.note) addText(s, m.note, m.x, 390, 330, 24, 19, { bold: true, color: C.amber });
  }
  addText(s, "MEILLEURS RUNS DISTINCTS - PAS DES MOYENNES COMPARABLES", 72, 432, 1136, 24, 22, {
    bold: true,
    color: C.amber,
    align: "center",
  });

  addBox(s, 72, 482, 530, 150, { fill: C.cyanSoft, line: C.cyan, radius: 12 });
  addText(s, "DIAGNOSTIC + IMPACT", 94, 500, 250, 22, 18, { bold: true, color: C.cyan });
  addText(s, "MCS 5  →  24-27", 94, 535, 240, 34, 30, { bold: true });
  addText(s, "MSS + fenêtre BLER", 350, 541, 220, 26, 22, { bold: true, color: C.muted });
  addText(s, "Banc relançable · noyau Jetson · rollback documenté", 94, 588, 470, 28, 22, { bold: true });

  addBox(s, 626, 482, 582, 150, { fill: C.amberSoft, line: C.amber, radius: 12 });
  addText(s, "LIMITES ASSUMÉES", 648, 500, 250, 22, 18, { bold: true, color: C.amber });
  addText(s, "Pas de vol", 648, 538, 160, 28, 24, { bold: true });
  addText(s, "Pas de campagne RF répétée", 825, 538, 335, 28, 24, { bold: true });
  addText(s, "Puissance encore estimée", 648, 585, 440, 28, 24, { bold: true });
  addFooter(s, 4);
  setNotes(
    s,
    "Sur un téléphone commercial, j'ai validé l'enregistrement, Internet et une alerte PWS transmise de la CU vers la DU par F1. Le banc fonctionne sur Ethernet, Wi-Fi/GRE et 5G/WireGuard, sur Pi et Jetson. Ces chiffres sont des meilleurs runs dans des conditions différentes, pas des moyennes comparables. Sur x86 et Ethernet : 89 mégabits par seconde soutenus, environ 100 en pic. Le Wi-Fi atteint 52. Sur Jetson avec backhaul 5G, le meilleur run validé atteint 68. Le diagnostic Ethernet compte autant : le réglage MSS et la fenêtre BLER ont fait passer le MCS dominant de 5 à 24-27. Je laisse un banc relançable, un noyau Jetson et un rollback documenté. Limites : pas de vol, pas de campagne RF répétée et une puissance encore estimée.\n\nTransition : Au-delà des chiffres, ce travail a surtout changé ma manière d'aborder un système complexe.",
    [
      "oai-cu-du-lab/docs/evidence/BENCHMARKS.md et PWS-F1.md — PWS, service utilisateur et mesures assainies.",
      "oai-cu-du-lab/docs/PDFs/research-paper.tex — 68 Mbit/s Jetson, 89 soutenus/100 pic, MCS 24-27 et limites.",
      "Confirmation explicite de Marc Duboc, 5 août 2026 — 68 Mbit/s officiellement validés.",
    ],
  );
}

function slideFive(p) {
  const s = p.slides.add();
  s.background.fill = C.bg;
  addTitle(s, "05 · Bilan et projet", "Prouver avant de miniaturiser : mon principal acquis", 5);

  const ys = [158, 274, 390];
  const nums = ["01", "02", "03"];
  const skills = ["DIAGNOSTIQUER ENTRE COUCHES", "RENDRE REPRODUCTIBLE", "PORTER SUR L'EMBARQUÉ"];
  const proofs = ["MSS · BLER · MCS", "Prévols · preuves · rollback", "ARM · SCTP · CPU / USB"];
  for (let i = 0; i < ys.length; i++) {
    addText(s, nums[i], 74, ys[i], 64, 52, 38, { bold: true, color: C.faint, valign: "middle" });
    addText(s, skills[i], 160, ys[i] + 2, 505, 30, 24, { bold: true, color: C.cyan });
    addText(s, proofs[i], 160, ys[i] + 40, 505, 36, 30, { bold: true });
    addRule(s, 72, ys[i] + 92, 600, 0, C.line, 1);
  }

  addText(s, "UNE MÉTHODE TRANSFÉRABLE", 735, 160, 430, 22, 16, { bold: true, color: C.muted });
  addRule(s, 767, 295, 335, 0, C.cyan, 3);
  const pathX = [780, 950, 1120];
  const pathLabels = ["IMT\nAtlantique", "R&D systèmes\ncyberphysiques", "SNU\n3D Vision Lab"];
  for (let i = 0; i < pathX.length; i++) {
    addDot(s, pathX[i], 295, 28, i === 2 ? C.green : C.cyan, C.bg, 5);
    addText(s, pathLabels[i], pathX[i] - 90, 325, 180, 76, 22, { bold: true, align: "center", lineSpacing: 1.05 });
  }
  addText(s, "Hypothèse  →  instrumentation  →  preuve  →  référence", 712, 430, 490, 60, 23, {
    bold: true,
    color: C.amber,
    align: "center",
    valign: "middle",
  });

  addBox(s, 72, 544, 1136, 104, { fill: C.panel2, line: C.cyan, radius: 14 });
  addText(s, "AVANT LE VOL : PROUVER, REPRODUIRE, DÉ-RISQUER.", 105, 570, 1070, 50, 32, {
    bold: true,
    color: C.ink,
    align: "center",
    valign: "middle",
  });
  addFooter(s, 5);
  setNotes(
    s,
    "J'ai mobilisé les réseaux appris à IMT Atlantique, puis développé trois compétences. Diagnostiquer entre couches : le faible débit venait de l'interaction entre paquets, BLER et scheduler. Rendre une expérience transmissible grâce aux prévols, aux preuves et au rollback. Maîtriser les contraintes embarquées, du noyau SCTP au partage CPU et USB. Cette méthode — hypothèse, instrumentation, preuve, référence — est transférable aux systèmes cyberphysiques. C'est mon principal acquis d'ingénieur. Elle relie ce stage à mon projet en R&D, robotique autonome et vision 3D à Seoul National University. Je n'ai pas fait voler une base 5G ; j'ai construit et dé-risqué le nœud reproductible qu'il faut valider avant le vol.",
    [
      "github.com/promaaa/jetson-kernel-sctp — preuve de portage et de rollback Jetson.",
      "oai-cu-du-lab — livrables, diagnostics et chronologie consolidée.",
      "Cahier des charges de la soutenance — projet professionnel SNU 3D Vision Lab.",
    ],
  );
}

async function writeBlob(filePath, blob) {
  await fs.writeFile(filePath, new Uint8Array(await blob.arrayBuffer()));
}

async function main() {
  await fs.mkdir(buildDir, { recursive: true });
  await fs.mkdir(outputDir, { recursive: true });
  const presentation = Presentation.create({ slideSize: { width: W, height: H } });
  slideOne(presentation);
  slideTwo(presentation);
  slideThree(presentation);
  slideFour(presentation);
  slideFive(presentation);

  for (const [index, slide] of presentation.slides.items.entries()) {
    const stem = `slide-${String(index + 1).padStart(2, "0")}`;
    await writeBlob(path.join(buildDir, `${stem}.png`), await presentation.export({ slide, format: "png", scale: 1.5 }));
    const layout = await slide.export({ format: "layout" });
    await fs.writeFile(path.join(buildDir, `${stem}.layout.json`), await layout.text());
  }
  await writeBlob(path.join(buildDir, "deck-montage.webp"), await presentation.export({ format: "webp", montage: true, scale: 1 }));
  const inspection = await presentation.inspect({ kind: "slide,textbox,shape,notes", maxChars: 50000 });
  await fs.writeFile(path.join(buildDir, "inspection.ndjson"), inspection.ndjson);
  const pptx = await PresentationFile.exportPptx(presentation);
  await pptx.save(pptxPath);
  await fs.rm(`${pptxPath}.inspect.ndjson`, { force: true });
  process.stdout.write(`${pptxPath}\n`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
