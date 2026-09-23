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

## Named boolean — for business conditions, not guards

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

Avoid — naming plain guards; the two names read as a contradiction:
```go
hasNoMessages := messages == nil
if hasNoMessages { messages = []Message{} }

lastID := ""
hasMessages := len(messages) > 0
if hasMessages { lastID = messages[len(messages)-1].ID }
```

Prefer — nil/empty guards inline:
```go
// the client iterates these; null would break it
if messages == nil { messages = []Message{} }

lastID := ""
if len(messages) > 0 { lastID = messages[len(messages)-1].ID }
```

## Extract only when reused

Avoid — single-use helpers that make the reader jump around:
```go
func (u *usecase) GetLatest(...) {
    page := pageFromOffset(params.Offset)
    list, err := u.repo.Get(ctx, buildRequest(params, page))
    // ...
    return toResponse(params.Offset, list)
}

func pageFromOffset(offset int) int { return offset/pageSize + 1 }
func buildRequest(...) Request { /* 8 lines, one caller */ }
```

Prefer — the flow in one place, top to bottom:
```go
func (u *usecase) GetLatest(...) {
    // client sends offset = messages.length, so it is always page-aligned
    page := params.Offset/pageSize + 1

    list, err := u.repo.Get(ctx, Request{Page: page, /* ... */})
    // ...
}
```

Extract when a second caller appears (`wrapModuleError` used on every error
path, `categoryOptions` shared by two mappers) or when the block is complex
enough to deserve its own tests.

## Assign, then guard — nil check first, classify inside

Avoid — inline init one-liners and a specific-error test ahead of the nil guard:
```go
user, err := u.userRepo.GetUserByEmail(ctx, email)
if errs.IsErrorCode(err, errcode.UserNotFound) {
    return entity.Login{}, invalidCredentials
}
if err != nil {
    return entity.Login{}, err
}
if err := bcrypt.CompareHashAndPassword(hash, password); err != nil {
    return entity.Login{}, invalidCredentials
}
```

Prefer — one shape everywhere, readable top to bottom:
```go
user, err := u.userRepo.GetUserByEmail(ctx, email)
if err != nil {
    if errs.IsErrorCode(err, errcode.UserNotFound) {
        return entity.Login{}, errInvalidCredentials
    }
    return entity.Login{}, err
}

err = bcrypt.CompareHashAndPassword(hash, password)
if err != nil {
    return entity.Login{}, errInvalidCredentials
}
```

## Canonical errors and contract values live at the top of the file

Avoid — a sentinel built mid-function, contract strings inline:
```go
func (u *authUsecase) Login(...) {
    invalidCredentials := errs.AppError{ErrorCode: "AUL01", Message: "invalid email or password"}
    // ...
    token, err := jwt.NewWithClaims(jwt.SigningMethodHS256, jwt.MapClaims{
        "iss": "message-center-russet",
        "exp": now.Add(24 * time.Hour).Unix(),
    })
```

Prefer — declared once, named for whose contract it is:
```go
// Explorer claims are ze-explorer's contract, copied from russet.
const (
    explorerTokenTTL    = 24 * time.Hour
    explorerTokenIssuer = "message-center-russet"
)

var errInvalidCredentials = errs.AppError{
    ErrorCode: errcode.ErrCodeAuthUsecaseLoginInvalidCredentials.ToString(),
    Message:   errcode.MessageInvalidCredentials,
}
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
