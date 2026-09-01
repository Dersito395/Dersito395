export const WHATSAPP_NUMBER = '5514998619590'
export const WHATSAPP_DISPLAY = '(14) 99861-9590'

export function whatsappLink(message: string): string {
  return `https://wa.me/${WHATSAPP_NUMBER}?text=${encodeURIComponent(message)}`
}

export const COMPANY = {
  name: 'Fire Command (Brasil)',
  cnpj: '68.697.868/0001-21',
  contact: WHATSAPP_DISPLAY,
  address: 'Lençóis Paulista - SP - Brasil',
}
