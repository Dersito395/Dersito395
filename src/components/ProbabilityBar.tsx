export function ProbabilityBar({ label, percent, rank }: { label: string; percent: number; rank: number }) {
  return (
    <div className="mb-3">
      <div className="flex justify-between text-sm mb-1">
        <span className={rank === 0 ? 'font-semibold text-slate-100' : 'text-slate-300'}>{label}</span>
        <span className="text-slate-400">{percent.toFixed(1)}%</span>
      </div>
      <div className="h-2 rounded-full bg-slate-800 overflow-hidden">
        <div
          className={`h-full rounded-full ${rank === 0 ? 'bg-gradient-to-r from-orange-500 to-red-500' : 'bg-slate-600'}`}
          style={{ width: `${percent}%` }}
        />
      </div>
    </div>
  )
}
