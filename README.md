# essentialdeveloper

# Assert for Specific Error:

---

- `Loader:` is the responsibility that should ***`load`*** the data from a **`URL`**
- `Client:` is the responsibility that should ***`request`*** the data from a **`URL`**
- `Loader` has a `Client` + `URL` as a destination point.
- Client should have dependency thorough a function, so when you call the request method on client, you should pass the URL, which is configured from the loader.
- Client can fail, so it should return completion handler with Result <Item, Error>
- The error type that can return from Client should be Generic.
- Loader also should have a completion handler with Specific Domain Error type.