// Formatação e parsing de valores monetários (pt-BR).

export function normalizeForSearch(text) {
  return (text || "")
    .toLowerCase()
    .normalize("NFD")
    .replace(/\p{Diacritic}/gu, "")
}

export function parseBrDecimal(raw) {
  if (raw == null) return null
  const s = String(raw).trim()
  if (s === "") return null

  let cleaned = s.replace(/\s/g, "").replace(/R\$/gi, "")
  if (cleaned.includes(",")) {
    cleaned = cleaned.replace(/\./g, "").replace(",", ".")
  } else {
    cleaned = cleaned.replace(/[^\d.-]/g, "")
  }

  const n = Number.parseFloat(cleaned)
  return Number.isFinite(n) ? n : null
}

export function formatBrMoney(value, { decimals = 2 } = {}) {
  const n = typeof value === "number" ? value : parseBrDecimal(value)
  if (n == null || !Number.isFinite(n)) return ""

  return n.toLocaleString("pt-BR", {
    minimumFractionDigits: decimals,
    maximumFractionDigits: decimals,
  })
}

export function formatBrQuantity(value) {
  const n = parseBrDecimal(value)
  if (n == null || !Number.isFinite(n)) return value ?? ""

  const decimals = Number.isInteger(n) ? 0 : Math.min(4, (String(n).split(".")[1] || "").length)
  return n.toLocaleString("pt-BR", {
    minimumFractionDigits: decimals,
    maximumFractionDigits: 4,
  })
}
