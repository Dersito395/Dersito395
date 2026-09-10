import {
  AlertTriangle,
  BarChart3,
  Camera,
  Check,
  ClipboardList,
  Droplets,
  Flame,
  ListTree,
  MapPin,
  Plane,
  Radio,
  Settings,
  Tractor,
  Truck,
  Users,
  type LucideProps,
} from 'lucide-react'

const iconMap = {
  AlertTriangle,
  BarChart3,
  Camera,
  Check,
  ClipboardList,
  Droplets,
  Flame,
  ListTree,
  MapPin,
  Plane,
  Radio,
  Settings,
  Tractor,
  Truck,
  Users,
} as const

export type IconName = keyof typeof iconMap

export function Icon({ name, ...props }: { name: string } & LucideProps) {
  const Cmp = iconMap[name as IconName] ?? Flame
  return <Cmp {...props} />
}
