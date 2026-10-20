# When to Mock

Mock at **system boundaries** only:

- External APIs (payment, email, etc.)
- Databases (sometimes - prefer test DB)
- Time/randomness
- File system (sometimes)

Don't mock:

- Your own classes/modules
- Internal collaborators
- Anything you control

## Designing for Mockability

At system boundaries, design interfaces that are easy to mock:

**1. Use dependency injection**

Pass external dependencies in rather than creating them internally:

```typescript
// Easy to mock
function processPayment(order, paymentClient) {
  return paymentClient.charge(order.total);
}

// Hard to mock
function processPayment(order) {
  const client = new StripeClient(process.env.STRIPE_KEY);
  return client.charge(order.total);
}
```

**2. Prefer SDK-style interfaces over generic fetchers**

Create specific functions for each external operation instead of one generic function with conditional logic:

```typescript
// GOOD: Each function is independently mockable
const api = {
  getUser: (id) => fetch(`/users/${id}`),
  getOrders: (userId) => fetch(`/users/${userId}/orders`),
  createOrder: (data) => fetch('/orders', { method: 'POST', body: data }),
};

// BAD: Mocking requires conditional logic inside the mock
const api = {
  fetch: (endpoint, options) => fetch(endpoint, options),
};
```

The SDK approach means:
- Each mock returns one specific shape
- No conditional logic in test setup
- Easier to see which endpoints a test exercises
- Type safety per endpoint

## Verifying calls

A mock that only feeds results lets a test pass when the code under test never reached it: `NoError` and a status-only body look the same whether the collaborator ran or not. Every subtest states what it expects of the calls it owns:

- The path reaches the call → assert it was called with the literal arguments (`AssertCalled(t, "CreateProject", …)`, `expect(client.charge).toHaveBeenCalledWith(…)`). The arguments are the contract, not just the fact of the call.
- A guard cuts the path first → assert it was not called (`AssertNotCalled`, `not.toHaveBeenCalled()`).
- A result that only the stub could have produced (an error code, a mapped body) is implicit proof of the call, but not of the arguments; add the explicit assertion when the arguments carry a rule (`CreatedBy: userID`).

Prefer plain mocks you verify yourself over self-verifying mocks (`mocks.NewIX(t)`) that assert every stub was used: a shared `beforeEach` stubs the whole happy path, and the self-verifying variant then forces an "optional" marker (`.Maybe()`) onto every stub a guard may skip, which hides the assertions that matter. The explicit style reads the same across the organisation's repos; a stricter local variant is not worth the divergence.
