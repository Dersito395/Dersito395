import { BrowserRouter, Route, Routes } from 'react-router-dom'
import { ConnectionGate } from './components/ConnectionGate'
import { Layout } from './components/Layout'
import { Classification } from './pages/Classification'
import { Confirmation } from './pages/Confirmation'
import { FeedbackForm } from './pages/FeedbackForm'
import { Home } from './pages/Home'
import { ModelDashboard } from './pages/ModelDashboard'
import { NewFocus } from './pages/NewFocus'
import { OccurrenceDetail } from './pages/OccurrenceDetail'
import { Recommendation } from './pages/Recommendation'
import { RiskResult } from './pages/RiskResult'
import { Settings } from './pages/Settings'

function App() {
  return (
    <ConnectionGate>
      <BrowserRouter>
        <Routes>
          <Route element={<Layout />}>
            <Route path="/" element={<Home />} />
            <Route path="/novo" element={<NewFocus />} />
            <Route path="/ocorrencias/:id" element={<OccurrenceDetail />} />
            <Route path="/ocorrencias/:id/classificacao" element={<Classification />} />
            <Route path="/ocorrencias/:id/confirmacao" element={<Confirmation />} />
            <Route path="/ocorrencias/:id/risco" element={<RiskResult />} />
            <Route path="/ocorrencias/:id/recomendacao" element={<Recommendation />} />
            <Route path="/ocorrencias/:id/feedback" element={<FeedbackForm />} />
            <Route path="/modelo" element={<ModelDashboard />} />
            <Route path="/configuracoes" element={<Settings />} />
          </Route>
        </Routes>
      </BrowserRouter>
    </ConnectionGate>
  )
}

export default App
