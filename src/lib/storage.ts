/** Utilitário genérico de persistência local (sem backend neste MVP standalone). */
export function loadFromStorage<T>(key: string, fallback: T): T {
  try {
    const raw = localStorage.getItem(key)
    return raw ? (JSON.parse(raw) as T) : fallback
  } catch {
    return fallback
  }
}

export function saveToStorage<T>(key: string, value: T) {
  try {
    localStorage.setItem(key, JSON.stringify(value))
  } catch {
    // localStorage indisponível (modo privado, quota excedida) — falha silenciosa
  }
}
