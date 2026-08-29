import { BrowserRouter, Route, Routes } from 'react-router-dom'
import { Layout } from './components/Layout'
import { Welcome } from './pages/Welcome'
import { PropertyType } from './pages/PropertyType'
import { AreaSelection } from './pages/AreaSelection'
import { Questions } from './pages/Questions'
import { Processing } from './pages/Processing'
import { Results } from './pages/Results'
import { Storefront } from './pages/Storefront'
import { ProductDetail } from './pages/ProductDetail'

function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route element={<Layout />}>
          <Route path="/" element={<Welcome />} />
          <Route path="/tipo-imovel" element={<PropertyType />} />
          <Route path="/areas" element={<AreaSelection />} />
          <Route path="/perguntas" element={<Questions />} />
          <Route path="/processando" element={<Processing />} />
          <Route path="/resultado" element={<Results />} />
          <Route path="/produtos" element={<Storefront />} />
          <Route path="/produtos/:id" element={<ProductDetail />} />
        </Route>
      </Routes>
    </BrowserRouter>
  )
}

export default App
