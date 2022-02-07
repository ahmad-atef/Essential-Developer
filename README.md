# Essential App Case Study

## Feature: Image Feed Features Specs


### Story: Customer requests to see their image feed


### Narrative: #1

```
As online customer
I want the app to automatically load my latest images of my friends
So I can always enjoy the newst image of my friends.
```

#### Scenarios (Acceptance criteria)

```
Given the customer has connectiviy
 When the customer requests to see their feed
 Then the app should display the latests feed from remote
  And replace the cache with the new feed.
```

### Narrative: #2

```
As an offline customer
I want the app to show the latest saved version of my image feed
So I can always enjoy images of my friends.
```

#### Scenarios (Acceptance criteria)

```
Given the customer doesn't have connectivity
  And there's a cached version of the feed
  And the cache is less than 7 days old
 When the customer requests to see the feed
 Then the app should display the latested feed from cache.

Given the customer doesn't have connectiviry
  And there's a cached version of the feed
  And the cache is 7 days old or more
 When the customer requests to see the feed
 Then the app should display an error message.

Given the customer doesn't have connectivity
  And the cache is empty
 When the customer requests to see thier feed
 Then the app should display an error message.

```

## Use Cases

### Load Feed From Cache Use Case (Service layer)

#### Primary course:
1. Execute "Load Image Feed" command with above data.
2. System retrieves feed data from cache.
3. System validates cache is less than seven days old.
4. System creates image feed from cached data.
5. System delivers image feed.

#### Retrieval error course (sad path):
1. System delivers error.

#### Expired cache course (sad path): 
1. System delivers no feed images.

#### Empty cache course (sad path): 
1. System delivers no feed images.



### Cache validation Use Case

#### Primary course:
1. Execute `validation` command.
2. System retrieves data from cache.
3. System validate retrieved cache should be non-expired (less than 7 days old).

#### Reterival Error:
1. System should delete cache on retrieval error.

#### Expired Cache feed path:
1. System should delete cache when finding expired cache image feed (7 or more days old)

---
