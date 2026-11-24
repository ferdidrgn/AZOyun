# Football catalogue reliability change

- Wikidata remains the only source; no scraping, API key or paid provider was added.
- SPARQL result order is stable and explicitly bounded. A result beyond the row cap is rejected instead of silently publishing a truncated catalogue.
- Candidate catalogues are validated for unique Wikidata player IDs, valid names and memberships, usable career dates, and enough dated multi-club players for Career Path.
- Box2Box and Connections are both precomputed and validated before the release is written. Connections now uses a deterministic, bounded backtracking search for 16 unique answers rather than a greedy assignment that can fail on a valid candidate set.
- The publisher stages JSON, writes the validated release to RTDB, then atomically replaces the static Hosting artifact. Hosting deployment is gated on the catalogue publication step succeeding, avoiding web deployment of a rejected/partial candidate.
- Player `positionIds` are retained alongside position labels so clients can normalize Turkish/English display labels against stable Wikidata IDs.

No live Wikidata refresh or Firebase publication was run for this change. The current source snapshot's coverage against the stricter career threshold remains to be observed in a scheduled/manual CI run.
