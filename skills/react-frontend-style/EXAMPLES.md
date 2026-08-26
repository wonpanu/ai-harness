# React frontend style — examples

Avoid/prefer pairs for each rule in SKILL.md.

## Hook returns a named object, exposes handlers

Avoid — leaking the library result and raw setters:
```ts
export function useOrderList(filters: Filters) {
  const query = useQuery({ queryKey: key(filters), queryFn: () => service.list(filters) })
  return query // consumer digs into query.data?.items, query.isLoading...
}
```

Prefer — named values, derived flags computed here:
```ts
export function useOrderList(filters: Filters) {
  const query = useQuery({ queryKey: key(filters), queryFn: () => service.list(filters) })
  const orders = query.data ?? []
  return {
    orders,
    isLoading: query.isLoading,
    isError: query.isError,
    isEmpty: query.isSuccess && orders.length === 0,
    hasRows: orders.length > 0,
    refetch: query.refetch,
  }
}
```

## Grouped state + single patch updater

Avoid — one setter per field:
```ts
const [status, setStatus] = useState('pending')
const [dateRange, setDateRange] = useState<DateRange>()
const [page, setPage] = useState(1)
```

Prefer:
```ts
const [filter, setFilter] = useState<Filter>({ status: 'pending', page: 1 })
const updateFilter = useCallback(
  (patch: Partial<Filter>) => setFilter(previous => ({ ...previous, ...patch, page: patch.page ?? 1 })),
  [],
)
```

## Discriminated union over boolean flags

Avoid:
```ts
const [showCancel, setShowCancel] = useState(false)
const [showRefund, setShowRefund] = useState(false)
const [showDetail, setShowDetail] = useState(false) // 3 booleans, 8 states, 4 impossible
```

Prefer:
```ts
type OrderDialog =
  | { kind: 'closed' }
  | { kind: 'cancel'; order: Order }
  | { kind: 'refund'; order: Order }

const [dialog, setDialog] = useState<OrderDialog>({ kind: 'closed' })
const shouldShowCancel = dialog.kind === 'cancel'
```

## Gate component with early-return ladder

```tsx
export default function OrderResults() {
  const { orders, isLoading, isError, isEmpty } = useOrderList(filters)

  if (isLoading) return <OrderTableSkeleton />
  if (isError) return <OrderErrorState />
  if (isEmpty) return <OrderEmptyState />
  return <OrderResultsContent orders={orders} />
}
```
The orchestrator above this never sees `isLoading`; `OrderResultsContent` is pure.

## as const set with derived type

Avoid: `type OrderStatus = 'pending' | 'paid' | 'cancelled'` duplicated next to a values array.
Prefer:
```ts
export const ORDER_STATUS = {
  pending: 'pending',
  paid: 'paid',
  cancelled: 'cancelled',
} as const
export type OrderStatus = (typeof ORDER_STATUS)[keyof typeof ORDER_STATUS]
```

## Service factory over inline fetch

Avoid — component calls fetch and digs into the envelope:
```ts
const res = await fetch(`/api/orders?status=${status}`)
const json = await res.json()
setRows(json.data.items)
```

Prefer — injectable factory, mapped entities, consumer never sees the wire shape:
```ts
export function createOrderService(http: HttpService) {
  return {
    async list(filters: Filters): Promise<Order[]> {
      const res = await http.getWithParams<OrderListResponse>('/orders', toQueryParams(filters))
      return res.data.items.map(toOrderEntity)
    },
  }
}
export const orderService = createOrderService(httpService)
```

## Enum guard at the boundary

```ts
function toOrderStatus(value: string): OrderStatus {
  return value in ORDER_STATUS ? (value as OrderStatus) : ORDER_STATUS.pending
}
```
Never a bare `value as OrderStatus` on wire data.
