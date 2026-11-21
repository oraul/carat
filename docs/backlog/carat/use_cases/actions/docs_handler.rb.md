# Backlog: carat/use_cases/actions/docs_handler.rb

### DocsHandler names its variant action
- Location: carat/use_cases/actions/docs_handler.rb:20
- Why: the handler's variant is named @action/action: where the sibling handlers (BufferHandler) name it @variant/variant:, and 'action' already means the dotted action name (quality advisory, markdown-reading-a)
- Fix: rename it to variant
- Category: editor
- Added: 2026-11-16
