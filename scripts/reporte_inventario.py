# -*- coding: utf-8 -*-
"""
Meat & Grill - Reporte diario de inventario en PDF.

Lo corre GitHub Actions de lunes a sabado a las 23:00 de Argentina.
Lee el inventario de Supabase, arma un PDF y lo manda por mail.

Necesita estas variables de entorno (se cargan como Secrets del repo):
    SUPABASE_URL        https://cnjbsrhpyxdvolysokzv.supabase.co
    SUPABASE_ANON_KEY   la key publicable (la misma que esta en index.html)
    MG_EMAIL            mail de la cuenta de Supabase que lee el inventario
    MG_PASSWORD         su password (el PIN + el sufijo mg)
    SMTP_USER           la casilla de Gmail desde la que sale el mail
    SMTP_PASSWORD       contraseña de aplicacion de Gmail (NO la del mail)
    DESTINATARIOS       a quien se le manda, separados por coma
"""
import io
import os
import sys
import json
import smtplib
import urllib.error
import urllib.request
from datetime import datetime, timedelta, timezone
from email.message import EmailMessage

from fpdf import FPDF
from fpdf.enums import XPos, YPos

# Argentina no tiene horario de verano desde 2009, asi que UTC-3 fijo alcanza.
AR = timezone(timedelta(hours=-3))

ROJO = (245, 28, 21)
AMBAR = (191, 125, 10)
VERDE = (56, 130, 62)
GRIS = (110, 110, 110)
NEGRO = (20, 20, 20)

CAJA_ORDEN = {'Semanal': 0, 'Mensual': 1}


# ============================================================
# Datos
# ============================================================
def pedir(url, token=None, key=None, metodo='GET', payload=None):
    datos = json.dumps(payload).encode('utf-8') if payload is not None else None
    req = urllib.request.Request(url, data=datos, method=metodo)
    req.add_header('apikey', key)
    req.add_header('Content-Type', 'application/json')
    if token:
        req.add_header('Authorization', 'Bearer ' + token)
    with urllib.request.urlopen(req, timeout=60) as r:
        return json.loads(r.read().decode('utf-8'))


def traer_datos(base, key, email, password, desde_iso):
    """Entra con la cuenta de reportes y baja productos y movimientos."""
    try:
        sesion = pedir(base + '/auth/v1/token?grant_type=password', key=key,
                       metodo='POST', payload={'email': email, 'password': password})
    except urllib.error.HTTPError as e:
        detalle = e.read().decode('utf-8', 'replace')[:300]
        raise SystemExit(
            'No pude entrar a Supabase con MG_EMAIL/MG_PASSWORD.\n'
            'Acordate que la password lleva el sufijo mg (PIN 4821 -> 4821mg).\n'
            'Respuesta de Supabase: ' + detalle)

    token = sesion['access_token']
    rol = (sesion.get('user', {}).get('user_metadata') or {}).get('role', '?')

    productos = pedir(base + '/rest/v1/products?select=*&order=category,name', token, key)
    movimientos = pedir(
        base + '/rest/v1/movements?select=*&ts=gte.' + desde_iso + '&order=ts.desc',
        token, key)

    if not productos:
        raise SystemExit(
            'La cuenta entro bien (rol: %s) pero no ve ningun producto. '
            'Seguramente le falta el rol correcto en la tabla employees.' % rol)

    return productos, movimientos, rol


# ============================================================
# Reglas de stock (tienen que coincidir con isLow() de index.html)
# ============================================================
def es_bajo(p):
    stock = p.get('stock')
    minimo = p.get('minimo')
    minimo = minimo if isinstance(minimo, (int, float)) else 1
    if not isinstance(stock, (int, float)):
        return False
    return stock <= minimo


def unidades_totales(p):
    f = p.get('factor')
    if isinstance(f, (int, float)) and f > 0 and isinstance(p.get('stock'), (int, float)):
        return int(p['stock'] * f)
    return None


# ============================================================
# PDF
# ============================================================
class Reporte(FPDF):
    def __init__(self, momento):
        super().__init__(orientation='P', unit='mm', format='A4')
        self.momento = momento
        self.set_auto_page_break(auto=True, margin=18)
        self.set_title('Meat & Grill - Inventario %s' % momento.strftime('%d/%m/%Y'))

    def header(self):
        logo = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 'logo.png')
        if os.path.exists(logo):
            self.image(logo, x=12, y=9, w=15)
        self.set_xy(31, 11)
        self.set_font('Helvetica', 'B', 15)
        self.set_text_color(*ROJO)
        self.cell(0, 6, 'MEAT & GRILL', new_x=XPos.LMARGIN, new_y=YPos.NEXT)
        self.set_x(31)
        self.set_font('Helvetica', '', 9)
        self.set_text_color(*GRIS)
        self.cell(0, 5, 'Inventario al %s' % self.momento.strftime('%d/%m/%Y a las %H:%M'),
                  new_x=XPos.LMARGIN, new_y=YPos.NEXT)
        self.ln(6)
        self.set_draw_color(225, 225, 225)
        self.line(12, self.get_y(), 198, self.get_y())
        self.ln(4)

    def footer(self):
        self.set_y(-14)
        self.set_font('Helvetica', '', 7.5)
        self.set_text_color(*GRIS)
        self.cell(0, 4, 'Reporte automatico de Meat & Grill  ·  pagina %s' % self.page_no(),
                  align='C')

    # ---- piezas reutilizables ----
    def titulo_seccion(self, texto, color=NEGRO):
        if self.get_y() > 250:
            self.add_page()
        self.ln(2)
        self.set_font('Helvetica', 'B', 12)
        self.set_text_color(*color)
        self.cell(0, 7, texto, new_x=XPos.LMARGIN, new_y=YPos.NEXT)
        self.ln(1)

    def encabezado_tabla(self):
        self.set_font('Helvetica', 'B', 8)
        self.set_text_color(255, 255, 255)
        self.set_fill_color(60, 60, 60)
        for ancho, txt, al in ((78, 'Producto', 'L'), (30, 'Unidad', 'L'),
                               (22, 'Stock', 'R'), (22, 'Minimo', 'R'), (34, 'Estado', 'C')):
            self.cell(ancho, 6, txt, border=0, align=al, fill=True)
        self.ln()

    def fila_producto(self, p, alterna):
        if self.get_y() > 262:
            self.add_page()
            self.encabezado_tabla()
        bajo = es_bajo(p)
        self.set_font('Helvetica', '', 8.5)
        self.set_text_color(*NEGRO)
        self.set_fill_color(247, 247, 247) if alterna else self.set_fill_color(255, 255, 255)

        u = unidades_totales(p)
        unidad = str(p.get('unit') or '')
        if u is not None:
            unidad = '%s (%d u.)' % (unidad, u)

        self.cell(78, 5.6, texto_pdf(p.get('name', ''))[:46], fill=True)
        self.cell(30, 5.6, texto_pdf(unidad)[:20], fill=True)
        self.cell(22, 5.6, str(p.get('stock', '')), align='R', fill=True)
        self.cell(22, 5.6, str(p.get('minimo', '')), align='R', fill=True)
        self.set_font('Helvetica', 'B', 8)
        self.set_text_color(*(AMBAR if bajo else VERDE))
        self.cell(34, 5.6, 'REPONER' if bajo else 'En stock', align='C', fill=True)
        self.ln()


def texto_pdf(s):
    """Las fuentes base del PDF son latin-1: cubren acentos y ñ, pero no
    emojis ni comillas tipograficas. Se limpia lo que no entra."""
    s = str(s or '')
    for malo, bueno in (('→', '->'), ('–', '-'), ('—', '-'),
                        ('‘', "'"), ('’', "'"), ('“', '"'),
                        ('”', '"'), ('·', '-')):
        s = s.replace(malo, bueno)
    return s.encode('latin-1', 'ignore').decode('latin-1')


def bloque_categorias(pdf, productos, categorias):
    for cat in categorias:
        items = [p for p in productos if p.get('category') == cat]
        if not items:
            continue
        faltan = sum(1 for p in items if es_bajo(p))
        if pdf.get_y() > 240:
            pdf.add_page()
        pdf.ln(2)
        pdf.set_font('Helvetica', 'B', 9.5)
        pdf.set_text_color(*NEGRO)
        pdf.cell(110, 6, texto_pdf(cat))
        pdf.set_font('Helvetica', '', 8.5)
        pdf.set_text_color(*(AMBAR if faltan else VERDE))
        pdf.cell(0, 6, '%d de %d para reponer' % (faltan, len(items)),
                 align='R', new_x=XPos.LMARGIN, new_y=YPos.NEXT)
        pdf.encabezado_tabla()
        for i, p in enumerate(sorted(items, key=lambda r: (not es_bajo(r), str(r.get('name'))))):
            pdf.fila_producto(p, i % 2 == 0)


def armar_pdf(productos, movimientos, momento):
    pdf = Reporte(momento)
    pdf.add_page()

    cocina = [p for p in productos if (p.get('menu') or 'Cocina') != 'Caja']
    caja = [p for p in productos if p.get('menu') == 'Caja']
    faltan = [p for p in productos if es_bajo(p)]

    # --- Resumen ---
    pdf.set_font('Helvetica', '', 10)
    pdf.set_text_color(*NEGRO)
    pdf.set_fill_color(245, 245, 245)
    pdf.cell(0, 9, '   %d productos  -  %d para reponer  -  %d en stock'
             % (len(productos), len(faltan), len(productos) - len(faltan)),
             fill=True, new_x=XPos.LMARGIN, new_y=YPos.NEXT)
    pdf.ln(3)

    # --- Cocina ---
    pdf.titulo_seccion('COCINA')
    cats_cocina = []
    for p in cocina:
        if p.get('category') not in cats_cocina:
            cats_cocina.append(p.get('category'))
    bloque_categorias(pdf, cocina, sorted(cats_cocina, key=lambda c: str(c)))

    # --- Caja, separada por periodo ---
    if caja:
        pdf.add_page()
        pdf.titulo_seccion('CAJA')
        for periodo in sorted({p.get('period') for p in caja},
                              key=lambda x: CAJA_ORDEN.get(x, 9)):
            delp = [p for p in caja if p.get('period') == periodo]
            pdf.ln(1)
            pdf.set_font('Helvetica', 'B', 10)
            pdf.set_text_color(*ROJO)
            pdf.cell(0, 6, 'Conteo %s' % texto_pdf(periodo or 'sin periodo'),
                     new_x=XPos.LMARGIN, new_y=YPos.NEXT)
            cats = []
            for p in delp:
                if p.get('category') not in cats:
                    cats.append(p.get('category'))
            bloque_categorias(pdf, delp, sorted(cats, key=lambda c: str(c)))

    # --- Movimientos del dia ---
    pdf.add_page()
    pdf.titulo_seccion('MOVIMIENTOS DEL DIA')
    if not movimientos:
        pdf.set_font('Helvetica', 'I', 9)
        pdf.set_text_color(*GRIS)
        pdf.cell(0, 6, 'No se registro ningun movimiento hoy.',
                 new_x=XPos.LMARGIN, new_y=YPos.NEXT)
    else:
        pdf.set_font('Helvetica', 'B', 8)
        pdf.set_text_color(255, 255, 255)
        pdf.set_fill_color(60, 60, 60)
        for ancho, txt, al in ((16, 'Hora', 'L'), (34, 'Quien', 'L'), (62, 'Producto', 'L'),
                               (26, 'Tipo', 'L'), (24, 'Cant.', 'R'), (24, 'Queda', 'R')):
            pdf.cell(ancho, 6, txt, align=al, fill=True)
        pdf.ln()
        for i, m in enumerate(movimientos):
            if pdf.get_y() > 262:
                pdf.add_page()
            pdf.set_font('Helvetica', '', 8.5)
            pdf.set_text_color(*NEGRO)
            pdf.set_fill_color(247, 247, 247) if i % 2 == 0 else pdf.set_fill_color(255, 255, 255)
            try:
                hora = datetime.fromisoformat(m['ts'].replace('Z', '+00:00')).astimezone(AR).strftime('%H:%M')
            except Exception:
                hora = '--:--'
            tipo = str(m.get('type', ''))
            signo = {'ingreso': '+', 'salida': '-', 'conteo': '='}.get(tipo, '')
            pdf.cell(16, 5.6, hora, fill=True)
            pdf.cell(34, 5.6, texto_pdf(m.get('employee'))[:20], fill=True)
            pdf.cell(62, 5.6, texto_pdf(m.get('product_name'))[:36], fill=True)
            pdf.cell(26, 5.6, texto_pdf(tipo).capitalize(), fill=True)
            pdf.cell(24, 5.6, '%s%s' % (signo, m.get('qty', '')), align='R', fill=True)
            pdf.cell(24, 5.6, str(m.get('result_stock', '')), align='R', fill=True)
            pdf.ln()

    salida = pdf.output()
    return bytes(salida)


# ============================================================
# Mail
# ============================================================
def enviar(pdf_bytes, momento, resumen, smtp_user, smtp_pass, destinatarios):
    msg = EmailMessage()
    msg['Subject'] = 'Meat & Grill - Inventario del %s' % momento.strftime('%d/%m/%Y')
    msg['From'] = smtp_user
    msg['To'] = ', '.join(destinatarios)
    msg.set_content(
        'Inventario de Meat & Grill al %s.\n\n'
        '%s\n\n'
        'El detalle completo va en el PDF adjunto.\n\n'
        '-- \nReporte automatico. Se envia de lunes a sabado a las 23:00.\n'
        % (momento.strftime('%d/%m/%Y a las %H:%M'), resumen))
    msg.add_attachment(pdf_bytes, maintype='application', subtype='pdf',
                       filename='inventario-%s.pdf' % momento.strftime('%Y-%m-%d'))

    with smtplib.SMTP('smtp.gmail.com', 587, timeout=60) as s:
        s.starttls()
        s.login(smtp_user, smtp_pass)
        s.send_message(msg)


# ============================================================
def main():
    ahora = datetime.now(AR)

    # Red de seguridad: aunque el cron se corra de mas, los domingos no sale.
    if ahora.weekday() == 6:
        print('Hoy es domingo (%s), el local no abre. No se manda nada.'
              % ahora.strftime('%d/%m/%Y'))
        return 0

    faltantes = [v for v in ('SUPABASE_URL', 'SUPABASE_ANON_KEY', 'MG_EMAIL', 'MG_PASSWORD',
                             'SMTP_USER', 'SMTP_PASSWORD', 'DESTINATARIOS')
                 if not os.environ.get(v)]
    if faltantes:
        print('Faltan estos Secrets en el repo: ' + ', '.join(faltantes))
        return 1

    base = os.environ['SUPABASE_URL'].rstrip('/')
    desde = ahora.replace(hour=0, minute=0, second=0, microsecond=0)

    productos, movimientos, rol = traer_datos(
        base, os.environ['SUPABASE_ANON_KEY'],
        os.environ['MG_EMAIL'], os.environ['MG_PASSWORD'],
        desde.astimezone(timezone.utc).isoformat())

    faltan = sum(1 for p in productos if es_bajo(p))
    resumen = ('%d productos en total, %d para reponer, %d en stock. '
               '%d movimientos hoy.' % (len(productos), faltan,
                                        len(productos) - faltan, len(movimientos)))
    print('Cuenta de lectura OK (rol: %s)' % rol)
    print(resumen)

    pdf = armar_pdf(productos, movimientos, ahora)
    print('PDF armado: %.1f KB' % (len(pdf) / 1024))

    destinatarios = [d.strip() for d in os.environ['DESTINATARIOS'].split(',') if d.strip()]
    enviar(pdf, ahora, resumen, os.environ['SMTP_USER'],
           os.environ['SMTP_PASSWORD'], destinatarios)
    print('Mail enviado a: ' + ', '.join(destinatarios))
    return 0


if __name__ == '__main__':
    sys.exit(main())
