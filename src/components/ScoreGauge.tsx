import { levelColors } from '../lib/riskLevel'
import type { RiskLevel } from '../types/domain'

export function ScoreGauge({ score, level, size = 140 }: { score: number; level: RiskLevel; size?: number }) {
  const meta = levelColors[level]
  const stroke = size * 0.09
  const radius = (size - stroke) / 2
  const circumference = 2 * Math.PI * radius
  const offset = circumference * (1 - score / 100)

  return (
    <div className="relative inline-flex items-center justify-center" style={{ width: size, height: size }}>
      <svg width={size} height={size} className="-rotate-90">
        <circle cx={size / 2} cy={size / 2} r={radius} stroke="#1e293b" strokeWidth={stroke} fill="none" />
        <circle
          cx={size / 2}
          cy={size / 2}
          r={radius}
          stroke={meta.ring}
          strokeWidth={stroke}
          fill="none"
          strokeLinecap="round"
          strokeDasharray={circumference}
          strokeDashoffset={offset}
          style={{ transition: 'stroke-dashoffset 1s ease-out' }}
        />
      </svg>
      <div className="absolute flex flex-col items-center">
        <span className={`text-3xl font-extrabold ${level === 'critico' ? 'text-red-500' : ''}`}>{score}</span>
        <span className="text-[10px] text-slate-500 uppercase tracking-wide">de 100</span>
      </div>
    </div>
  )
}
