## MODIFIED Requirements

### Requirement: Dependabot moves third-party actions and never the OPM pins

`.github/dependabot.yml` MUST keep the `github-actions` ecosystem up to date, MUST wait seven days after an action release before proposing it (`cooldown: {default-days: 7}`), and MUST ignore `open-platform-model/docs-kit*` and `open-platform-model/.github*`, whose references move only through their own pin PRs.

#### Scenario: A third-party action release opens a bump

- **WHEN** `actions/checkout` publishes a new release and seven days have passed
- **THEN** Dependabot opens a `ci`-prefixed PR moving its SHA pin

#### Scenario: A cascade pin is not bumped by Dependabot

- **WHEN** `.github` `main` moves past the SHA core pins for `cascade-notify`
- **THEN** Dependabot opens no PR for it; the pin moves only through a `ci(deps)` pin PR

#### Scenario: A fresh action release waits out the cooldown

- **WHEN** a third-party action publishes a release today
- **THEN** Dependabot proposes no bump to it for seven days
