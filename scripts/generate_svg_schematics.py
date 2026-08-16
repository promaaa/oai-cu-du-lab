#!/usr/bin/env python3
import os

def generate_monolithic_svg():
    svg_content = '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 760 220" width="100%" height="100%">
  <defs>
    <style>
      .title { font-family: system-ui, -apple-system, sans-serif; font-size: 14px; font-weight: bold; fill: #176B87; }
      .label { font-family: system-ui, -apple-system, sans-serif; font-size: 12px; font-weight: 600; fill: #2C3E50; }
      .sublabel { font-family: system-ui, -apple-system, sans-serif; font-size: 10px; fill: #666666; }
      .link-text { font-family: system-ui, -apple-system, sans-serif; font-size: 11px; font-weight: 600; fill: #176B87; }
      .badge { font-family: system-ui, -apple-system, sans-serif; font-size: 10px; font-weight: bold; fill: #FFFFFF; }
      .box-host { fill: #EDF6F8; stroke: #176B87; stroke-width: 1.5; stroke-dasharray: 4,4; rx: 8px; }
      .box-core { fill: #176B87; stroke: #0E4658; stroke-width: 1.5; rx: 6px; }
      .box-radio { fill: #FFF3E0; stroke: #E67E22; stroke-width: 1.5; rx: 6px; }
      .box-ue { fill: #EAF6EE; stroke: #27AE60; stroke-width: 1.5; rx: 6px; }
      .line-bus { stroke: #176B87; stroke-width: 2; }
      .line-rf { stroke: #E67E22; stroke-width: 2; stroke-dasharray: 5,3; }
    </style>
    <marker id="arrow-blue" markerWidth="8" markerHeight="8" refX="6" refY="4" orient="auto">
      <path d="M0,0 L8,4 L0,8 Z" fill="#176B87" />
    </marker>
    <marker id="arrow-orange" markerWidth="8" markerHeight="8" refX="6" refY="4" orient="auto">
      <path d="M0,0 L8,4 L0,8 Z" fill="#E67E22" />
    </marker>
    <marker id="arrow-orange-reverse" markerWidth="8" markerHeight="8" refX="2" refY="4" orient="auto">
      <path d="M8,0 L0,4 L8,8 Z" fill="#E67E22" />
    </marker>
    <filter id="shadow" x="-5%" y="-5%" width="110%" height="110%">
      <feDropShadow dx="0" dy="2" stdDeviation="3" flood-opacity="0.1" />
    </filter>
  </defs>

  <!-- Background container for Firecell Host -->
  <rect x="20" y="25" width="340" height="170" class="box-host" />
  <text x="35" y="45" class="title">Firecell Host (Monolithic Reference)</text>

  <!-- OAI 5GC Core Box -->
  <g filter="url(#shadow)">
    <rect x="40" y="65" width="120" height="100" class="box-core" />
    <text x="100" y="110" class="label" fill="#FFFFFF" text-anchor="middle">OAI 5GC</text>
    <text x="100" y="130" class="sublabel" fill="#D0E8F0" text-anchor="middle">AMF / SMF / UPF</text>
  </g>

  <!-- Internal Bus Arrow -->
  <path d="M160 115 L220 115" class="line-bus" marker-end="url(#arrow-blue)" />
  <text x="190" y="105" class="link-text" text-anchor="middle">N2 / N3</text>

  <!-- OAI gNB Box inside Firecell -->
  <g filter="url(#shadow)">
    <rect x="220" y="65" width="120" height="100" class="box-core" />
    <text x="280" y="110" class="label" fill="#FFFFFF" text-anchor="middle">OAI gNB</text>
    <text x="280" y="130" class="sublabel" fill="#D0E8F0" text-anchor="middle">CU + DU Monolithic</text>
  </g>

  <!-- USB3 Link -->
  <path d="M340 115 L430 115" class="line-bus" marker-end="url(#arrow-blue)" />
  <text x="385" y="105" class="link-text" text-anchor="middle">USB 3.0</text>

  <!-- USRP B210 Box -->
  <g filter="url(#shadow)">
    <rect x="430" y="65" width="130" height="100" class="box-radio" />
    <text x="495" y="105" class="label" fill="#D35400" text-anchor="middle">USRP B210</text>
    <text x="495" y="125" class="sublabel" fill="#E67E22" text-anchor="middle">Sub-6 GHz Radio</text>
    <rect x="455" y="138" width="80" height="18" rx="3" fill="#E67E22" />
    <text x="495" y="151" class="badge" text-anchor="middle">ACCESS RADIO</text>
  </g>

  <!-- RF Air Interface Link -->
  <path d="M560 115 L620 115" class="line-rf" marker-start="url(#arrow-orange-reverse)" marker-end="url(#arrow-orange)" />
  <text x="590" y="100" class="link-text" fill="#D35400" text-anchor="middle">NR n78</text>
  <text x="590" y="135" class="sublabel" fill="#D35400" text-anchor="middle">3.5 GHz RF</text>

  <!-- Commercial UE Box -->
  <g filter="url(#shadow)">
    <rect x="620" y="65" width="120" height="100" class="box-ue" />
    <text x="680" y="105" class="label" fill="#27AE60" text-anchor="middle">Nothing Phone</text>
    <text x="680" y="125" class="sublabel" fill="#27AE60" text-anchor="middle">Commercial 5G UE</text>
    <rect x="640" y="138" width="80" height="18" rx="3" fill="#27AE60" />
    <text x="680" y="151" class="badge" text-anchor="middle">5G SA CLIENT</text>
  </g>
</svg>
'''
    with open('docs/PDFs/schematics/monolithic-reference.svg', 'w') as f:
        f.write(svg_content.strip())
    print("Generated monolithic-reference.svg")

def generate_cu_du_split_svg():
    svg_content = '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 800 240" width="100%" height="100%">
  <defs>
    <style>
      .title { font-family: system-ui, -apple-system, sans-serif; font-size: 13px; font-weight: bold; fill: #176B87; }
      .label { font-family: system-ui, -apple-system, sans-serif; font-size: 12px; font-weight: 600; fill: #2C3E50; }
      .sublabel { font-family: system-ui, -apple-system, sans-serif; font-size: 10px; fill: #666666; }
      .link-text { font-family: system-ui, -apple-system, sans-serif; font-size: 11px; font-weight: bold; fill: #176B87; }
      .badge { font-family: system-ui, -apple-system, sans-serif; font-size: 10px; font-weight: bold; fill: #FFFFFF; }
      .box-host { fill: #EDF6F8; stroke: #176B87; stroke-width: 1.5; stroke-dasharray: 4,4; rx: 8px; }
      .box-du-host { fill: #F4F6F7; stroke: #7F8C8D; stroke-width: 1.5; stroke-dasharray: 4,4; rx: 8px; }
      .box-core { fill: #176B87; stroke: #0E4658; stroke-width: 1.5; rx: 6px; }
      .box-cu { fill: #2980B9; stroke: #1B4F72; stroke-width: 1.5; rx: 6px; }
      .box-du { fill: #8E44AD; stroke: #512E5F; stroke-width: 1.5; rx: 6px; }
      .box-radio { fill: #FFF3E0; stroke: #E67E22; stroke-width: 1.5; rx: 6px; }
      .box-ue { fill: #EAF6EE; stroke: #27AE60; stroke-width: 1.5; rx: 6px; }
      .line-f1 { stroke: #2980B9; stroke-width: 2.5; }
      .line-rf { stroke: #E67E22; stroke-width: 2; stroke-dasharray: 5,3; }
      .line-bus { stroke: #176B87; stroke-width: 2; }
    </style>
    <marker id="arrow-blue" markerWidth="8" markerHeight="8" refX="6" refY="4" orient="auto">
      <path d="M0,0 L8,4 L0,8 Z" fill="#2980B9" />
    </marker>
    <marker id="arrow-blue-rev" markerWidth="8" markerHeight="8" refX="2" refY="4" orient="auto">
      <path d="M8,0 L0,4 L8,8 Z" fill="#2980B9" />
    </marker>
    <marker id="arrow-orange" markerWidth="8" markerHeight="8" refX="6" refY="4" orient="auto">
      <path d="M0,0 L8,4 L0,8 Z" fill="#E67E22" />
    </marker>
    <marker id="arrow-orange-rev" markerWidth="8" markerHeight="8" refX="2" refY="4" orient="auto">
      <path d="M8,0 L0,4 L8,8 Z" fill="#E67E22" />
    </marker>
    <filter id="shadow" x="-5%" y="-5%" width="110%" height="110%">
      <feDropShadow dx="0" dy="2" stdDeviation="3" flood-opacity="0.1" />
    </filter>
  </defs>

  <!-- Firecell Host Box -->
  <rect x="15" y="25" width="255" height="190" class="box-host" />
  <text x="25" y="45" class="title">Firecell Host (CU Side)</text>

  <g filter="url(#shadow)">
    <rect x="30" y="60" width="105" height="135" class="box-core" />
    <text x="82" y="120" class="label" fill="#FFFFFF" text-anchor="middle">OAI 5GC</text>
    <text x="82" y="140" class="sublabel" fill="#D0E8F0" text-anchor="middle">AMF / SMF / UPF</text>
  </g>

  <g filter="url(#shadow)">
    <rect x="150" y="60" width="105" height="135" class="box-cu" />
    <text x="202" y="115" class="label" fill="#FFFFFF" text-anchor="middle">OAI CU</text>
    <text x="202" y="135" class="sublabel" fill="#E1F5FE" text-anchor="middle">F1AP &amp; GTP-U</text>
    <rect x="162" y="165" width="80" height="18" rx="3" fill="#1B4F72" />
    <text x="202" y="178" class="badge" text-anchor="middle">CENTRAL UNIT</text>
  </g>

  <!-- F1 Network Path -->
  <path d="M255 127 L385 127" class="line-f1" marker-start="url(#arrow-blue-rev)" marker-end="url(#arrow-blue)" />
  <rect x="270" y="90" width="100" height="32" rx="4" fill="#E1F5FE" stroke="#2980B9" stroke-width="1" />
  <text x="320" y="105" class="link-text" text-anchor="middle">F1-C (SCTP)</text>
  <text x="320" y="117" class="link-text" text-anchor="middle">F1-U (GTP-U)</text>
  <text x="320" y="145" class="sublabel" text-anchor="middle">Ethernet / Wi-Fi GRE</text>

  <!-- Access DU Host Box -->
  <rect x="385" y="25" width="265" height="190" class="box-du-host" />
  <text x="395" y="45" class="title" fill="#512E5F">Access DU Host (MiniPC / Pi / Jetson)</text>

  <g filter="url(#shadow)">
    <rect x="400" y="60" width="105" height="135" class="box-du" />
    <text x="452" y="115" class="label" fill="#FFFFFF" text-anchor="middle">OAI DU</text>
    <text x="452" y="135" class="sublabel" fill="#F3E5F5" text-anchor="middle">RLC / MAC / PHY</text>
    <rect x="412" y="165" width="80" height="18" rx="3" fill="#512E5F" />
    <text x="452" y="178" class="badge" text-anchor="middle">DISTRIBUTED UNIT</text>
  </g>

  <g filter="url(#shadow)">
    <rect x="520" y="60" width="115" height="135" class="box-radio" />
    <text x="577" y="115" class="label" fill="#D35400" text-anchor="middle">USRP B210</text>
    <text x="577" y="135" class="sublabel" fill="#E67E22" text-anchor="middle">Access Radio</text>
    <rect x="537" y="165" width="80" height="18" rx="3" fill="#E67E22" />
    <text x="577" y="178" class="badge" text-anchor="middle">ACCESS RF</text>
  </g>

  <!-- RF Air Link -->
  <path d="M650 127 L695 127" class="line-rf" marker-start="url(#arrow-orange-rev)" marker-end="url(#arrow-orange)" />
  <text x="672" y="115" class="link-text" fill="#D35400" text-anchor="middle">n78</text>

  <!-- Phone Box -->
  <g filter="url(#shadow)">
    <rect x="695" y="60" width="95" height="135" class="box-ue" />
    <text x="742" y="115" class="label" fill="#27AE60" text-anchor="middle">Phone</text>
    <text x="742" y="135" class="sublabel" fill="#27AE60" text-anchor="middle">5G UE</text>
  </g>
</svg>
'''
    with open('docs/PDFs/schematics/cu-du-split.svg', 'w') as f:
        f.write(svg_content.strip())
    print("Generated cu-du-split.svg")

def generate_quectel_wireless_f1_svg():
    svg_content = '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 840 320" width="100%" height="100%">
  <defs>
    <style>
      .title { font-family: system-ui, -apple-system, sans-serif; font-size: 13px; font-weight: bold; fill: #176B87; }
      .label { font-family: system-ui, -apple-system, sans-serif; font-size: 11px; font-weight: 600; fill: #2C3E50; }
      .sublabel { font-family: system-ui, -apple-system, sans-serif; font-size: 9.5px; fill: #555555; }
      .link-text { font-family: system-ui, -apple-system, sans-serif; font-size: 10.5px; font-weight: bold; fill: #176B87; }
      .badge { font-family: system-ui, -apple-system, sans-serif; font-size: 9px; font-weight: bold; fill: #FFFFFF; }
      .box-host { fill: #EDF6F8; stroke: #176B87; stroke-width: 1.5; stroke-dasharray: 4,4; rx: 8px; }
      .box-du-host { fill: #F4F6F7; stroke: #7F8C8D; stroke-width: 1.5; stroke-dasharray: 4,4; rx: 8px; }
      .box-core { fill: #176B87; stroke: #0E4658; stroke-width: 1.5; rx: 6px; }
      .box-cu { fill: #2980B9; stroke: #1B4F72; stroke-width: 1.5; rx: 6px; }
      .box-du { fill: #8E44AD; stroke: #512E5F; stroke-width: 1.5; rx: 6px; }
      .box-radio { fill: #FFF3E0; stroke: #E67E22; stroke-width: 1.5; rx: 6px; }
      .box-modem { fill: #E8F8F5; stroke: #16A085; stroke-width: 1.5; rx: 6px; }
      .box-ue { fill: #EAF6EE; stroke: #27AE60; stroke-width: 1.5; rx: 6px; }
      .line-f1 { stroke: #2980B9; stroke-width: 2.5; }
      .line-wg { stroke: #8E44AD; stroke-width: 2; stroke-dasharray: 6,3; }
      .line-rf { stroke: #E67E22; stroke-width: 2; stroke-dasharray: 4,3; }
    </style>
    <marker id="arrow-blue" markerWidth="8" markerHeight="8" refX="6" refY="4" orient="auto">
      <path d="M0,0 L8,4 L0,8 Z" fill="#2980B9" />
    </marker>
    <marker id="arrow-purple" markerWidth="8" markerHeight="8" refX="6" refY="4" orient="auto">
      <path d="M0,0 L8,4 L0,8 Z" fill="#8E44AD" />
    </marker>
    <marker id="arrow-purple-rev" markerWidth="8" markerHeight="8" refX="2" refY="4" orient="auto">
      <path d="M8,0 L0,4 L8,8 Z" fill="#8E44AD" />
    </marker>
    <marker id="arrow-orange" markerWidth="8" markerHeight="8" refX="6" refY="4" orient="auto">
      <path d="M0,0 L8,4 L0,8 Z" fill="#E67E22" />
    </marker>
    <marker id="arrow-orange-rev" markerWidth="8" markerHeight="8" refX="2" refY="4" orient="auto">
      <path d="M8,0 L0,4 L8,8 Z" fill="#E67E22" />
    </marker>
    <filter id="shadow" x="-5%" y="-5%" width="110%" height="110%">
      <feDropShadow dx="0" dy="2" stdDeviation="3" flood-opacity="0.1" />
    </filter>
  </defs>

  <!-- Firecell Host Container (Top Box) -->
  <rect x="15" y="15" width="810" height="130" class="box-host" />
  <text x="25" y="32" class="title">Firecell Host (5GC Core + Donor gNB + Access CU)</text>

  <!-- 5GC Box -->
  <g filter="url(#shadow)">
    <rect x="25" y="45" width="110" height="85" class="box-core" />
    <text x="80" y="85" class="label" fill="#FFFFFF" text-anchor="middle">OAI 5GC</text>
    <text x="80" y="100" class="sublabel" fill="#D0E8F0" text-anchor="middle">AMF / UPF</text>
  </g>

  <!-- Donor gNB Box -->
  <g filter="url(#shadow)">
    <rect x="155" y="45" width="125" height="85" class="box-core" />
    <text x="217" y="80" class="label" fill="#FFFFFF" text-anchor="middle">Donor gNB</text>
    <text x="217" y="95" class="sublabel" fill="#D0E8F0" text-anchor="middle">+ USRP B210 #1</text>
    <rect x="177" y="105" width="80" height="16" rx="3" fill="#0E4658" />
    <text x="217" y="116" class="badge" text-anchor="middle">DONOR CELL</text>
  </g>

  <!-- Access CU Box -->
  <g filter="url(#shadow)">
    <rect x="675" y="45" width="135" height="85" class="box-cu" />
    <text x="742" y="80" class="label" fill="#FFFFFF" text-anchor="middle">Firecell Access CU</text>
    <text x="742" y="95" class="sublabel" fill="#E1F5FE" text-anchor="middle">F1 Endpoint</text>
    <rect x="702" y="105" width="80" height="16" rx="3" fill="#1B4F72" />
    <text x="742" y="116" class="badge" text-anchor="middle">ACCESS CU</text>
  </g>

  <!-- Donor RF Air Interface Link to Modem -->
  <path d="M280 87 L370 87" class="line-rf" marker-start="url(#arrow-orange-rev)" marker-end="url(#arrow-orange)" />
  <text x="325" y="75" class="link-text" fill="#D35400" text-anchor="middle">Donor RF n78</text>
  <text x="325" y="102" class="sublabel" fill="#D35400" text-anchor="middle">Wireless 5G</text>

  <!-- Access DU Host Container (Bottom Right Box) -->
  <rect x="15" y="170" width="810" height="135" class="box-du-host" />
  <text x="25" y="187" class="title" fill="#512E5F">Access DU Host (MiniPC / Pi / Jetson) + Backhaul &amp; UE</text>

  <!-- Quectel Modem Box -->
  <g filter="url(#shadow)">
    <rect x="370" y="45" width="150" height="85" class="box-modem" />
    <text x="445" y="78" class="label" fill="#16A085" text-anchor="middle">Quectel 5G Modem</text>
    <text x="445" y="93" class="sublabel" fill="#16A085" text-anchor="middle">Data Interface: wwan0</text>
    <rect x="405" y="105" width="80" height="16" rx="3" fill="#16A085" />
    <text x="445" y="116" class="badge" text-anchor="middle">IP BACKHAUL</text>
  </g>

  <!-- WireGuard Tunnel Path -->
  <path d="M445 130 L445 200 L675 200" fill="none" class="line-wg" marker-end="url(#arrow-purple)" />
  <rect x="475" y="185" width="170" height="30" rx="4" fill="#F3E5F5" stroke="#8E44AD" stroke-width="1" />
  <text x="560" y="200" class="link-text" fill="#8E44AD" text-anchor="middle">WireGuard (wg-quectel-f1)</text>
  <text x="560" y="210" class="sublabel" fill="#8E44AD" text-anchor="middle">F1-C / F1-U Encapsulated</text>

  <!-- Access DU Box -->
  <g filter="url(#shadow)">
    <rect x="25" y="200" width="140" height="90" class="box-du" />
    <text x="95" y="235" class="label" fill="#FFFFFF" text-anchor="middle">Access DU</text>
    <text x="95" y="250" class="sublabel" fill="#F3E5F5" text-anchor="middle">MiniPC / Pi / Jetson</text>
    <rect x="55" y="263" width="80" height="16" rx="3" fill="#512E5F" />
    <text x="95" y="274" class="badge" text-anchor="middle">ACCESS DU</text>
  </g>

  <!-- WireGuard connection into Access DU -->
  <path d="M675 200 L165 200" fill="none" class="line-wg" marker-start="url(#arrow-purple-rev)" />

  <!-- Access USRP B210 Box -->
  <g filter="url(#shadow)">
    <rect x="220" y="200" width="135" height="90" class="box-radio" />
    <text x="287" y="235" class="label" fill="#D35400" text-anchor="middle">USRP B210 #2</text>
    <text x="287" y="250" class="sublabel" fill="#E67E22" text-anchor="middle">Access Cell Radio</text>
    <rect x="247" y="263" width="80" height="16" rx="3" fill="#E67E22" />
    <text x="287" y="274" class="badge" text-anchor="middle">ACCESS RF</text>
  </g>

  <!-- Connection between Access DU and Access B210 -->
  <path d="M165 245 L220 245" class="line-f1" />

  <!-- Access RF Link to Phone -->
  <path d="M355 245 L420 245" class="line-rf" marker-start="url(#arrow-orange-rev)" marker-end="url(#arrow-orange)" />
  <text x="387" y="235" class="link-text" fill="#D35400" text-anchor="middle">n78</text>

  <!-- Nothing Phone Box -->
  <g filter="url(#shadow)">
    <rect x="420" y="200" width="110" height="90" class="box-ue" />
    <text x="475" y="240" class="label" fill="#27AE60" text-anchor="middle">Nothing Phone</text>
    <text x="475" y="255" class="sublabel" fill="#27AE60" text-anchor="middle">Commercial UE</text>
  </g>
</svg>
'''
    with open('docs/PDFs/schematics/quectel-wireless-f1.svg', 'w') as f:
        f.write(svg_content.strip())
    print("Generated quectel-wireless-f1.svg")

if __name__ == '__main__':
    generate_monolithic_svg()
    generate_cu_du_split_svg()
    generate_quectel_wireless_f1_svg()
