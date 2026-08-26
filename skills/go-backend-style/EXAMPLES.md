# Go backend style — examples

Avoid/prefer pairs for each rule in SKILL.md.

## Guard ladder, never else

Avoid — nested:
```go
resp, err := r.client.Get(url)
if err == nil {
    if resp.StatusCode() == 200 {
        if resp.Body != nil {
            return resp.ToEntity(), nil
        } else {
            return nil, errEmptyBody
        }
    } else { /* ... */ }
} else { /* ... */ }
```

Prefer — flat ladder, each guard returns:
```go
resp, err := r.client.Get(url)
if err != nil {
    return nil, errs.New(errcode.OrderFetchFailed, err)
}
if resp.StatusCode() == http.StatusNotFound {
    return nil, errs.New(errcode.OrderNotFound, err)
}
if resp.Body == nil {
    return nil, errs.New(errcode.OrderEmptyBody, err)
}
return resp.ToEntity(), nil
```

## Descriptive names

Avoid: `maxAmt float64`, `gwBase string`
Prefer: `maximumRefundAmount float64`, `paymentGatewayBaseURL string`

## Named boolean

Avoid — condition re-derived at every branch:
```go
if order.Type != nil && *order.Type == "express" { order.Queue = expressQueue }
// ...later...
if order.Type != nil && *order.Type == "express" { span.SetAttributes(...) }
```

Prefer — test once, branch on the name:
```go
isExpress := order.Type != nil && *order.Type == "express"
if isExpress { order.Queue = expressQueue }
// ...later...
if isExpress { span.SetAttributes(...) }
```

## Initialism casing

Avoid: `UserId`, `ProfileImageUrl`, `ApiKeyExpireAt`
Prefer: `UserID`, `ProfileImageURL`, `APIKeyExpireAt`
Exception — wire-mirror struct matches upstream JSON verbatim:
```go
type orderResponse struct {
    TrackingUrl string `json:"trackingUrl"` // upstream casing kept
}
```

## Constructor returns interface

```go
type IOrdersUsecase interface { Get(ctx context.Context, id string) (*entity.Order, error) }

type ordersUsecase struct{ repo IOrdersRepo } // unexported concrete

func NewOrdersUsecase(repo IOrdersRepo) IOrdersUsecase {
    return &ordersUsecase{repo: repo}
}
```

## Why-comment

Avoid: `// loop over orders` above a range loop.
Prefer:
```go
// express orders skip the nightly batch; route them
// to the priority queue so same-day delivery holds
if isExpress {
    order.Queue = expressQueue
}
```

## Test shape

```go
package orders_test

func TestGetOrder(t *testing.T) {
    var (
        mockRepo *mocks.IOrdersRepo
        usecase  usecase.IOrdersUsecase
    )
    beforeEach := func() {
        mockRepo = mocks.NewIOrdersRepo(t)
        usecase = usecase.NewOrdersUsecase(mockRepo)
    }

    t.Run("should route express order to priority queue", func(t *testing.T) {
        beforeEach()
        // Arrange
        mockRepo.EXPECT().Get(mock.Anything, "order-1").Return(expressOrder(), nil)
        // Act
        order, err := usecase.Get(ctx, "order-1")
        // Assert
        assert.NoError(t, err)
        assert.Equal(t, expressQueue, order.Queue)
    })
}
```
