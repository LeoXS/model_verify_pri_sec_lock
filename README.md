# Model Verification of Locking System for Primary/Secondary Failover

## Requirements

- One primary instance and secondary instance. The primary has privilege over secondary.
- Failover is risky and costly, so only trigger it when have to, i.e. DO NOT trigger when the primary temporarily loses lock or/and critical resources, but still active.
- Trigger failover when
    1. The primary crashed,
    2. By some measure the secondary detect the primary death, or
    3. The primary proactively gives up the leadership.

## Proposals

### P1: Distributed Lock + P/S(Primary/Secondary) Connection
