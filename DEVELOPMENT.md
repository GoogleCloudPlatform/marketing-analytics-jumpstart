# propensity-modeling
Marketing Intelligence Solution with Propensity Modeling

## Preparing development environment

### Installing Python dependencies
```bash
gcloud init
python3.7 -m venv ~/.venvs/myenv
source ~/.venvs/myenv/bin/activate
gcloud config configurations activate propensity-modelling
pip3 install -r requirements-dev.txt
pip3 install pipenv
```

### Installing Terraform
```bash
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform
```

### Manually testing template rendering from yaml file
```bash
inv apply-env-variables-procedures --env-name=prod
```

### Testing using pyTest
Tests are configuration is part of *pyproject.toml*
Automatically running tests will aslo execute code coverage.
*variables* will be imported from config/dev.yaml to the test suite and used in testing

To execute tests on terminal
```bash
poetry run pytest -c pyproject.toml

```
flags:
    -n <NUMBER_OF_THREATS> # Number of Tests to run in Parallel
    -m "<MARKER_NAME> # Execute only tests marked with the given marker (@pytest.mark.unit)
    --maxfail=<NUMBER_OF_FAILURES> # Number of failed tests before aboarding
    --cov # test incudes code coverage
