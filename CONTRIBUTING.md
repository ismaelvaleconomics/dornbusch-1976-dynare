# Contributing

Thank you for your interest in improving this repository.

## Basic principles

- Preserve the economic interpretation of the original Dornbusch framework.
- Document all non-trivial calibration changes.
- Keep code comments clear and academically useful.
- Separate theoretical model changes from purely computational changes.

## Suggested contribution workflow

1. Fork the repository.
2. Create a feature branch.
3. Make focused commits with informative messages.
4. Test the modified `.mod` file in Dynare.
5. Open a pull request describing:
   - what changed,
   - why it changed,
   - whether the change is theoretical, computational, or empirical.

## Style suggestions

- Use descriptive variable names when adding scripts.
- Keep calibration blocks easy to inspect.
- Add references when extending the original model.
- Prefer reproducible scripts over manual steps.
