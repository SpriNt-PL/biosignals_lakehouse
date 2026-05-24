### Instalation

- Connect using ssh tunnel to Virtual Machine
- Create venv (optional but I suggest to do it): py -m venv .venv
- Make sure your terminal is in venv
- Install all libraries: pip install --no-cache-dir -r requirements.txt
- Configure profiles.yml file according to the instruction in profiles_template.yml.
- Run dbt: dbt run (make sure you are in biosignals_lakehouse directory)




