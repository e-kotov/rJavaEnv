# Global Use Cache Parameter

Documentation for the `.use_cache` parameter, used for performance
optimization.

## Usage

``` r
global_use_cache_param(.use_cache)
```

## Arguments

- .use_cache:

  A `logical` value controlling caching behavior. If `FALSE` (default),
  performs a fresh check each time (safe, reflects current state). If
  `TRUE`, uses session-scoped cached results for performance in loops or
  repeated calls.

  **Caching Behavior:**

  - Session-scoped: Cache is cleared when R restarts

  - Key-based for version checks: Changes to JAVA_HOME create new cache
    entries

  - System-wide for scanning: Always recalculates current default Java

  **Performance Benefits:**

  - First call: ~37-209ms (depending on operation)

  - Cached calls: \<1ms

  - Prevents 30-100ms delays on every call in performance-critical code

  **When to Enable:**

  - Package initialization code (`.onLoad` or similar)

  - Loops calling the same function multiple times

  - Performance-critical paths with frequent version checks

  **When to Keep Default (FALSE):**

  - Interactive use (one-off checks)

  - When you need current data reflecting recent Java installations

  - General-purpose function calls that aren't time-critical
