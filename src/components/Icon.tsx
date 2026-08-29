import {
  BatteryCharging,
  BedDouble,
  Building2,
  Car,
  ChefHat,
  Factory,
  Flame,
  Home,
  Mountain,
  ShieldCheck,
  Sofa,
  Store,
  Trees,
  TreePine,
  WashingMachine,
  Warehouse,
  Zap,
  type LucideProps,
} from 'lucide-react'

const iconMap = {
  BatteryCharging,
  BedDouble,
  Building2,
  Car,
  ChefHat,
  Factory,
  Flame,
  Home,
  Mountain,
  ShieldCheck,
  Sofa,
  Store,
  Trees,
  TreePine,
  WashingMachine,
  Warehouse,
  Zap,
} as const

export type IconName = keyof typeof iconMap

export function Icon({ name, ...props }: { name: string } & LucideProps) {
  const Cmp = iconMap[name as IconName] ?? Flame
  return <Cmp {...props} />
}
