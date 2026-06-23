#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""Raspa todos os horarios de onibus do site da Prefeitura de Mogi das Cruzes.
Gera schedules.json com a versao (data de geracao) e os horarios de cada linha,
EXCLUINDO os itinerarios (logradouros)."""
import json, re, sys, time, urllib.request, datetime, os

BASE = "https://mobilidadeservicos.mogidascruzes.sp.gov.br"
UA = {"User-Agent": "Mozilla/5.0 (mogi-onibus scraper)"}
OUT = os.path.join(os.path.dirname(__file__), "..", "app", "assets", "schedules.json")


def get(url, tries=3):
    last = None
    for _ in range(tries):
        try:
            req = urllib.request.Request(url, headers=UA)
            with urllib.request.urlopen(req, timeout=30) as r:
                return r.read()
        except Exception as e:
            last = e
            time.sleep(2)
    raise last


def listar_linhas():
    data = json.loads(get(BASE + "/buscar-linha?query=").decode("utf-8"))
    out = []
    for x in data.get("linhas", []):
        out.append({"linha": x["linha"], "nome": x.get("nome", "").strip()})
    # dedup preservando ordem
    seen, uniq = set(), []
    for x in out:
        if x["linha"] not in seen:
            seen.add(x["linha"]); uniq.append(x)
    return uniq


def clean(s):
    s = re.sub(r"<[^>]+>", "", s)
    s = s.replace("&nbsp;", " ").replace("&amp;", "&")
    return re.sub(r"\s+", " ", s).strip()


def parse_pagina(html):
    """Extrai info geral + horarios (sem itinerarios) de uma pagina de linha."""
    # corta tudo a partir de ITINERARIOS
    idx = html.find("ITINER")
    if idx > 0:
        html = html[:idx]

    info = {}
    m = re.search(r"<h3>.*?<strong>(.*?)</strong>", html, re.S)
    info["titulo"] = clean(m.group(1)) if m else ""
    for label, key in [("Ponto A:", "ponto_a"), ("Ponto B:", "ponto_b"),
                        ("Sentido:", "sentido"), ("Dias atendidos:", "dias"),
                        ("Empresa:", "empresa"), ("Obs:", "obs")]:
        m = re.search(re.escape(label) + r"</strong>(.*?)(?:<strong|<hr|<h5)", html, re.S)
        if not m:
            m = re.search(re.escape(label) + r"(.*?)(?:<strong|<hr|<h5|<br)", html, re.S)
        info[key] = clean(m.group(1)) if m else ""

    # localiza inicio dos HORARIOS
    h = html
    hi = h.find("HOR")
    if hi > 0:
        h = h[hi:]

    # marcadores de dia
    day_map = [("Dia", "util"), ("bado", "sabado"), ("Domingo", "domingo")]
    # encontra posicoes de cada bloco de dia
    day_positions = []
    for m in re.finditer(r"<strong>\s*(Dia[^<]*|S\w*bado|Domingo[^<]*)</strong>", h):
        txt = m.group(1)
        key = None
        for needle, k in day_map:
            if needle.lower() in txt.lower():
                key = k; break
        if key:
            day_positions.append((m.start(), key))
    day_positions.append((len(h), None))

    horarios = {}
    for i in range(len(day_positions) - 1):
        start, key = day_positions[i]
        end = day_positions[i + 1][0]
        block = h[start:end]
        # dentro do bloco: Ponto A (Ida) e Ponto B (Volta)
        seg = {}
        ponto_iter = list(re.finditer(r"<strong>\s*Ponto\s*</strong>\s*:?\s*([AB])", block))
        ponto_iter_pos = [(m.start(), m.group(1)) for m in ponto_iter]
        ponto_iter_pos.append((len(block), None))
        for j in range(len(ponto_iter_pos) - 1):
            ps, pt = ponto_iter_pos[j]
            pe = ponto_iter_pos[j + 1][0]
            sub = block[ps:pe]
            times = re.findall(r"(\d{2}:\d{2}):\d{2}", sub)
            direction = "ida" if pt == "A" else "volta"
            seg[direction] = times
        if seg:
            horarios[key] = seg
    return info, horarios


def main():
    linhas = listar_linhas()
    print(f"{len(linhas)} linhas encontradas", file=sys.stderr)
    result = []
    for i, ln in enumerate(linhas, 1):
        code = ln["linha"]
        try:
            html = get(f"{BASE}/site/transportes/linha/{code}").decode("utf-8")
            info, horarios = parse_pagina(html)
            result.append({
                "linha": code,
                "nome": ln["nome"] or info.get("titulo", ""),
                "titulo": info.get("titulo", ""),
                "ponto_a": info.get("ponto_a", ""),
                "ponto_b": info.get("ponto_b", ""),
                "sentido": info.get("sentido", ""),
                "dias": info.get("dias", ""),
                "empresa": info.get("empresa", ""),
                "obs": info.get("obs", ""),
                "horarios": horarios,
            })
            print(f"[{i}/{len(linhas)}] {code} OK "
                  f"({sum(len(v) for d in horarios.values() for v in d.values())} horarios)",
                  file=sys.stderr)
        except Exception as e:
            print(f"[{i}/{len(linhas)}] {code} FALHA: {e}", file=sys.stderr)
        time.sleep(0.3)

    today = datetime.date.today().isoformat()
    payload = {
        "data_versao": today,
        "gerado_em": datetime.datetime.now().isoformat(timespec="seconds"),
        "fonte": BASE + "/site/transportes",
        "total_linhas": len(result),
        "linhas": result,
    }
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    with open(OUT, "w", encoding="utf-8") as f:
        json.dump(payload, f, ensure_ascii=False, indent=1)
    print(f"OK -> {OUT} ({len(result)} linhas)", file=sys.stderr)


if __name__ == "__main__":
    main()
