import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { Button } from '../components/Button'
import { Card, SectionTitle } from '../components/Card'
import { Field, Select, TextArea, TextInput } from '../components/Field'
import { useOccurrenceStore } from '../store/occurrenceStore'
import type { FocusSource } from '../types/domain'

export function NewFocus() {
  const navigate = useNavigate()
  const createFocus = useOccurrenceStore((s) => s.createFocus)

  const [source, setSource] = useState<FocusSource>('manual')
  const [lat, setLat] = useState('')
  const [lng, setLng] = useState('')
  const [soilHumidity, setSoilHumidity] = useState('35')
  const [mediaNote, setMediaNote] = useState('')

  function handleSubmit() {
    const id = createFocus({
      source,
      coordinates: lat && lng ? { lat: Number(lat), lng: Number(lng) } : undefined,
      soilHumidityPercent: Number(soilHumidity),
      mediaNote: mediaNote || undefined,
    })
    navigate(`/ocorrencias/${id}/classificacao`)
  }

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-xl font-bold">Novo foco</h1>
        <p className="text-slate-400 text-sm mt-1">Etapa 1 de 6 — dados de entrada do foco de fumaça.</p>
      </div>

      <Card>
        <SectionTitle>Origem</SectionTitle>
        <Field label="Como este foco chegou?">
          <Select value={source} onChange={(e) => setSource(e.target.value as FocusSource)}>
            <option value="manual">Inserção manual pelo operador</option>
            <option value="api_monitoramento">API do software de monitoramento (simulado)</option>
          </Select>
        </Field>

        <SectionTitle>Localização</SectionTitle>
        <div className="grid grid-cols-2 gap-3">
          <Field label="Latitude">
            <TextInput type="number" step="0.0001" placeholder="-22.1234" value={lat} onChange={(e) => setLat(e.target.value)} />
          </Field>
          <Field label="Longitude">
            <TextInput type="number" step="0.0001" placeholder="-48.5678" value={lng} onChange={(e) => setLng(e.target.value)} />
          </Field>
        </div>

        <SectionTitle>Condições ambientais</SectionTitle>
        <Field label="Umidade do solo na região (%)" help="Via sensor de solo ou API meteorológica/agro — ou inserção manual.">
          <TextInput type="number" min={0} max={100} value={soilHumidity} onChange={(e) => setSoilHumidity(e.target.value)} />
        </Field>

        <SectionTitle>Imagem/vídeo do foco</SectionTitle>
        <Field label="Descrição da foto/vídeo" help="MVP: descreva o que a imagem mostra. Numa integração real, isto viria do upload da foto/vídeo do foco.">
          <TextArea placeholder="Ex.: coluna de fumaça densa, próxima a talhão de eucalipto..." value={mediaNote} onChange={(e) => setMediaNote(e.target.value)} />
        </Field>
      </Card>

      <Button onClick={handleSubmit} disabled={!soilHumidity}>
        Avançar para classificação da fumaça
      </Button>
    </div>
  )
}
