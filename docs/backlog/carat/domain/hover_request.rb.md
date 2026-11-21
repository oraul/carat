# Backlog: carat/domain/hover_request.rb

## The request records copy waiting? and the language predicate

- Where: `carat/domain/hover_request.rb` line 79, `completion_request.rb` line 94, `completion_docs.rb` line 81, and `signature_request.rb` line 204 under `carat/domain/`, at b76b722. Periodic quality. Queue item `lsp-client-tidy`.
- Why it matters: four records repeat the same serial members, `waiting?`, and the languages predicate, and drift apart.
- Fix outline: fold them into the one request record the entry on the gateway's two timeout paths plans, or a domain concern.
- Category: ide
- Added: 2026-11-09

### Language-service asks have no port (architecture-review H1)

Location: `carat/domain/hover_request.rb`, `definition_request.rb`, `signature_request.rb`, `symbol_request.rb`, `completion_request.rb`; `carat/adapters/editor_assembly.rb` (the `hover`, `definition`, `symbols`, `signature` readers); `docs/architecture.md` section 5.3. Why: completion goes through `CompletionPort` while hover, definition, signature help, and document symbols go through mutable domain records the use cases and `JsonRpcLanguageGateway` both write, two mechanisms for one job; the records hold protocol bookkeeping (request in flight, deadline, serial), so the domain carries adapter state and a second backend or double must mimic the mutations. Fix outline: one `LanguageAskPort` (ask by kind and anchor, answer by kind, `waiting?`) or the `CompletionPort` shape per ask; domain records keep the anchor and answer, the gateway the ids and deadlines; one double for every ask.
- Also: carat/adapters/editor_assembly.rb, docs/architecture.md
- Category: ide
- Added: 2026-11-15

### HoverRequest and DefinitionRequest repeat their members (sprint-16 sweep quality)

- Location: carat/domain/hover_request.rb:3, carat/domain/definition_request.rb:3.
- Why: the anchor, want, sent, sent_id, language, deadline, languages members and at?, waiting?, offers? predicates are copied.
- Fix outline: a domain concern for the cursor-anchored ask, or one record both hold. Pool item `lsp-tidy`.
- Also: carat/domain/definition_request.rb
- Category: ide
- Added: 2026-11-18
