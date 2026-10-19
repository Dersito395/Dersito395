#!/usr/bin/env python3
"""Gera as ilustrações originais (SVG) da biblioteca essencial.

Todas as figuras são desenhos vetoriais originais do projeto SOBREVIVA,
licenciadas sob CC BY 4.0. Rode: python3 tools/make_illustrations.py
"""
import os

OUT = os.path.join(os.path.dirname(__file__), '..', 'content', 'media')
G, DK, GR, WH, OR, BL, RD = '#364536', '#1D2922', '#242827', '#F7F7F3', '#E58A32', '#3E7CB1', '#B23A30'
FONT = "font-family='Roboto'"


def frame(title, body, h=260):
    return (f"<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 400 {h}' width='400' height='{h}'>"
            f"<rect x='0' y='0' width='400' height='{h}' rx='14' fill='{WH}'/>"
            f"<rect x='0' y='0' width='400' height='34' rx='14' fill='{G}'/><rect x='0' y='20' width='400' height='14' fill='{G}'/>"
            f"<text x='16' y='23' {FONT} font-size='15' font-weight='700' fill='{WH}'>{title}</text>"
            f"{body}</svg>")


def t(x, y, s, size=13, color=GR, weight='400', anchor='start'):
    return f"<text x='{x}' y='{y}' {FONT} font-size='{size}' font-weight='{weight}' fill='{color}' text-anchor='{anchor}'>{s}</text>"


def badge(x, y, s, w=None):
    w = w or (len(s) * 7.6 + 18)
    return (f"<rect x='{x}' y='{y}' width='{w}' height='26' rx='13' fill='{OR}'/>"
            + t(x + w / 2, y + 18, s, 13, DK, '700', 'middle'))


def step(n, x, y):
    return f"<circle cx='{x}' cy='{y}' r='12' fill='{OR}'/>" + t(x, y + 5, str(n), 13, DK, '700', 'middle')


def clock(cx, cy, r=26, label=''):
    return (f"<circle cx='{cx}' cy='{cy}' r='{r}' fill='none' stroke='{GR}' stroke-width='3'/>"
            f"<line x1='{cx}' y1='{cy}' x2='{cx}' y2='{cy - r + 7}' stroke='{GR}' stroke-width='3' stroke-linecap='round'/>"
            f"<line x1='{cx}' y1='{cy}' x2='{cx + r - 10}' y2='{cy}' stroke='{OR}' stroke-width='3' stroke-linecap='round'/>"
            + t(cx, cy + r + 18, label, 13, GR, '700', 'middle'))


def tree(x, base, h=120, dead=False):
    trunk = f"<rect x='{x - 7}' y='{base - h}' width='14' height='{h}' fill='#6B4F35'/>"
    if dead:
        return trunk + f"<path d='M{x} {base - h + 20} l-30 -25 M{x} {base - h + 40} l28 -22' stroke='#6B4F35' stroke-width='6' stroke-linecap='round'/>"
    return trunk + f"<circle cx='{x}' cy='{base - h}' r='34' fill='{G}'/><circle cx='{x - 22}' cy='{base - h + 20}' r='22' fill='{G}'/><circle cx='{x + 22}' cy='{base - h + 20}' r='22' fill='{G}'/>"


def person(x, y, s=1.0, color=GR):
    return (f"<g transform='translate({x},{y}) scale({s})'><circle cx='0' cy='-58' r='10' fill='{color}'/>"
            f"<path d='M0 -46 L0 -14 M0 -38 L-16 -22 M0 -38 L16 -22 M0 -14 L-12 12 M0 -14 L12 12' stroke='{color}' stroke-width='6' stroke-linecap='round' fill='none'/></g>")


svgs = {}

svgs['agua-fervura.svg'] = frame('Fervura da água', (
    f"<rect x='50' y='120' width='150' height='90' rx='10' fill='{GR}'/>"
    f"<rect x='40' y='112' width='170' height='14' rx='6' fill='{DK}'/>"
    f"<rect x='58' y='132' width='134' height='70' rx='6' fill='{BL}'/>"
    + ''.join(f"<circle cx='{x}' cy='{y}' r='{r}' fill='{WH}' opacity='0.9'/>" for x, y, r in [(80, 150, 7), (110, 170, 9), (140, 148, 6), (170, 175, 8), (95, 190, 5), (155, 160, 5)])
    + f"<path d='M80 100 q10 -20 0 -40 M125 100 q10 -20 0 -40 M170 100 q10 -20 0 -40' stroke='{GR}' stroke-width='3' fill='none' opacity='0.5'/>"
    f"<path d='M70 222 q15 -18 30 0 q15 -18 30 0 q15 -18 30 0' fill='{OR}'/>"
    + clock(300, 105, 30, '1 minuto') + badge(212, 166, 'Acima de 2.000 m: 3 min', 180)
    + t(232, 220, 'Fervura vigorosa, com', 12) + t(232, 236, 'bolhas grandes e contínuas', 12)))

svgs['agua-cloro.svg'] = frame('Cloração com hipoclorito 2,5%', (
    f"<path d='M70 70 h24 v40 l14 30 h-52 l14 -30z' fill='{GR}'/><rect x='66' y='58' width='32' height='16' rx='4' fill='{OR}'/>"
    f"<path d='M82 150 q-6 10 0 16 q6 -6 0 -16z' fill='{BL}'/><path d='M82 175 q-6 10 0 16 q6 -6 0 -16z' fill='{BL}'/>"
    f"<rect x='150' y='90' width='70' height='130' rx='16' fill='none' stroke='{GR}' stroke-width='4'/><rect x='170' y='76' width='30' height='18' rx='4' fill='{GR}'/>"
    f"<rect x='154' y='120' width='62' height='96' rx='12' fill='{BL}' opacity='0.6'/>" + t(185, 175, '1 L', 18, DK, '700', 'middle')
    + badge(48, 205, '2 gotas', 80) + clock(310, 105, 30, '30 minutos')
    + t(250, 190, 'Misture e espere', 12) + t(250, 206, '30 min antes de beber', 12) + t(250, 230, 'Consumir em até 24 h', 12, G, '700')))

svgs['agua-sodis.svg'] = frame('Desinfecção solar (SODIS)', (
    f"<circle cx='330' cy='80' r='30' fill='{OR}'/>"
    + ''.join(f"<line x1='{330 + 42 * c}' y1='{80 + 42 * s}' x2='{330 + 56 * c}' y2='{80 + 56 * s}' stroke='{OR}' stroke-width='4' stroke-linecap='round'/>" for c, s in [(1, 0), (-1, 0), (0, 1), (0, -1), (.7, .7), (-.7, .7), (.7, -.7), (-.7, -.7)])
    + f"<path d='M20 230 L200 150 L380 230 Z' fill='{GR}'/>"
    + ''.join(f"<g transform='rotate(-24 {x} {y})'><rect x='{x}' y='{y}' width='70' height='24' rx='10' fill='{BL}' opacity='0.75' stroke='{DK}' stroke-width='2'/><rect x='{x + 70}' y='{y + 6}' width='10' height='12' fill='{DK}'/></g>" for x, y in [(70, 196), (130, 170)])
    + t(16, 62, 'Garrafas PET transparentes', 12, GR, '700') + t(16, 78, 'até 2 litros, água limpa', 12)
    + badge(16, 92, 'Sol forte: 6 horas', 132) + badge(16, 124, 'Muito nublado: 2 dias', 160)))

svgs['abrigo-lona-a.svg'] = frame("Abrigo em 'A' com lona", (
    tree(50, 230, 140) + tree(350, 230, 140)
    + f"<line x1='57' y1='140' x2='343' y2='140' stroke='{OR}' stroke-width='3'/>"
    + f"<path d='M110 140 L290 140 L330 228 L70 228 Z' fill='{G}' opacity='0.35'/>"
    f"<path d='M110 140 L70 228 M290 140 L330 228' stroke='{G}' stroke-width='4'/>"
    f"<path d='M110 140 L150 228 L250 228 L290 140' fill='{G}' opacity='0.85'/>"
    + ''.join(f"<line x1='{x}' y1='228' x2='{x2}' y2='236' stroke='{GR}' stroke-width='3'/><rect x='{x2 - 3}' y='230' width='6' height='14' fill='{DK}'/>" for x, x2 in [(70, 58), (150, 150), (250, 250), (330, 342)])
    + f"<line x1='100' y1='140' x2='100' y2='162' stroke='{BL}' stroke-width='2'/>" + t(14, 196, 'cordel de', 10) + t(14, 208, 'gotejamento', 10)
    + t(200, 128, 'corda da cumeeira (~1 m do chão)', 12, GR, '700', 'middle')
    + f"<rect x='0' y='228' width='400' height='32' rx='0' fill='#8A7A5C' opacity='0.35'/>"
    + t(200, 252, 'Abertura de costas para o vento • isolante no chão', 12, DK, '700', 'middle')))

svgs['abrigo-terreno.svg'] = frame('Onde montar o abrigo', (
    f"<path d='M0 200 Q100 120 200 160 T400 150 L400 260 L0 260 Z' fill='#C9C2A8'/>"
    f"<path d='M250 205 q40 10 80 0 q40 -10 70 0 L400 260 L250 260 Z' fill='{BL}' opacity='0.6'/>"
    + tree(320, 160, 90, dead=True)
    + f"<path d='M120 150 l26 -22 l26 22 z' fill='{G}'/>"
    + f"<circle cx='146' cy='112' r='16' fill='none' stroke='#2E8B57' stroke-width='4'/><path d='M138 112 l6 6 l11 -12' stroke='#2E8B57' stroke-width='4' fill='none'/>"
    + f"<circle cx='300' cy='230' r='14' fill='{RD}'/><path d='M294 224 l12 12 M306 224 l-12 12' stroke='{WH}' stroke-width='3'/>"
    + f"<circle cx='345' cy='60' r='14' fill='{RD}'/><path d='M339 54 l12 12 M351 54 l-12 12' stroke='{WH}' stroke-width='3'/>"
    + t(18, 60, 'BOM: plano, elevado,', 12, '#2E6B45', '700') + t(18, 76, 'drenado, protegido do vento', 12, '#2E6B45', '700')
    + t(160, 236, 'EVITE: leito de rio', 12, RD, '700') + t(170, 82, 'EVITE: árvores mortas', 12, RD, '700')))

svgs['rcp-maos.svg'] = frame('RCP: posição das mãos', (
    f"<ellipse cx='130' cy='160' rx='80' ry='60' fill='#E8D7C3'/><line x1='130' y1='110' x2='130' y2='200' stroke='#CDB59A' stroke-width='6'/>"
    f"<ellipse cx='130' cy='165' rx='30' ry='18' fill='{OR}' opacity='0.85'/><ellipse cx='130' cy='158' rx='26' ry='14' fill='#D9B38C' stroke='{GR}' stroke-width='2'/>"
    + t(130, 236, 'Centro do peito', 13, GR, '700', 'middle')
    + badge(240, 60, '100–120 / min', 120) + badge(240, 100, '5–6 cm', 80)
    + t(240, 150, 'Braços esticados,', 12) + t(240, 166, 'deixe o peito voltar', 12) + t(240, 182, 'totalmente', 12)
    + t(240, 214, 'Ligue 192 • Use o DEA', 13, RD, '700')))

svgs['engasgo.svg'] = frame('Engasgo: adulto e criança > 1 ano', (
    step(1, 30, 60) + t(48, 65, '5 golpes nas costas', 13, GR, '700')
    + person(100, 210, 1.3) + f"<rect x='64' y='150' width='24' height='14' rx='5' fill='{OR}'/><path d='M60 157 h-16' stroke='{OR}' stroke-width='4'/>"
    + f"<path d='M200 50 v190' stroke='#D0CEC4' stroke-width='2' stroke-dasharray='6 6'/>"
    + step(2, 214, 60) + t(230, 65, '5 compressões no abdome', 12, GR, '700')
    + person(300, 210, 1.3) + f"<circle cx='300' cy='182' r='9' fill='{OR}'/><path d='M300 176 l0 -18' stroke='{OR}' stroke-width='4' marker-end='url(#a)'/>"
    + f"<defs><marker id='a' markerWidth='8' markerHeight='8' refX='4' refY='4' orient='auto'><path d='M0 0 L8 4 L0 8 z' fill='{OR}'/></marker></defs>"
    + t(200, 250, 'Alterne até o objeto sair • desmaiou = RCP', 12, RD, '700', 'middle')))

svgs['hemorragia.svg'] = frame('Controle de sangramento', (
    f"<rect x='40' y='120' width='160' height='60' rx='28' fill='#E8D7C3'/><ellipse cx='120' cy='150' rx='14' ry='8' fill='{RD}'/>"
    f"<rect x='92' y='110' width='56' height='36' rx='8' fill='{WH}' stroke='{GR}' stroke-width='2'/>"
    f"<path d='M100 92 v18 M140 92 v18' stroke='{GR}' stroke-width='6' stroke-linecap='round'/>"
    + step(1, 40, 70) + t(58, 75, 'Pressão direta e firme', 13, GR, '700')
    + f"<rect x='230' y='120' width='150' height='60' rx='28' fill='#E8D7C3'/><ellipse cx='340' cy='150' rx='12' ry='7' fill='{RD}'/>"
    f"<rect x='270' y='116' width='16' height='68' rx='4' fill='{OR}'/>"
    + step(2, 240, 70) + t(258, 75, 'Torniquete (membros)', 13, GR, '700')
    + f"<path d='M286 200 h54' stroke='{GR}' stroke-width='2'/>" + t(313, 218, '5–7 cm', 12, GR, '700', 'middle')
    + t(200, 248, 'Ligue 192 • anote a hora do torniquete', 12, RD, '700', 'middle')))

svgs['queimadura.svg'] = frame('Queimadura: resfriar', (
    f"<rect x='80' y='60' width='70' height='20' rx='6' fill='{GR}'/><rect x='130' y='72' width='14' height='26' fill='{GR}'/>"
    + ''.join(f"<line x1='{x}' y1='102' x2='{x}' y2='150' stroke='{BL}' stroke-width='3' opacity='0.8'/>" for x in (130, 137, 144))
    + f"<rect x='40' y='150' width='200' height='40' rx='20' fill='#E8D7C3'/><ellipse cx='137' cy='165' rx='26' ry='10' fill='{OR}' opacity='0.7'/>"
    + clock(310, 100, 30, '20 minutos') + t(260, 180, 'Água corrente,', 12) + t(260, 196, 'temperatura ambiente', 12)
    + t(20, 232, 'NÃO: gelo, pasta de dente, manteiga, pó de café', 12, RD, '700')))

svgs['tala.svg'] = frame('Imobilização com tala', (
    f"<rect x='40' y='120' width='320' height='44' rx='22' fill='#E8D7C3'/>"
    f"<rect x='60' y='100' width='260' height='16' rx='4' fill='{G}'/><rect x='60' y='168' width='260' height='16' rx='4' fill='{G}'/>"
    + ''.join(f"<rect x='{x}' y='96' width='16' height='92' rx='4' fill='{OR}' opacity='0.9'/>" for x in (80, 180, 290))
    + f"<path d='M190 128 l10 18 l-10 10' stroke='{RD}' stroke-width='3' fill='none'/>"
    + t(200, 76, 'Tala cobre a articulação acima e abaixo', 13, GR, '700', 'middle')
    + t(200, 214, 'Imobilize na posição encontrada', 12, GR, '400', 'middle')
    + t(200, 234, 'Depois, confira cor e sensibilidade dos dedos', 12, G, '700', 'middle')))

svgs['hipotermia-envoltorio.svg'] = frame('Hipotermia: envoltório em camadas', (
    f"<rect x='40' y='190' width='320' height='16' rx='4' fill='{GR}'/>"
    f"<rect x='50' y='130' width='300' height='62' rx='30' fill='#C0C4C8'/>"
    f"<rect x='60' y='138' width='280' height='48' rx='24' fill='{G}'/>"
    f"<circle cx='86' cy='162' r='18' fill='#E8D7C3'/><path d='M70 152 q16 -16 32 0' fill='{OR}'/>"
    + ''.join(f"<rect x='{x}' y='150' width='22' height='22' rx='4' fill='{OR}'/>" for x in (150, 190))
    + t(40, 70, '1 Isolante sob o corpo', 12, GR, '700') + t(40, 88, '2 Roupas secas e cobertores', 12, GR, '700')
    + t(40, 106, '3 Plástico/manta por fora', 12, GR, '700') + t(230, 70, 'Calor no tórax,', 12, OR, '700')
    + t(230, 88, 'axilas e costas', 12, OR, '700') + t(200, 236, 'Não esfregue • sem álcool • manuseie com cuidado', 12, RD, '700', 'middle')))

svgs['calor-resfriamento.svg'] = frame('Golpe de calor: resfriar já', (
    f"<rect x='40' y='150' width='240' height='50' rx='10' fill='{BL}' opacity='0.5'/>"
    f"<circle cx='70' cy='160' r='16' fill='#E8D7C3'/><rect x='90' y='150' width='160' height='26' rx='13' fill='#E8D7C3'/>"
    + ''.join(f"<circle cx='{x}' cy='{y}' r='7' fill='{WH}' stroke='{BL}' stroke-width='3'/>" for x, y in [(90, 158), (120, 170), (200, 170)])
    + f"<path d='M320 90 l30 -20 l0 40 z' fill='{GR}'/>" + ''.join(f"<path d='M300 {y} q-10 6 -20 0' stroke='{GR}' stroke-width='3' fill='none'/>" for y in (80, 92, 104))
    + badge(30, 60, 'Ligue 192', 92) + t(30, 110, 'Imersão em água fria (ideal)', 12, GR, '700')
    + t(30, 128, 'ou molhar e abanar sem parar', 12) + t(30, 228, 'Frio no pescoço, axilas e virilha', 13, G, '700')))

svgs['peconhentos.svg'] = frame('Picada de animal peçonhento', (
    t(30, 66, 'FAÇA', 15, '#2E6B45', '700')
    + ''.join(t(30, 92 + 22 * i, '✓ ' + s, 12) for i, s in enumerate(['Lavar com água e sabão', 'Vítima deitada e em repouso', 'Retirar anéis e relógios', 'Ir já ao hospital / 192']))
    + f"<line x1='210' y1='50' x2='210' y2='240' stroke='#D0CEC4' stroke-width='2'/>"
    + t(225, 66, 'NÃO FAÇA', 15, RD, '700')
    + ''.join(t(225, 92 + 22 * i, '✕ ' + s, 12) for i, s in enumerate(['Torniquete', 'Cortar ou furar', 'Chupar o veneno', 'Folhas, café, terra', 'Álcool']))
    + t(200, 240, 'Disque-Intoxicação 0800 722 6001', 12, G, '700', 'middle')))

svgs['bussola-partes.svg'] = frame('Partes da bússola de placa', (
    f"<rect x='120' y='50' width='120' height='196' rx='12' fill='#D9E3EA' stroke='{GR}' stroke-width='3'/>"
    f"<path d='M180 58 l14 30 h-28 z' fill='{OR}'/>"
    f"<circle cx='180' cy='170' r='52' fill='{WH}' stroke='{GR}' stroke-width='4'/>"
    + ''.join(f"<line x1='{180 + 46 * c}' y1='{170 + 46 * s}' x2='{180 + 52 * c}' y2='{170 + 52 * s}' stroke='{GR}' stroke-width='2'/>" for c, s in [(0, -1), (1, 0), (0, 1), (-1, 0), (.7, .7), (-.7, .7), (.7, -.7), (-.7, -.7)])
    + f"<path d='M180 128 l8 18 h-16 z' fill='none' stroke='{OR}' stroke-width='2'/><line x1='164' y1='140' x2='164' y2='205' stroke='{OR}' stroke-width='1.5'/><line x1='196' y1='140' x2='196' y2='205' stroke='{OR}' stroke-width='1.5'/>"
    f"<path d='M180 132 l7 38 h-14 z' fill='{RD}'/><path d='M180 208 l7 -38 h-14 z' fill='{GR}'/>"
    + t(250, 78, '① Seta de direção', 12, GR, '700') + t(250, 128, '② Limbo giratório', 12, GR, '700')
    + t(250, 150, '    (0–360°)', 12) + t(250, 190, '③ Agulha (norte', 12, GR, '700') + t(250, 206, '    vermelho)', 12)
    + t(14, 150, '④ Seta e linhas', 12, GR, '700') + t(14, 166, 'de orientação', 12)))

svgs['bussola-rumo.svg'] = frame('Medindo um rumo no mapa', (
    f"<rect x='20' y='46' width='360' height='200' fill='#EFEBDD' stroke='#CFC8B0'/>"
    + ''.join(f"<line x1='{x}' y1='46' x2='{x}' y2='246' stroke='{BL}' stroke-width='1' opacity='0.6'/>" for x in range(50, 380, 60))
    + f"<path d='M60 200 Q150 120 240 150 T360 90' fill='none' stroke='#B9A77E' stroke-width='2'/>"
    + f"<g transform='rotate(-35 210 150)'><rect x='150' y='130' width='170' height='44' rx='8' fill='#D9E3EA' opacity='0.9' stroke='{GR}' stroke-width='2'/><path d='M320 152 l-14 -8 v16 z' fill='{OR}'/><circle cx='200' cy='152' r='18' fill='{WH}' stroke='{GR}' stroke-width='2'/></g>"
    + f"<circle cx='120' cy='206' r='8' fill='{RD}'/>" + t(100, 232, 'A (você)', 12, GR, '700')
    + f"<circle cx='300' cy='80' r='8' fill='{G}'/>" + t(312, 76, 'B', 14, GR, '700')
    + t(40, 70, 'Linhas N-S do mapa', 11, BL, '700')))

svgs['pare-perdido.svg'] = frame('Perdido? Use o método PARE', ''.join(
    f"<rect x='{20 + 92 * i}' y='60' width='84' height='150' rx='12' fill='{G if i % 2 == 0 else DK}'/>"
    + t(62 + 92 * i, 112, l, 40, OR, '700', 'middle') + t(62 + 92 * i, 150, w, 12, WH, '700', 'middle')
    + t(62 + 92 * i, 170, d1, 10, WH, '400', 'middle') + t(62 + 92 * i, 184, d2, 10, WH, '400', 'middle')
    for i, (l, w, d1, d2) in enumerate([('P', 'PARE', 'sente, beba', 'água, respire'), ('A', 'ANALISE', 'último ponto', 'conhecido'), ('R', 'RECONHEÇA', 'terreno, luz,', 'clima, recursos'), ('E', 'ELABORE', 'fique visível,', 'peça socorro')]))
    + t(200, 240, 'Se alguém sabe seu roteiro: em geral, fique no lugar', 12, GR, '700', 'middle'))

svgs['fogo-triangulo.svg'] = frame('Triângulo do fogo', (
    f"<path d='M200 56 L320 226 L80 226 Z' fill='none' stroke='{OR}' stroke-width='10' stroke-linejoin='round'/>"
    f"<path d='M200 130 q-26 36 0 70 q26 -34 0 -70z' fill='{OR}'/><path d='M200 160 q-10 18 0 36 q10 -18 0 -36z' fill='#F4C27A'/>"
    + t(118, 140, 'CALOR', 14, GR, '700', 'end') + t(282, 140, 'OXIGÊNIO', 14, GR, '700') + t(200, 250, 'COMBUSTÍVEL', 14, GR, '700', 'middle')
    + t(300, 64, 'Retire um lado', 11, G, '700') + t(300, 78, 'e o fogo apaga', 11, G, '700')))

svgs['kit-72h.svg'] = frame('Kit de emergência', (
    f"<path d='M40 90 q0 -30 50 -30 h40 q50 0 50 30 v140 h-140 z' fill='{G}'/><rect x='60' y='120' width='100' height='60' rx='8' fill='{DK}'/>"
    + ''.join(t(200, 66 + 20 * i, '• ' + s, 12) for i, s in enumerate(['Água e comida', 'Lanterna e pilhas', 'Rádio a pilha/manivela', 'Primeiros socorros', 'Remédios e receitas', 'Apito, lona e fita', 'Documentos e dinheiro', 'Carregador e bateria', 'Roupas e manta']))
    + t(200, 250, 'Revise a cada 6 meses', 12, OR, '700')))

svgs['no-lais-de-guia.svg'] = frame('Lais de guia (alça fixa)', (
    step(1, 30, 60) + f"<path d='M70 240 V120 m0 0 c0 -30 40 -30 40 0 c0 30 -40 30 -40 0' fill='none' stroke='{OR}' stroke-width='7'/>" + f"<path d='M110 120 v80' stroke='{G}' stroke-width='7' fill='none'/>"
    + step(2, 160, 60) + f"<path d='M200 240 V120 c0 -30 40 -30 40 0 c0 30 -40 30 -40 0' fill='none' stroke='{OR}' stroke-width='7'/><path d='M240 210 v-90 q0 -30 -12 -40 q-30 10 -38 30' fill='none' stroke='{G}' stroke-width='7'/>"
    + step(3, 290, 60) + f"<path d='M330 240 V110' stroke='{OR}' stroke-width='7'/><path d='M330 110 q-22 0 -22 30 q0 50 22 70 q22 -20 22 -70 q0 -30 -22 -30' fill='none' stroke='{G}' stroke-width='7'/><circle cx='330' cy='110' r='12' fill='none' stroke='{OR}' stroke-width='6'/>"
    + t(200, 252, 'Volta • a ponta sobe pela volta, contorna e retorna', 11, GR, '700', 'middle')))

svgs['no-volta-fiel.svg'] = frame('Volta do fiel', (
    f"<rect x='180' y='40' width='40' height='210' rx='6' fill='#8A6A4A'/>"
    f"<path d='M40 120 H175 q15 0 25 10 q20 20 0 30 L170 150' fill='none' stroke='{OR}' stroke-width='8'/>"
    f"<path d='M175 150 q25 30 50 10 q20 -16 0 -30 L190 168 q30 30 40 20 L360 190' fill='none' stroke='{G}' stroke-width='8'/>"
    + t(30, 80, '1. Uma volta no suporte', 12, GR, '700') + t(230, 80, '2. Cruze por cima', 12, GR, '700')
    + t(230, 230, '3. Segunda volta e ponta', 12, GR, '700') + t(230, 246, 'por baixo do cruzamento', 12)))

svgs['enchente.svg'] = frame('Nunca atravesse água em movimento', (
    f"<rect x='0' y='150' width='400' height='110' fill='{BL}' opacity='0.45'/>"
    + ''.join(f"<path d='M{x} 165 q15 -8 30 0' stroke='{WH}' stroke-width='3' fill='none'/>" for x in range(10, 400, 50))
    + person(90, 222, 1.2)
    + f"<line x1='40' y1='196' x2='40' y2='224' stroke='{RD}' stroke-width='3'/>" + t(46, 190, '15 cm', 13, RD, '700')
    + f"<rect x='220' y='158' width='130' height='44' rx='12' fill='{GR}'/><rect x='240' y='138' width='80' height='26' rx='8' fill='{GR}'/><circle cx='250' cy='204' r='14' fill='{DK}'/><circle cx='320' cy='204' r='14' fill='{DK}'/>"
    + f"<line x1='370' y1='190' x2='370' y2='230' stroke='{RD}' stroke-width='3'/>" + t(350, 248, '30 cm', 13, RD, '700')
    + t(20, 62, 'derrubam uma pessoa', 12, GR, '700') + t(220, 62, 'arrastam um carro', 12, GR, '700')
    + f"<path d='M20 120 h360' stroke='{OR}' stroke-width='4' marker-end='url(#b)'/><defs><marker id='b' markerWidth='10' markerHeight='10' refX='5' refY='5' orient='auto'><path d='M0 0 L10 5 L0 10 z' fill='{OR}'/></marker></defs>"
    + t(200, 110, 'correnteza', 11, OR, '700', 'middle')))

svgs['deslizamento-sinais.svg'] = frame('Sinais de alerta de deslizamento', (
    f"<path d='M0 70 L230 70 L400 250 L0 250 Z' fill='#B9A77E'/>"
    + f"<g transform='rotate(12 120 150)'><rect x='110' y='80' width='10' height='70' fill='{GR}'/></g>" + t(140, 96, 'poste/árvore inclinando', 11, DK, '700')
    + f"<rect x='200' y='150' width='110' height='80' fill='{WH}' stroke='{GR}' stroke-width='3'/><path d='M200 150 l55 -40 l55 40' fill='{GR}'/>"
    + f"<path d='M230 170 l10 14 l-6 10 l12 16' stroke='{RD}' stroke-width='3' fill='none'/>" + t(322, 182, 'rachaduras', 11, RD, '700')
    + f"<path d='M60 220 q10 -10 20 0 q10 10 20 0' stroke='#7A5A30' stroke-width='5' fill='none'/>" + t(20, 244, 'água barrenta brotando', 11, DK, '700')
    + t(16, 56, 'Notou algum sinal? Saia já e ligue 199 ou 193', 12, RD, '700')))

svgs['sinais-resgate.svg'] = frame('Sinais de socorro', (
    t(20, 66, 'Padrão internacional: TRÊS', 13, GR, '700')
    + ''.join(f"<circle cx='{40 + 34 * i}' cy='96' r='12' fill='{OR}'/>" for i in range(3)) + t(150, 101, '3 apitos • 3 flashes • 3 fogueiras', 12)
    + f"<rect x='20' y='130' width='170' height='100' fill='#C9C2A8'/>" + t(105, 198, 'SOS', 48, DK, '700', 'middle') + t(105, 248, 'no solo, grande e contrastante', 11, GR, '700', 'middle')
    + f"<circle cx='300' cy='150' r='20' fill='{OR}'/><rect x='250' y='190' width='34' height='24' fill='#C0C4C8' stroke='{GR}' stroke-width='2'/><path d='M267 190 L300 150' stroke='{OR}' stroke-width='2' stroke-dasharray='4 4'/><path d='M267 202 L370 90' stroke='{OR}' stroke-width='3'/>"
    + t(300, 240, 'espelho: mire com os dedos em V', 11, GR, '700', 'middle')))

svgs['agua-reserva-tambores.svg'] = frame('Reserva de água de longo prazo', (
    f"<rect x='20' y='206' width='360' height='14' rx='3' fill='#8A6A4A'/>"
    + ''.join(f"<rect x='{x}' y='{206 - h}' width='{w}' height='{h}' rx='10' fill='{BL}' stroke='{DK}' stroke-width='3'/><rect x='{x + 8}' y='{216 - h}' width='{w - 16}' height='22' rx='4' fill='{WH}'/>" + t(x + w / 2, 232 - h, d, 11, DK, '700', 'middle') for x, w, h, d in [(30, 90, 140, '03/2026'), (135, 90, 140, '05/2026'), (240, 60, 90, '06/2026'), (310, 60, 90, '08/2026')])
    + f"<rect x='112' y='180' width='14' height='8' fill='{GR}'/>"
    + t(20, 246, 'Opacos, tampados, etiquetados, sobre estrado • troca a cada 6 meses', 11, GR, '700')
    + badge(232, 44, '2,5–3 L/pessoa/dia: beber', 160) + badge(232, 76, '15 L/pessoa/dia: + higiene', 160)))

svgs['despensa-rotacao.svg'] = frame('Rotação da despensa', (
    ''.join(f"<rect x='40' y='{y}' width='320' height='8' fill='#8A6A4A'/>" for y in (110, 180))
    + ''.join(f"<rect x='{60 + 52 * i}' y='{y - 46}' width='40' height='46' rx='6' fill='{G if i < 3 else OR}' opacity='{0.55 + 0.1 * i}'/>" for i in range(6) for y in (110, 180))
    + f"<path d='M372 70 h-30' stroke='{GR}' stroke-width='4' marker-end='url(#r1)'/><path d='M60 228 h-40' stroke='{RD}' stroke-width='4' marker-end='url(#r1)'/>"
    + f"<defs><marker id='r1' markerWidth='8' markerHeight='8' refX='4' refY='4' orient='auto'><path d='M0 0 L8 4 L0 8 z' fill='{GR}'/></marker></defs>"
    + t(200, 58, 'novo entra atrás', 12, GR, '700') + t(70, 244, 'mais antigo sai primeiro', 12, RD, '700')))

svgs['horta-canteiro.svg'] = frame('Canteiro elevado', (
    f"<rect x='0' y='196' width='400' height='64' fill='#7A5A30'/>"
    f"<path d='M70 196 L90 150 L310 150 L330 196 Z' fill='#5C4022'/>"
    f"<rect x='90' y='142' width='220' height='10' fill='#D9C27A'/>"
    + ''.join(f"<path d='M{x} 142 q-10 -26 0 -40 q10 14 0 40 M{x} 142 q-18 -18 -22 -30 M{x} 142 q18 -18 22 -30' stroke='{G}' stroke-width='5' fill='none'/>" for x in (125, 175, 225, 275))
    + f"<path d='M90 214 h220' stroke='{OR}' stroke-width='3' marker-start='url(#c1)' marker-end='url(#c1)'/><defs><marker id='c1' markerWidth='8' markerHeight='8' refX='4' refY='4' orient='auto-start-reverse'><path d='M0 0 L8 4 L0 8 z' fill='{OR}'/></marker></defs>"
    + t(200, 236, '≈ 1 m de largura', 13, WH, '700', 'middle') + t(16, 64, 'Terra afofada + composto', 12, GR, '700')
    + t(16, 82, 'Elevado 15–20 cm', 12, GR, '700') + t(250, 64, 'Palha cobre o solo', 12, GR, '700') + t(250, 82, 'Caminho ao lado', 12, GR, '700')))

svgs['compostagem.svg'] = frame('Compostagem em camadas', (
    f"<rect x='60' y='60' width='160' height='180' rx='6' fill='none' stroke='{GR}' stroke-width='4'/>"
    + ''.join(f"<rect x='64' y='{236 - 30 * (i + 1)}' width='152' height='30' fill='{'#C9A86A' if i % 2 == 0 else '#6B8E4E'}'/>" for i in range(5))
    + t(240, 100, 'Seco: folhas, palha,', 12, '#8A6A2A', '700') + t(240, 116, 'serragem (mais)', 12, '#8A6A2A', '700')
    + t(240, 150, 'Verde: cascas, borra', 12, '#3E6B2E', '700') + t(240, 166, 'de café, verduras', 12, '#3E6B2E', '700')
    + t(240, 206, 'Umidade de esponja', 12, GR, '700') + t(240, 222, 'Revirar a cada 1–2 sem.', 12, GR, '700')))

svgs['abrigo-duas-paredes.svg'] = frame('Regra das duas paredes', (
    f"<rect x='40' y='50' width='320' height='190' fill='none' stroke='{GR}' stroke-width='6'/>"
    f"<line x1='160' y1='50' x2='160' y2='240' stroke='{GR}' stroke-width='4'/><line x1='240' y1='50' x2='240' y2='240' stroke='{GR}' stroke-width='4'/>"
    f"<line x1='160' y1='145' x2='240' y2='145' stroke='{GR}' stroke-width='4'/>"
    + ''.join(f"<rect x='{x}' y='{y}' width='{w}' height='{h}' fill='{BL}' opacity='0.6'/>" for x, y, w, h in [(70, 46, 50, 8), (280, 46, 50, 8), (70, 236, 50, 8), (280, 236, 50, 8)])
    + f"<rect x='164' y='149' width='72' height='87' fill='{OR}' opacity='0.85'/>" + person(200, 228, 0.9, DK)
    + t(100, 150, 'janelas', 12, BL, '700', 'middle') + t(300, 150, 'janelas', 12, BL, '700', 'middle')
    + t(200, 100, 'corredor', 12, GR, '400', 'middle')))

svgs['quarentena-quarto.svg'] = frame('Isolamento de doente em casa', (
    f"<rect x='30' y='50' width='200' height='180' fill='none' stroke='{GR}' stroke-width='5'/>"
    f"<rect x='30' y='90' width='8' height='60' fill='{BL}'/>" + ''.join(f"<path d='M{x} 120 q-12 -6 -24 0' stroke='{BL}' stroke-width='3' fill='none'/>" for x in (20, 8))
    + f"<rect x='120' y='150' width='96' height='50' rx='6' fill='{G}'/><circle cx='140' cy='160' r='12' fill='#E8D7C3'/>"
    + f"<rect x='226' y='120' width='8' height='60' fill='{WH}' stroke='{GR}' stroke-width='2'/>"
    + person(300, 214, 1.0) + f"<rect x='290' y='150' width='20' height='10' rx='3' fill='{WH}' stroke='{GR}' stroke-width='1.5'/>"
    + t(40, 72, 'janela aberta', 11, BL, '700') + t(250, 76, '1 cuidador', 12, GR, '700') + t(250, 92, 'de máscara', 12, GR, '700')
    + t(30, 250, 'Sinais de gravidade (falta de ar, lábios roxos, confusão): 192', 11, RD, '700')))

svgs['fogo-arco-broca.svg'] = frame('Arco e broca: as peças', (
    f"<rect x='0' y='214' width='400' height='46' fill='#7A5A30'/>"
    f"<rect x='60' y='196' width='220' height='18' rx='3' fill='#C9A86A' stroke='{GR}' stroke-width='2'/>"
    f"<path d='M150 196 l12 0 l-4 18 l-4 0 z' fill='{DK}'/><ellipse cx='156' cy='222' rx='16' ry='5' fill='#3B2A18'/>"
    f"<rect x='150' y='92' width='12' height='104' rx='4' fill='#B08850' stroke='{GR}' stroke-width='2'/>"
    f"<rect x='130' y='72' width='52' height='20' rx='6' fill='#8A6A3A' stroke='{GR}' stroke-width='2'/>"
    f"<path d='M40 150 Q156 110 290 150' stroke='#6B4A22' stroke-width='6' fill='none'/>"
    f"<path d='M40 150 L156 140 L290 150' stroke='{GR}' stroke-width='2' fill='none'/>"
    + t(190, 86, 'apoio de mão (madeira dura/pedra)', 11, GR, '700') + t(298, 140, 'arco + cordão', 11, GR, '700')
    + t(170, 120, 'broca reta e seca', 11, GR, '700') + t(290, 206, 'base (madeira seca)', 11, GR, '700')
    + t(176, 236, 'entalhe em V + folha para a brasa', 11, WH, '700')
    + t(16, 60, 'Madeira macia e totalmente seca', 12, OR, '700')))

os.makedirs(OUT, exist_ok=True)
for name, svg in svgs.items():
    with open(os.path.join(OUT, name), 'w', encoding='utf-8') as fh:
        fh.write(svg)
print(f'{len(svgs)} ilustrações geradas em {os.path.abspath(OUT)}')
