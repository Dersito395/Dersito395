import type { SimulationResult } from '../engine/riskEngine'
import { levelMeta } from './riskLevel'
import { COMPANY } from './contact'

const levelLabel: Record<string, string> = {
  baixo: 'Risco baixo',
  medio: 'Risco médio',
  alto: 'Risco alto',
  critico: 'Risco crítico',
}

export async function generateResultPdf(propertyTypeLabel: string, result: SimulationResult): Promise<void> {
  const { jsPDF } = await import('jspdf')
  const doc = new jsPDF({ unit: 'pt', format: 'a4' })
  const marginX = 48
  const pageWidth = doc.internal.pageSize.getWidth()
  const pageHeight = doc.internal.pageSize.getHeight()
  const maxWidth = pageWidth - marginX * 2
  let y = 56

  function ensureSpace(lines = 1, lineHeight = 14) {
    if (y + lines * lineHeight > pageHeight - 56) {
      doc.addPage()
      y = 56
    }
  }

  function heading(text: string, size = 14) {
    ensureSpace(2, size + 6)
    doc.setFont('helvetica', 'bold')
    doc.setFontSize(size)
    doc.text(text, marginX, y)
    y += size + 8
  }

  function paragraph(text: string, size = 10) {
    doc.setFont('helvetica', 'normal')
    doc.setFontSize(size)
    const lines = doc.splitTextToSize(text, maxWidth)
    ensureSpace(lines.length, size + 4)
    doc.text(lines, marginX, y)
    y += lines.length * (size + 4) + 4
  }

  doc.setFont('helvetica', 'bold')
  doc.setFontSize(18)
  doc.text('Check - Incêndios (Fire Command)', marginX, y)
  y += 22
  doc.setFont('helvetica', 'normal')
  doc.setFontSize(11)
  doc.text('Resultado do simulador de risco de incêndio', marginX, y)
  y += 14
  doc.setFontSize(9)
  doc.setTextColor(120)
  doc.text(new Date().toLocaleDateString('pt-BR'), marginX, y)
  doc.setTextColor(0)
  y += 24

  paragraph(`Tipo de imóvel avaliado: ${propertyTypeLabel}`, 11)

  heading(`Score geral de segurança: ${result.overallSafetyScore} / 100 — ${levelLabel[result.overallLevel]}`)

  heading('Score por ambiente', 12)
  for (const area of result.areaResults) {
    paragraph(`${area.label}: ${area.safetyScore}/100 (${levelMeta(area.level).label})`, 10)
    if (area.identifiedRisks.length > 0) {
      for (const risk of area.identifiedRisks) {
        paragraph(`  • ${risk}`, 9)
      }
    } else {
      paragraph('  • Nenhum risco relevante identificado', 9)
    }
  }

  y += 8
  heading('Equipamentos recomendados', 12)
  for (const { product, quantityNote } of result.recommendedProducts) {
    paragraph(`${product.name} — ${product.price}`, 10)
    paragraph(`  ${quantityNote}`, 9)
  }

  y += 12
  doc.setDrawColor(200)
  doc.line(marginX, y, pageWidth - marginX, y)
  y += 20
  paragraph(
    'Este resultado é uma ferramenta educativa e orientativa, com base nas classes de incêndio e diretrizes ' +
      'gerais do Corpo de Bombeiros de São Paulo. Não substitui vistoria técnica nem laudo (AVCB).',
    8,
  )
  paragraph(`${COMPANY.name} · CNPJ ${COMPANY.cnpj} · ${COMPANY.contact} · ${COMPANY.address}`, 8)

  doc.save('check-incendios-resultado.pdf')
}
