# Lint the Helm charts using chart-testing (ct)
lint *args="--all":
    ct lint --config .ct.yaml {{args}}
